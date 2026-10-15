"""Create the app's WebP deck without modifying the original PNG artwork.

Requires Pillow: python -m pip install Pillow
Run from any directory: python tool/compress_tarot.py
"""

from pathlib import Path

from PIL import Image, ImageOps


def main():
    root = Path(__file__).resolve().parent.parent
    source = root / "lib/assets/Tarot Deck"
    target = root / "lib/assets/tarot_webp"
    originals = sorted(source.glob("*.png"))
    if len(originals) != 78:
        raise ValueError(f"Expected 78 source cards, found {len(originals)}")
    target.mkdir(parents=True, exist_ok=True)
    original_bytes = 0
    webp_bytes = 0
    for path in originals:
        destination = target / f"{path.stem}.webp"
        with Image.open(path) as image:
            image = ImageOps.exif_transpose(image)
            image.thumbnail((768, 1152), Image.Resampling.LANCZOS)
            mode = "RGBA" if "A" in image.getbands() else "RGB"
            image.convert(mode).save(
                destination, "WEBP", quality=86, method=6
            )
        with Image.open(destination) as result:
            result.load()
            if result.format != "WEBP" or max(result.size) > 1152:
                raise ValueError(f"Invalid compressed card: {destination.name}")
        original_bytes += path.stat().st_size
        webp_bytes += destination.stat().st_size
    print(f"Cards: {len(originals)}")
    print(f"Original PNG: {original_bytes / 1024**2:.2f} MiB")
    print(f"Bundled WebP: {webp_bytes / 1024**2:.2f} MiB")
    print(f"Reduction: {(1 - webp_bytes / original_bytes) * 100:.1f}%")


if __name__ == "__main__":
    main()
