"""Make an augmented copy of a folder-per-label training set.

Each chord clip gets N variants: random gain, random start offset, and training
noise mixed in at 8-25 dB SNR. Pitch is never changed, because that would change the chord.
Noise recordings are sliced into 2 s clips at several levels, plus synthetic quiet room tone.

Usage: python augment.py dataset/Train dataset/TrainAug [variants_per_clip]
"""
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

SR = 16000


def load(path):
    audio, sr = sf.read(path, dtype="float32", always_2d=True)
    audio = audio.mean(axis=1)
    return resample_poly(audio, SR, sr).astype(np.float32) if sr != SR else audio


def main():
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 4
    rng = np.random.default_rng(0)
    noise = np.concatenate([load(f) for f in (src / "Ambient Noise").iterdir()])

    for label_dir in sorted(p for p in src.iterdir() if p.is_dir()):
        out = dst / label_dir.name
        out.mkdir(parents=True, exist_ok=True)
        for f in sorted(label_dir.iterdir()):
            if label_dir.name == "Ambient Noise":
                # Slice long noise recordings into 2 s clips at several levels so the
                # noise class keeps up with the augmented chord classes.
                audio = load(f)
                for k, s in enumerate(range(0, len(audio) - 2 * SR, SR)):
                    for g, gain in enumerate((1.0, 0.3, 0.05)):
                        sf.write(out / f"{f.stem}_{k}_{g}.wav", audio[s:s + 2 * SR] * gain, SR)
                continue
            clean = load(f)
            sf.write(out / f"{f.stem}_orig.wav", clean, SR)
            for i in range(n):
                x = clean[int(rng.uniform(0, 0.3) * SR):] * rng.uniform(0.3, 1.0)
                start = rng.integers(0, len(noise) - len(x))
                nz = noise[start:start + len(x)]
                snr_db = rng.uniform(8, 25)
                gain = np.sqrt(np.mean(x ** 2) / (np.mean(nz ** 2) + 1e-9) / 10 ** (snr_db / 10))
                y = x + gain * nz
                y = y / max(1.0, np.abs(y).max())
                sf.write(out / f"{f.stem}_aug{i}.wav", y.astype(np.float32), SR)
        if label_dir.name == "Ambient Noise":
            # Quiet room tone: what the mic hears between strums in a calm room
            for k in range(150):
                tone = rng.normal(0, rng.uniform(1e-4, 5e-3), 2 * SR)
                hum = rng.uniform(0, 3e-3) * np.sin(2 * np.pi * rng.choice([50, 60]) * np.arange(2 * SR) / SR)
                sf.write(out / f"roomtone_{k}.wav", (tone + hum).astype(np.float32), SR)
        print(label_dir.name, len(list(out.iterdir())))


if __name__ == "__main__":
    main()
