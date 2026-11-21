"""Compare Create ML sound classifiers on the same labelled test clips, scored the way the app plays.

For each chord clip: take ~1 s windows starting at the strum (hop 0.5 s, first 2 s),
average the probabilities, and take the top label (one strum = one decision).
For noise clips: count windows the app would score as a chord (confidence > 60%).

Usage: python compare_models.py dataset/Test model1.mlmodel [model2.mlmodel ...]
"""
import sys
from collections import defaultdict
from pathlib import Path

import coremltools as ct
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

SR = 16000
WIN = 15600  # Create ML sound classifier input (0.975 s)
HOP = SR // 2
MIN_CONF = 0.60  # chordModel.minConfidence
OLD_CHORDS = {"Am", "C", "Dm", "Em", "G"}  # labels the current app model knows


def load(path):
    audio, sr = sf.read(path, dtype="float32", always_2d=True)
    audio = audio.mean(axis=1)
    if sr != SR:
        audio = resample_poly(audio, SR, sr).astype(np.float32)
    return audio


def windows(audio, start, count):
    out = []
    for i in range(count):
        w = audio[start + i * HOP: start + i * HOP + WIN]
        if len(w) < WIN:
            break
        out.append(w)
    return out


def predict(model, w):
    out = model.predict({"audioSamples": w})
    return out["targetProbability"]


def main():
    test_dir = Path(sys.argv[1])
    for model_path in sys.argv[2:]:
        model = ct.models.MLModel(model_path)
        labels = set(model.get_spec().description.metadata.userDefined.get("labels", "").split(",")) - {""}
        per_chord = defaultdict(lambda: [0, 0])
        noise_windows = noise_fp = 0
        for label_dir in sorted(p for p in test_dir.iterdir() if p.is_dir()):
            label = label_dir.name
            for f in sorted(label_dir.iterdir()):
                audio = load(f)
                if label == "Ambient Noise":
                    for w in windows(audio, 0, len(audio) // HOP):
                        probs = predict(model, w)
                        top = max(probs, key=probs.get)
                        noise_windows += 1
                        noise_fp += top != "Ambient Noise" and probs[top] > MIN_CONF
                    continue
                onset = int(np.argmax(np.abs(audio) > 0.1 * np.abs(audio).max()))
                ws = windows(audio, max(0, onset - SR // 20), 3)
                summed = defaultdict(float)
                for w in ws:
                    for k, v in predict(model, w).items():
                        summed[k] += v
                top = max(summed, key=summed.get)
                per_chord[label][0] += top == label
                per_chord[label][1] += 1

        def score(chords):
            hit = sum(per_chord[c][0] for c in chords)
            tot = sum(per_chord[c][1] for c in chords)
            return f"{hit}/{tot} ({hit / tot:.0%})"

        print(f"\n== {Path(model_path).name} ({Path(model_path).stat().st_size / 1e6:.2f} MB)")
        print("  per chord: " + ", ".join(f"{c} {h}/{t}" for c, (h, t) in sorted(per_chord.items())))
        print(f"  Am/C/Dm/Em/G: {score(OLD_CHORDS)}   all 8 chords: {score(per_chord.keys())}")
        print(f"  noise windows scored as a chord (>60%): {noise_fp}/{noise_windows}")


if __name__ == "__main__":
    main()
