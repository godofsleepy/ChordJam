"""Convert alejogil35/distilhubert-finetuned-chorddetection (Apache-2.0) to Core ML.

Output: ChordClassifierV2.mlpackage, a Core ML classifier that takes
`audio` = Float32 [1, 32000] (2 s of 16 kHz mono) and returns `classLabel`
plus `classLabel_probs`, with labels renamed to the app's ChordType names.

Usage:
  python convert_distilhubert.py [--out ChordClassifierV2.mlpackage] [--palettize]
"""
import argparse

import coremltools as ct
import numpy as np
import torch
from transformers import HubertForSequenceClassification

REPO = "alejogil35/distilhubert-finetuned-chorddetection"
REVISION = "f8196ded447d9d281532bc81f390a6b14101dfa2"
SAMPLE_RATE = 16000
NUM_SAMPLES = 32000  # 2 s window

# Spanish solfege label -> name used by the app (ChordType raw values)
ROOTS = {
    "Do": "C", "ReBemol": "Db", "Re": "D", "MiBemol": "Eb", "Mi": "E", "Fa": "F",
    "SolBemol": "Gb", "Sol": "G", "LaBemol": "Ab", "La": "A", "SiBemol": "Bb", "Si": "B",
}
QUALITIES = {"Mayor": "", "Menor": "m", "Aumentada": "aug", "Disminuida": "dim"}


def app_label(spanish: str) -> str:
    for q_es, q in QUALITIES.items():
        if spanish.endswith(q_es):
            return ROOTS[spanish[: -len(q_es)]] + q
    raise ValueError(f"unknown label {spanish}")


class Wrapped(torch.nn.Module):
    """Normalizes the waveform like Wav2Vec2FeatureExtractor, then returns softmax probs."""

    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, audio):
        mean = audio.mean(dim=-1, keepdim=True)
        var = audio.var(dim=-1, keepdim=True, unbiased=False)
        x = (audio - mean) / torch.sqrt(var + 1e-7)
        logits = self.model(input_values=x).logits
        return torch.softmax(logits, dim=-1)


def load_torch():
    model = HubertForSequenceClassification.from_pretrained(REPO, revision=REVISION)
    model.eval()
    labels = [app_label(model.config.id2label[i]) for i in range(model.config.num_labels)]
    return Wrapped(model).eval(), labels


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="ChordClassifierV2.mlpackage")
    ap.add_argument("--palettize", action="store_true", help="8-bit weight palettization (~4x smaller)")
    args = ap.parse_args()

    wrapped, labels = load_torch()
    example = torch.randn(1, NUM_SAMPLES) * 0.1
    with torch.no_grad():
        traced = torch.jit.trace(wrapped, example)

    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="audio", shape=(1, NUM_SAMPLES), dtype=np.float32)],
        classifier_config=ct.ClassifierConfig(labels),
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS17,
        compute_precision=ct.precision.FLOAT16,
    )

    if args.palettize:
        from coremltools.optimize.coreml import OpPalettizerConfig, OptimizationConfig, palettize_weights
        cfg = OptimizationConfig(global_config=OpPalettizerConfig(mode="kmeans", nbits=8))
        mlmodel = palettize_weights(mlmodel, cfg)

    mlmodel.short_description = "Guitar chord classifier (DistilHuBERT, 48 classes). Input: 2 s of 16 kHz mono audio."
    mlmodel.author = f"Converted from {REPO}@{REVISION[:7]} (Apache-2.0)"
    mlmodel.license = "Apache-2.0"
    mlmodel.input_description["audio"] = "2 s of 16 kHz mono Float32 PCM, shape [1, 32000]"
    mlmodel.save(args.out)
    print(f"saved {args.out} with {len(labels)} labels")


if __name__ == "__main__":
    main()
