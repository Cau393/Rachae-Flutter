#!/usr/bin/env python3
"""Regenerate iOS AppIcon and web PWA/favicon PNGs from assets/branding/logo.png."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "branding" / "logo.png"
IOS_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
WEB_ICONS = ROOT / "web" / "icons"


def square_icon(
    src: Path,
    size: int,
    out: Path,
    *,
    margin_ratio: float = 0.10,
) -> None:
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    inset = max(1, int(size * margin_ratio))
    box = size - 2 * inset
    scale = min(box / w, box / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    ox = (size - nw) // 2
    oy = (size - nh) // 2
    canvas.paste(img, (ox, oy), img)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, "PNG")


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"Missing source logo: {SRC}")

    ios_map = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, px in ios_map.items():
        square_icon(SRC, px, IOS_DIR / name, margin_ratio=0.08)

    square_icon(SRC, 192, WEB_ICONS / "Icon-192.png", margin_ratio=0.10)
    square_icon(SRC, 512, WEB_ICONS / "Icon-512.png", margin_ratio=0.10)
    square_icon(SRC, 192, WEB_ICONS / "Icon-maskable-192.png", margin_ratio=0.18)
    square_icon(SRC, 512, WEB_ICONS / "Icon-maskable-512.png", margin_ratio=0.18)
    square_icon(SRC, 48, ROOT / "web" / "favicon.png", margin_ratio=0.10)


if __name__ == "__main__":
    main()
