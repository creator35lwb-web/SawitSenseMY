"""Generate SawitSense's app icons and logo sizes from the master logo.

The master logo (docs/brand/sawitsense-logo-master.png: 2048 px, 2.7 MB) used
to be shipped as-is as the favicon, the PWA icon, the share image and the
40 px logo in the app bar, so every visitor downloaded 2.7 MB to see a tiny
white square. This script derives right-sized files from it:

- the emblem alone (fruit, fronds and rising arrow, without the wordmark) for
  small sizes, where the wordmark would be unreadable
- the full logo (with the wordmark) for large uses: link previews and README

Usage (Pillow is a dev tool here, not a runtime dependency):
    pip install pillow
    python frontend/tool/make_icons.py

Author: SS (Claude Code), Sep 2026
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "docs" / "brand" / "sawitsense-logo-master.png"

# Regions of the 2048 px master, measured by eye on a gridded zoom.
EMBLEM_BOX = (470, 405, 1720, 1300)  # fruit, fronds, arrow (the wordmark starts at y=1342)
MY_BOX = (1395, 1262, 1720, 1300)    # the small "MY" beside the lowest leaflets
FULL_BOX = (487, 423, 1703, 1477)    # all artwork, wordmark included
WHITE = (255, 255, 255)


def square(img: Image.Image, margin: float) -> Image.Image:
    """Centre img on a white square, leaving `margin` (a fraction of the side) around it."""
    side = round(max(img.size) / (1 - 2 * margin))
    canvas = Image.new("RGB", (side, side), WHITE)
    canvas.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
    return canvas


def save(img: Image.Image, size: int, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path, optimize=True)
    print(f"{path.relative_to(ROOT).as_posix()}: {size}x{size}, {path.stat().st_size // 1024} KB")


def main() -> None:
    master = Image.open(MASTER).convert("RGB")
    emblem = master.copy()
    emblem.paste(WHITE, MY_BOX)
    emblem = emblem.crop(EMBLEM_BOX)
    full = master.crop(FULL_BOX)

    web = ROOT / "frontend" / "web"
    save(square(emblem, 0.04), 192, ROOT / "frontend" / "assets" / "logo_mark.png")
    save(square(emblem, 0.04), 48, web / "favicon.png")
    save(square(emblem, 0.06), 192, web / "icons" / "Icon-192.png")
    save(square(emblem, 0.06), 512, web / "icons" / "Icon-512.png")
    # Android may crop a maskable icon to a circle: keep the art inside the
    # central 80% "safe zone".
    save(square(emblem, 0.18), 512, web / "icons" / "Icon-maskable-512.png")
    save(square(emblem, 0.10), 180, web / "icons" / "apple-touch-icon.png")
    save(square(full, 0.08), 600, web / "og-image.png")
    save(square(full, 0.08), 512, ROOT / "docs" / "logo.png")


if __name__ == "__main__":
    main()
