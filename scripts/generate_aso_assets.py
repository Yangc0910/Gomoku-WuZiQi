#!/usr/bin/env python3
"""Compose store creatives; use actual UI in search-results artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'AppStoreAssets/aso-2026-10'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = OUT / 'key-art-source.png'
INK, IVORY, JADE, MUTED = '#050D0F', '#F7F5EE', '#5BE1B6', '#A6B5B3'
def font(size, bold=False):
    return ImageFont.truetype('/System/Library/Fonts/Hiragino Sans GB.ttc', size, index=int(bold))

header = ImageOps.fit(Image.open(SOURCE).convert('RGB'), (3840, 1646))
draw = ImageDraw.Draw(header)
draw.text((240, 250), '技能五子棋 · 棋逢对手', font=font(74), fill=JADE)
draw.text((230, 480), '五子棋', font=font(188, True), fill=IVORY)
draw.text((230, 710), '玩出新策略', font=font(188, True), fill=IVORY)
draw.text((240, 1040), '九项技能，自由组合', font=font(83), fill=IVORY)
draw.text((240, 1240), '离线人机  /  本机双人', font=font(64), fill=MUTED)
header.save(OUT / 'header-zh-Hans.png')

search = Image.new('RGB', (1920, 1280), INK)
draw = ImageDraw.Draw(search)
draw.text((110, 155), '技能五子棋 · 棋逢对手', font=font(42), fill=JADE)
draw.text((105, 310), '不只落子', font=font(100, True), fill=IVORY)
draw.text((105, 440), '还能出招', font=font(100, True), fill=IVORY)
draw.text((110, 665), '九项技能，改写棋局', font=font(46), fill=IVORY)
draw.text((110, 775), '高阶模式 · 九选三', font=font(38), fill=MUTED)
draw.text((110, 1010), '离线 AI  /  同屏双人', font=font(38), fill=JADE)
# This crop is the real XCTest gameplay capture inside the existing approved composition.
ui = Image.open(ROOT / 'AppStoreAssets/iphone-6.9-promo/01-iphone.png').convert('RGB')
ui = ui.crop((140, 670, 1180, 2800))
ui.thumbnail((780, 1120), Image.Resampling.LANCZOS)
x, y = 1090, 80
draw.rounded_rectangle((x-5,y-5,x+ui.width+5,y+ui.height+5), radius=36, fill=JADE)
mask = Image.new('L', ui.size)
ImageDraw.Draw(mask).rounded_rectangle((0,0,ui.width,ui.height), radius=32, fill=255)
search.paste(ui, (x,y), mask)
search.save(OUT / 'search-zh-Hans.png')
for name in ('header-zh-Hans.png', 'search-zh-Hans.png'):
    im = Image.open(OUT / name)
    print(name, im.size, im.mode)
