#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Crop transparent padding from a PNG/WebP image.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--padding", type=int, default=12)
    parser.add_argument("--alpha-threshold", type=int, default=8)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    image = Image.open(args.input).convert("RGBA")
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > args.alpha_threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise SystemExit(f"No visible pixels found in {args.input}")

    left, top, right, bottom = bbox
    padding = max(0, int(args.padding))
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.width, right + padding)
    bottom = min(image.height, bottom + padding)

    cropped = image.crop((left, top, right, bottom))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(args.output)
    print(
        f"Wrote {args.output} "
        f"size={cropped.width}x{cropped.height} "
        f"crop=({left},{top},{right},{bottom})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
