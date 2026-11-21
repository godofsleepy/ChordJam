# Chord model upgrade: proof of concept

Tools for replacing `ChordJam/ML Model/ChordDetection.mlmodel`. This folder is not part of the Xcode target.

## Result

**Recommended: retrain the Create ML classifier (VGGish) on public guitar recordings with augmentation** (`ChordDetectionV2-vggish.mlmodel`). It has the same input and outputs as the current model (`audioSamples` [15600] → `target`, `targetProbability`), so it is a drop-in file swap: `chordModel.swift` needs no changes.

Scores on the dataset's held-out test split (6 real strums per chord, one decision per strum; see `compare_models.py`):

| Model | Size | Am/C/Dm/Em/G | All 8 game chords | Noise windows scored as a chord |
|---|---|---|---|---|
| Current `ChordDetection.mlmodel` | 5.0 MB | 15/30 (50%) | 15/48 (31%) | 64/301 (21%) |
| **V2 VGGish, augmented** | 5.3 MB | **23/30 (77%)** | **30/48 (62%)** | 142/301 (47%) |
| V2 Audio Feature Print, augmented | 0.03 MB | 18/30 (60%) | 24/48 (50%) | 52/301 (17%) |
| DistilHuBERT (Hugging Face, converted) | 45 MB | — | 1/48 (2%) | — |

- The current model knows `Am, Ambient Noise, C, Dm, Em, G`. V2 adds `A, D, E`, so it covers every `ChordType`.
- V2's weak spot is loud crowd/stadium noise. Quiet-room behaviour is untested on a device. In the app, a loudness gate or "same chord in two windows in a row" check would cut most of these false hits.
- D and E are still weak (1–2 of 6). More recordings of those two would help most.
- The test set uses the same guitar as the training set (Fender FA series), so real-world accuracy with other guitars and phone mics will be lower. Check on a device.

### Why not a pretrained model from the internet
- `alejogil35/distilhubert-finetuned-chorddetection` (Apache-2.0) converted to Core ML cleanly; Core ML matched PyTorch on 48/48 clips. But it scored **1/48 on real guitar strums**, which is chance level. Its card's 100% accuracy comes from a broken evaluation. `convert_distilhubert.py` and `evaluate.py` are kept as a record and a template.
- `rodriler/betterchord-chord-cnn` has the best reported accuracy, but its license is **CC BY-NC** (non-commercial) and it needs a CQT front end written in Swift. Not usable for a shipped app.
- No other public guitar-chord model had usable weights plus labels.

## Reproduce

```sh
cd Tools/model-conversion
uv venv -p 3.11 .venv && uv pip install -p .venv/bin/python -r requirements.txt
.venv/bin/python fetch_dataset.py                           # ~190 MB into dataset/
.venv/bin/python augment.py dataset/Train dataset/TrainAug 4
swift train_createml.swift dataset/TrainAug dataset/Test ChordDetectionV2-vggish.mlmodel vggish
swift train_createml.swift dataset/TrainAug dataset/Test ChordDetectionV2-afp.mlmodel afp
.venv/bin/python compare_models.py dataset/Test "../../ChordJam/ML Model/ChordDetection.mlmodel" ChordDetectionV2-vggish.mlmodel ChordDetectionV2-afp.mlmodel
```

Training takes about 1 minute on Apple silicon. Outputs (`*.mlmodel`, `dataset/`, `.venv/`, `hf-cache/`) are gitignored.

## Files
- `fetch_dataset.py`: downloads the 8 game chords and the noise class from [severyn-k/isolated-guitar-chords](https://huggingface.co/datasets/severyn-k/isolated-guitar-chords) (CC-BY-4.0, pinned revision).
- `augment.py`: chord clips × gain, offset and mixed room noise (never pitch-shifted). Noise is sliced into 2 s clips at three levels, plus synthetic quiet room tone.
- `train_createml.swift`: Create ML `MLSoundClassifier` training (`afp` or `vggish`), with accuracy and confusion printouts.
- `compare_models.py`: scores any Create ML sound classifiers the way the game uses them.
- `convert_distilhubert.py`, `evaluate.py`: Hugging Face → Core ML conversion and parity check (DistilHuBERT; not suitable, see above).

## Attribution
Training data: severyn-k, *isolated-guitar-chords*, CC-BY-4.0. If V2 ships, credit the dataset in the app's acknowledgements.
