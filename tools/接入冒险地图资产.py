"""将审核 v4 资产无损复制到游戏，整理本轮改名 PNG；不重新绘制已定稿美术。"""
from pathlib import Path
import json, shutil
from PIL import Image, ImageEnhance
import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / 'UI拆分预览/冒险地图_草图拆分_v4'
OUT = ROOT / 'Game/Assets/UI/AdventureMap/定稿_v1'
RECORD = ROOT / '美术接入记录/冒险地图'
OUT.mkdir(parents=True, exist_ok=True)
RECORD.mkdir(parents=True, exist_ok=True)
for src in (SOURCE / '透明素材').glob('*.png'):
    if src.name in ['人物属性牌_满血含头像_合成.png', '名牌_集市市场_含字.png']:
        continue
    name = src.name.replace('集市市场', '街口集市')
    if name.startswith('缩略图_'):
        im = Image.open(src).convert('RGB')
        im = ImageEnhance.Color(im).enhance(.82)
        im = ImageEnhance.Contrast(im).enhance(.94)
        im = ImageEnhance.Brightness(im).enhance(1.02)
        im.save(OUT / name)
    else:
        shutil.copy2(src, OUT / name)

generated = Path(r'C:\Users\Administrator\.codex\generated_images\01a1ca1d-b83c-7fe3-83ee-fec5b5fe14ff\exec-47416d6a-608e-43d0-986a-12154605b1b7.png')
shutil.copy2(generated, RECORD / '街口集市_生成原图.png')
ar = np.array(Image.open(generated).convert('RGBA'))
a = ar[:, :, 3]
core = (a >= 192).astype('uint8')
n, labels, stats, _ = cv2.connectedComponentsWithStats(core, 8)
keep = cv2.dilate(np.isin(labels, [i for i in range(1, n) if stats[i, cv2.CC_STAT_AREA] > max(16, core.size*.0003)]).astype('uint8'), np.ones((7, 7), 'uint8'))
ar[:, :, 3] = np.where(keep, np.minimum(a.astype('float32')*255/253, 255), 0).astype('uint8')
ar[ar[:, :, 3] == 0, :3] = 0
im = Image.fromarray(ar)
im = im.crop(im.getchannel('A').getbbox())
scale = min((897-24)/im.width, (318-24)/im.height)
im = im.resize((round(im.width*scale), round(im.height*scale)), Image.Resampling.LANCZOS)
plate = Image.new('RGBA', (897, 318))
plate.alpha_composite(im, ((897-im.width)//2, (318-im.height)//2))
plate.save(OUT / '名牌_街口集市_含字.png')

shadows = []
(OUT / '独立投影').mkdir(exist_ok=True)
for item in json.loads((SOURCE / '制作记录/独立投影位置.json').read_text(encoding='utf-8-sig')):
    filename = Path(item['文件']).name.replace('集市市场', '街口集市')
    shutil.copy2(SOURCE / item['文件'], OUT / '独立投影' / filename)
    x, y, ex, ey = item['裁切边界']
    shadows.append({'file': '独立投影/'+filename, 'rect': [x, y, ex-x, ey-y]})
(OUT / '独立投影布局.json').write_text(json.dumps(shadows, ensure_ascii=False, indent=2), encoding='utf-8')
for filename in ['属性牌槽位.json', '布局与状态.json']:
    shutil.copy2(SOURCE / '制作记录' / filename, RECORD / filename)
(RECORD / '来源说明.md').write_text('''# 冒险地图接入记录

使用《冒险地图_草图拆分_v4》已审核美术。背景、01–12 关卡底座、数字和路径为同一 PNG；主角、光圈、UI 外投影保持独立。
第二章含字名牌通过内置 imagegen 仅更正文字为“街口集市”，生成原图及提示词保存在本目录。导出时等比缩放，保持圆徽章比例和真实 Alpha。
缩略图按原审核预览降低饱和度及对比度；头像、血量和进入文案由运行状态驱动。
复现资产整理：在项目根目录运行 `python tools/接入冒险地图资产.py`（需要本机保留生成原图和 v4 目录）。游戏运行仅依赖 Game/Assets/UI/AdventureMap/定稿_v1，无需外部目录。
''', encoding='utf-8')
print('Imported adventure map artwork:', OUT)
