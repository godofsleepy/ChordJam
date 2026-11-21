"""Evaluate the PyTorch model and the converted Core ML model on labelled WAV clips.

Clip file names must start with the chord name, e.g. `G_0.wav`, `Am_take2.wav`.
Usage: python evaluate.py <clip_dir> [--mlpackage ChordClassifierV2.mlpackage]
"""
import argparse
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from scipy.signal import resample_poly

from convert_distilhubert import NUM_SAMPLES, SAMPLE_RATE, load_torch

GAME_CHORDS = ["C", "Am", "G", "Dm", "Em", "D", "E", "A"]


def load_clip(path):
    audio, sr = sf.read(path, dtype="float32", always_2d=True)
    audio = audio.mean(axis=1)
    if sr != SAMPLE_RATE:
        audio = resample_poly(audio, SAMPLE_RATE, sr).astype(np.float32)
    # Start just before the strum (skip leading silence), like the app does once it hears sound
    onset = int(np.argmax(np.abs(audio) > 0.1 * np.abs(audio).max()))
    audio = audio[max(0, onset - SAMPLE_RATE // 20):][:NUM_SAMPLES]
    return np.pad(audio, (0, NUM_SAMPLES - len(audio)))[None, :]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("clips")
    ap.add_argument("--mlpackage")
    args = ap.parse_args()

    wrapped, labels = load_torch()
    mlmodel = None
    if args.mlpackage:
        import coremltools as ct
        mlmodel = ct.models.MLModel(args.mlpackage)

    files = sorted(Path(args.clips).glob("*.wav"))
    torch_hits = ml_hits = agree = 0
    max_diff = 0.0
    print(f"{'clip':<14}{'torch':>14}{'coreml':>14}")
    for f in files:
        expected = f.stem.split("_")[0]
        x = load_clip(f)
        with torch.no_grad():
            p = wrapped(torch.from_numpy(x))[0].numpy()
        t_label, t_conf = labels[int(p.argmax())], float(p.max())
        torch_hits += t_label == expected
        row = f"{f.name:<14}{t_label:>8} {t_conf:4.0%}"
        if mlmodel:
            out = mlmodel.predict({"audio": x})
            probs = out["classLabel_probs"]
            m_label = out["classLabel"]
            ml_hits += m_label == expected
            agree += m_label == t_label
            max_diff = max(max_diff, max(abs(probs[l] - p[i]) for i, l in enumerate(labels)))
            row += f"{m_label:>8} {probs[m_label]:4.0%}"
        print(row + ("" if t_label == expected else "   <- miss"))

    n = len(files)
    print(f"\ntorch top-1: {torch_hits}/{n}")
    if mlmodel:
        print(f"coreml top-1: {ml_hits}/{n}, agrees with torch on {agree}/{n}, max prob diff {max_diff:.3f}")


if __name__ == "__main__":
    main()
