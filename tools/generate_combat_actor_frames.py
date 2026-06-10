#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot_project"
DATA = PROJECT / "data"
MAPPING = DATA / "combat_actor_frames.json"

SPECS = [
    {
        "key": "player_male_none",
        "source": PROJECT / "assets" / "characters" / "player" / "player_male_none_stage_v2.png",
        "out": PROJECT / "assets" / "characters" / "player" / "actions" / "male_none",
    },
    {
        "key": "npc_流氓",
        "source": PROJECT / "assets" / "characters" / "npc" / "map_sprites_v2" / "thug_stage_v2.png",
        "out": PROJECT / "assets" / "characters" / "npc" / "actions" / "thug",
    },
    {
        "key": "npc_流氓头",
        "source": PROJECT / "assets" / "characters" / "npc" / "map_sprites_v2" / "thug_leader_stage_v2.png",
        "out": PROJECT / "assets" / "characters" / "npc" / "actions" / "thug_leader",
    },
]


def res_path(path: Path) -> str:
    return "res://" + str(path.relative_to(PROJECT))


def trim_alpha(image: Image.Image, padding: int = 28) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(image.width, x1 + padding)
    y1 = min(image.height, y1 + padding)
    return image.crop((x0, y0, x1, y1))


def fit_canvas(image: Image.Image, size: tuple[int, int], anchor_y: float = 0.90, offset: tuple[int, int] = (0, 0)) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    x = round((size[0] - image.width) * 0.5 + offset[0])
    y = round(size[1] * anchor_y - image.height + offset[1])
    canvas.alpha_composite(image, (x, y))
    return canvas


def resize(image: Image.Image, sx: float, sy: float) -> Image.Image:
    w = max(1, round(image.width * sx))
    h = max(1, round(image.height * sy))
    return image.resize((w, h), Image.Resampling.LANCZOS)


def shear(image: Image.Image, amount: float) -> Image.Image:
    xshift = abs(amount) * image.height
    width = image.width + round(xshift)
    matrix = (1, amount, -xshift if amount > 0 else 0, 0, 1, 0)
    return image.transform((width, image.height), Image.Transform.AFFINE, matrix, Image.Resampling.BICUBIC)


def tint(image: Image.Image, color: tuple[int, int, int], strength: float) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (*color, 0))
    overlay.putalpha(image.getchannel("A").point(lambda a: round(a * strength)))
    return Image.alpha_composite(image, overlay)


def make_shadowed(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(3)))
    shadow = ImageChops.offset(shadow, 4, 6)
    shadow.putalpha(shadow.getchannel("A").point(lambda a: round(a * 0.32)))
    return Image.alpha_composite(shadow, image)


def action_frame(base: Image.Image, size: tuple[int, int], action: str, index: int) -> Image.Image:
    subject = trim_alpha(base)
    if action == "idle":
        variants = [(1.0, 1.0, 0.0, (0, 0)), (1.012, 0.988, -0.012, (0, 2))]
        sx, sy, sh, off = variants[index]
        frame = shear(resize(subject, sx, sy), sh)
        return make_shadowed(fit_canvas(frame, size, 0.90, off))
    if action == "attack":
        variants = [
            (0.96, 1.035, -0.11, (-34, 4), None),
            (1.18, 0.90, 0.24, (46, 18), (255, 230, 150)),
            (1.05, 0.96, 0.15, (18, 10), (255, 175, 88)),
        ]
        sx, sy, sh, off, glow = variants[index]
        frame = shear(resize(subject, sx, sy), sh)
        if glow is not None:
            frame = tint(frame, glow, 0.16)
            frame = ImageEnhance.Contrast(frame).enhance(1.08)
        return make_shadowed(fit_canvas(frame, size, 0.90, off))
    if action == "hurt":
        variants = [(1.12, 0.88, -0.22, (-24, 28)), (1.04, 0.94, -0.15, (-8, 18))]
        sx, sy, sh, off = variants[index]
        frame = tint(shear(resize(subject, sx, sy), sh), (255, 92, 62), 0.22)
        return make_shadowed(fit_canvas(frame, size, 0.91, off))
    if action == "down":
        flat = resize(subject.rotate(-78, expand=True, resample=Image.Resampling.BICUBIC), 1.18, 0.68)
        flat = ImageEnhance.Brightness(flat).enhance(0.72)
        return make_shadowed(fit_canvas(flat, size, 0.94, (0, 42)))
    return make_shadowed(fit_canvas(subject, size))


def generate_for_spec(spec: dict[str, object]) -> dict[str, list[str]]:
    source = Path(spec["source"])
    out_dir = Path(spec["out"])
    if not source.exists():
        raise FileNotFoundError(source)
    out_dir.mkdir(parents=True, exist_ok=True)
    base = Image.open(source).convert("RGBA")
    trimmed = trim_alpha(base)
    size = (
        max(360, round(trimmed.width * 1.55)),
        max(520, round(trimmed.height * 1.24)),
    )
    counts = {"idle": 2, "attack": 3, "hurt": 2, "down": 1}
    result: dict[str, list[str]] = {}
    for action, count in counts.items():
        paths: list[str] = []
        for index in range(count):
            frame = action_frame(base, size, action, index)
            path = out_dir / f"{action}_{index}.png"
            frame.save(path)
            paths.append(res_path(path))
        result[action] = paths
    return result


def main() -> None:
    mapping: dict[str, dict[str, list[str]]] = {}
    for spec in SPECS:
        mapping[str(spec["key"])] = generate_for_spec(spec)
    MAPPING.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated combat actor frames: actors={len(mapping)}")


if __name__ == "__main__":
    main()
