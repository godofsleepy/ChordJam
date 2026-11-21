"""Download the game's chords from severyn-k/isolated-guitar-chords (CC-BY-4.0) into dataset/.

Layout: dataset/{Train,Test}/<label>/*.wav, where labels match ChordType raw values
plus "Ambient Noise" (the dataset's "Noise" class). Files are copied, not symlinked,
because Create ML does not follow symlinks.

Usage: python fetch_dataset.py
"""
import shutil
from pathlib import Path

from huggingface_hub import snapshot_download

REPO = "severyn-k/isolated-guitar-chords"
REVISION = "873968c2499d528e57e9909001d4329917f3d677"
CHORDS = ["A", "Am", "C", "D", "Dm", "E", "Em", "G", "Noise"]


def main():
    src = Path(snapshot_download(
        REPO, repo_type="dataset", revision=REVISION,
        allow_patterns=[f"data/{split}/{c}/*" for split in ("Train", "Test") for c in CHORDS],
    ))
    for split in ("Train", "Test"):
        for chord in CHORDS:
            dst = Path("dataset", split, "Ambient Noise" if chord == "Noise" else chord)
            dst.mkdir(parents=True, exist_ok=True)
            for f in (src / "data" / split / chord).iterdir():
                shutil.copy(f, dst / f.name.replace(" ", ""))
        counts = {d.name: len(list(d.iterdir())) for d in sorted(Path("dataset", split).iterdir())}
        print(split, counts)


if __name__ == "__main__":
    main()
