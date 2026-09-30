#!/usr/bin/env python3
"""Build App Store screenshot compositions from real XCTest captures."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


INK = (5, 13, 15)
INK_2 = (9, 23, 24)
RICE = (247, 245, 238)
MUTED = (166, 181, 179)
JADE = (91, 225, 182)
GOLD = (255, 184, 90)
VIOLET = (163, 133, 255)
CORAL = (255, 100, 113)
CYAN = (89, 205, 231)

FONT_PATH = "/System/Library/Fonts/Hiragino Sans GB.ttc"


@dataclass(frozen=True)
class Slide:
    number: str
    title: str
    subtitle: str
    tags: tuple[str, str]
    accent: tuple[int, int, int]
    source: Path


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size=size, index=1 if bold else 0)


def vertical_gradient(size: tuple[int, int], accent: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, INK)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        progress = y / max(height - 1, 1)
        glow = max(0.0, 1.0 - abs(progress - 0.30) * 2.2)
        strength = 0.085 * glow
        color = tuple(
            int(INK[channel] * (1 - strength) + accent[channel] * strength)
            for channel in range(3)
        )
        draw.line((0, y, width, y), fill=color)
    return image


def draw_brand_texture(image: Image.Image, accent: tuple[int, int, int], scale: float) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    width, height = image.size
    grid = int(82 * scale)
    start_y = int(height * 0.61)
    for x in range(-grid, width + grid, grid):
        draw.line((x, start_y, x, height), fill=(*accent, 19), width=max(1, int(scale)))
    for y in range(start_y, height + grid, grid):
        draw.line((0, y, width, y), fill=(*accent, 19), width=max(1, int(scale)))

    stone_radius = int(46 * scale)
    stones = [
        (int(width * 0.09), int(height * 0.76), RICE),
        (int(width * 0.91), int(height * 0.68), accent),
        (int(width * 0.84), int(height * 0.91), RICE),
    ]
    for x, y, color in stones:
        draw.ellipse(
            (x - stone_radius, y - stone_radius, x + stone_radius, y + stone_radius),
            fill=(*color, 24),
            outline=(*color, 48),
            width=max(2, int(2 * scale)),
        )

    draw.arc(
        (int(width * 0.62), int(height * 0.09), int(width * 1.13), int(height * 0.43)),
        start=145,
        end=315,
        fill=(*accent, 52),
        width=max(2, int(4 * scale)),
    )


def rounded_screenshot(source: Path, target_size: tuple[int, int], radius: int) -> Image.Image:
    screenshot = Image.open(source).convert("RGB")
    screenshot.thumbnail(target_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", screenshot.size, (0, 0, 0, 0))
    mask = Image.new("L", screenshot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, screenshot.width - 1, screenshot.height - 1),
        radius=radius,
        fill=255,
    )
    canvas.paste(screenshot, (0, 0), mask)
    return canvas


def paste_with_frame(
    image: Image.Image,
    screenshot: Image.Image,
    position: tuple[int, int],
    accent: tuple[int, int, int],
    scale: float,
) -> None:
    x, y = position
    pad = int(13 * scale)
    radius = int(58 * scale)
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (x - pad, y - pad, x + screenshot.width + pad, y + screenshot.height + pad),
        radius=radius,
        fill=(0, 0, 0, 220),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(26 * scale)))
    image.paste(shadow, (0, 0), shadow)

    frame = Image.new("RGBA", image.size, (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle(
        (x - pad, y - pad, x + screenshot.width + pad, y + screenshot.height + pad),
        radius=radius,
        fill=(12, 21, 23, 255),
        outline=(*accent, 150),
        width=max(3, int(4 * scale)),
    )
    image.paste(frame, (0, 0), frame)
    image.paste(screenshot, (x, y), screenshot)


def render_slide(
    slide: Slide,
    size: tuple[int, int],
    output_path: Path,
    device: str,
) -> None:
    width, height = size
    scale = width / 1320 if device == "iphone" else width / 2064
    image = vertical_gradient(size, slide.accent)
    draw_brand_texture(image, slide.accent, scale)
    draw = ImageDraw.Draw(image, "RGBA")

    margin = int((86 if device == "iphone" else 132) * scale)
    badge_y = int((92 if device == "iphone" else 82) * scale)
    badge_font = font(int((27 if device == "iphone" else 32) * scale), bold=True)
    title_font = font(int((90 if device == "iphone" else 108) * scale), bold=True)
    subtitle_font = font(int((37 if device == "iphone" else 43) * scale))
    tag_font = font(int((25 if device == "iphone" else 29) * scale), bold=True)

    badge_text = "技能五子棋  ·  2.2"
    badge_box = draw.textbbox((0, 0), badge_text, font=badge_font)
    badge_w = badge_box[2] - badge_box[0] + int(42 * scale)
    badge_h = badge_box[3] - badge_box[1] + int(26 * scale)
    draw.rounded_rectangle(
        (margin, badge_y, margin + badge_w, badge_y + badge_h),
        radius=badge_h // 2,
        fill=(*slide.accent, 34),
        outline=(*slide.accent, 105),
        width=max(2, int(2 * scale)),
    )
    draw.text(
        (margin + int(21 * scale), badge_y + int(7 * scale)),
        badge_text,
        font=badge_font,
        fill=(*slide.accent, 255),
    )

    number_font = font(int((28 if device == "iphone" else 34) * scale), bold=True)
    number = f"{slide.number} / 06"
    number_box = draw.textbbox((0, 0), number, font=number_font)
    draw.text(
        (width - margin - (number_box[2] - number_box[0]), badge_y + int(8 * scale)),
        number,
        font=number_font,
        fill=(*MUTED, 190),
    )

    title_y = int((190 if device == "iphone" else 175) * scale)
    draw.multiline_text(
        (margin, title_y),
        slide.title,
        font=title_font,
        fill=RICE,
        spacing=int(5 * scale),
    )
    title_lines = slide.title.count("\n") + 1
    subtitle_y = title_y + int((title_lines * 106 + 25) * scale)
    draw.text((margin, subtitle_y), slide.subtitle, font=subtitle_font, fill=(*MUTED, 255))

    tag_y = subtitle_y + int(76 * scale)
    tag_x = margin
    for tag in slide.tags:
        bounds = draw.textbbox((0, 0), tag, font=tag_font)
        tag_w = bounds[2] - bounds[0] + int(42 * scale)
        tag_h = int(50 * scale)
        draw.rounded_rectangle(
            (tag_x, tag_y, tag_x + tag_w, tag_y + tag_h),
            radius=tag_h // 2,
            fill=(*slide.accent, 30),
        )
        draw.text(
            (tag_x + int(21 * scale), tag_y + int(7 * scale)),
            tag,
            font=tag_font,
            fill=(*slide.accent, 235),
        )
        tag_x += tag_w + int(16 * scale)

    if device == "iphone":
        target_width = int(1020 * scale)
        top = int(675 * scale)
    else:
        target_width = int(1510 * scale)
        top = int(735 * scale)

    source_image = Image.open(slide.source)
    target_height = int(target_width * source_image.height / source_image.width)
    screenshot = rounded_screenshot(
        slide.source,
        (target_width, target_height),
        radius=int(48 * scale),
    )
    x = (width - screenshot.width) // 2
    paste_with_frame(image, screenshot, (x, top), slide.accent, scale)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output_path, format="PNG", optimize=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    for device in ("iphone", "ipad"):
        for name in ("effect", "advanced", "guide", "ai", "mode", "local"):
            parser.add_argument(f"--{device}-{name}", type=Path, required=True)
    return parser.parse_args()


def slides_for(args: argparse.Namespace, device: str) -> list[Slide]:
    source = lambda name: getattr(args, f"{device}_{name}")
    return [
        Slide("01", "九项技能\n改写棋局", "不只落子，更能扭转局势", ("技能动效", "清晰结算"), CORAL, source("effect")),
        Slide("02", "选择你的\n技能流派", "高阶模式 · 9 选 3，自由组合", ("人机可选", "双人可选"), VIOLET, source("advanced")),
        Slide("03", "每项技能\n一目了然", "效果、目标、冷却与次数，随时查看", ("图文说明", "对局内可查"), GOLD, source("guide")),
        Slide("04", "离线 AI\n认真应战", "三档难度 · 保留自然思考节奏", ("无需联网", "本地运算"), JADE, source("ai")),
        Slide("05", "人机或双人\n一键开局", "三种规则，选择后再开始", ("经典五子棋", "技能五子棋"), CYAN, source("mode")),
        Slide("06", "同屏对弈\n技能尽在手中", "双方技能栏常驻，状态清清楚楚", ("本机双人", "即时反馈"), GOLD, source("local")),
    ]


def main() -> None:
    args = parse_args()
    targets = {
        "iphone": (1320, 2868),
        "ipad": (2064, 2752),
    }
    folders = {
        "iphone": "iphone-6.9-promo",
        "ipad": "ipad-13-promo",
    }
    for device in ("iphone", "ipad"):
        for slide in slides_for(args, device):
            name = f"{slide.number}-{device}.png"
            render_slide(slide, targets[device], args.output / folders[device] / name, device)


if __name__ == "__main__":
    main()
