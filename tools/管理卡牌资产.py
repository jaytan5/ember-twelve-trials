"""准备、接入、压缩及核验卡牌素材；正式插图每张不超过500,000字节。"""
import argparse
import hashlib
import json
import shutil
from io import BytesIO
from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parents[1]
WORKSPACE = PROJECT.parent
RECORDS = WORKSPACE / 'output/卡牌拆分/正式接入'
ASSETS = PROJECT / 'Game/Assets/Cards/正式卡牌'
ILLUSTRATION_MAX_BYTES = 500_000
SHELL_NAMES = {
    'neutral': '通用卡外壳_v2_半透明阴影.png',
    'fury': '狂刃卡外壳_最终版_半透明阴影.png',
    'bastion': '铁壁卡外壳_最终版_半透明阴影.png',
    'venom': '蚀毒卡外壳_修正版_内外半透明阴影.png',
}
ROUTES = {'neutral': '通用', 'fury': '狂刃', 'bastion': '铁壁', 'venom': '蚀毒'}
SUBJECTS = {
 'strike': 'one chunky steel sword with a leather grip hitting a wooden training dummy, one broad golden impact arc, stylized wood chips, grassy training ground',
 'quick': 'two small steel daggers crossing in a lightning-fast double cut, two crisp ivory motion trails, blue-green training courtyard',
 'aegis': 'a luminous protective eggshell dome with a fine eggshell texture shielding a small leather backpack from a bouncing arrow, warm golden magical barrier',
 'disarm': 'a lowered enemy axe losing its red magical glow while gentle mint breathing ribbons heal a small adventurer glove in the foreground, peaceful release of tension',
 'expose': 'a magnifying lens revealing one glowing amber crack in an armored practice target, one small precise dagger aimed at that weak point',
 'battle_trance': 'a brass compass beside three blank parchment strategy cards being deliberately rearranged on a wooden planning table, blue directional magical trails',
 'guard': 'one broad round wooden shield with polished steel rim bracing against a shower of harmless sparks, warm forest camp',
 'tactical_strike': 'a short sword brushing aside tall grass to reveal a winding forest path and a blank parchment discovery card floating above the trail',
 'blizzard': 'a wave of sparkling blue ice freezing several stylized stone training enemies in translucent chunky ice crystals, snowy magical clearing',
 'clockwork_bomb': 'a single round bronze clockwork bomb with large winding key and visible clock gears, amber countdown glow without numbers, stone arena, anticipation before detonation',
 'insight': 'a bright blue crystal eye hovering above four blank parchment cards fanning outward over an open travel journal, focused clear magical vision',
 'mend': 'a compact open leather medical satchel with clean bandages and a glowing red healing potion, golden healing particles, forest campsite',
 'polymath': 'a balanced circular arrangement of a sword, shield, small green potion, crimson strength crystal and healing leaf around a central golden orb, five distinct powers united',
 'stunning_blow': 'a small brass bell releasing a powerful circular gold sonic shockwave that makes a chunky stone dummy dizzy, tiny orbiting stars, no impact injury',
 'cleave': 'one massive curved silver blade sweeping horizontally through three straw training dummies, a single broad golden crescent spanning the scene',
 'erudition': 'a thick open adventurer encyclopedia on a wooden desk emitting six blank parchment cards and gentle blue knowledge light, rich readable central silhouette',
 'sunder': 'a heavy square warhammer shattering an empty steel breastplate into large stylized armor fragments, brilliant amber impact, no body inside armor',
 'wild_cast': 'an open magical tome unleashing three blank glowing spell cards that cast different gold blue and green spells in sequence, swirling inspiration spark',
 'brace': 'a brass energy accumulator lantern storing several blue lightning wisps inside a clear crystal chamber, a sunrise glow behind it suggesting energy saved for tomorrow',
 'sting': 'a concealed green poison vial hidden behind a folded blank strategy parchment, emerald vapor curling around its cork, mysterious woodland desk',
 'recycle': 'four green poison droplets being drawn out of a stone target into a blue glowing energy crystal, curved alchemical recycling flow, forest laboratory',
 'venom_dart': 'one slender silver dart tipped with a single luminous green poison droplet flying rapidly through mossy woodland air, clear needle silhouette',
 'corrosion': 'a tipped dark glass vial pouring luminous green acid over an empty steel gauntlet as its surface softly corrodes, safe stylized alchemy workshop',
 'poison_trigger': 'one emerald poison droplet pulsing with a sharp concentric toxic shockwave on a chunky stone training target, immediate activation with green sparks',
 'venom_pierce': 'one bright emerald dagger chasing a trail of stacked glowing poison droplets toward a stone training target, active green momentum, poison empowered strike',
 'poison_stab': 'one curved dagger with luminous green poison coating lunging forward from woodland shadows, one bold sweeping green slash arc',
 'poison_guard': 'a semicircular translucent emerald mist shield surrounding a round wooden shield, green mist spilling outward toward distant stone targets',
 'catalyst': 'a round glass alchemy flask in which two green poison droplets multiply into many bright emerald bubbles, magical chemical reaction, mossy laboratory',
 'coating': 'a small alchemy brush applying a thick bright emerald poison coating to a clean steel blade on a workbench, green droplets and simple tools',
 'leech': 'a curved green magical blade drawing a thin ribbon of luminous emerald life energy from a stone target into a glowing healing leaf in the foreground, no blood',
 'detonate': 'a brilliant emerald alchemical explosion bursting out of stacked poison droplets, a distant stone dummy silhouetted in the green blast, no gore',
 'plague': 'billowing emerald toxic fog rolling over a field of several chunky stone training enemies, large readable layers of green mist, purple magical accents',
 'counter': 'a stout round steel shield reflecting an incoming orange impact back along a sharp golden rebound arrow of light, thorns glowing on the rim',
 'fortify': 'a single thick blue steel tower shield planted firmly in the earth, a luminous blue protective aura, small stones at its base, forest clearing',
 'shield_bash': 'a heavy blue steel shield slamming forward into a wooden dummy with a bright gold collision star and blue forward momentum',
 'shield_draw': 'a neatly arranged steel shield and helmet beside a blank parchment strategy card being pulled from a leather satchel, prepared adventurer equipment',
 'thorn_armor': 'a rounded steel breastplate wrapped in a few thick green thorn vines, a blue armor glow and sharp readable golden thorns',
 'thorn_pierce': 'one large silver thorn-shaped spear tip piercing forward from a thorn-covered round shield, focused blue and gold thrust, no body',
 'armor_sacrifice': 'blue steel armor plates disassembling and fusing into a single massive forward golden strike, empty discarded armor shell behind the shockwave',
 'hold': 'a thick blue stone fortress shield anchored behind solid stone blocks, a calm persistent blue magical barrier and golden anchor motif',
 'rampart': 'a line of three empty rounded steel shields charging forward together through dust and golden impact arcs toward distant wooden targets',
 'thorns': 'thick thorn vines rapidly growing around a steel shield and blossoming into bright gold defensive spikes, small green leaves, magical forest light',
 'bulwark': 'a complete suit of chunky blue steel armor displayed with a huge reinforced shield, bright blue protective aura, confident fortress armory',
 'thorn_storm': 'a fan-shaped volley of many large luminous steel thorns launching outward from a round shield toward multiple wooden targets, blue and gold energy',
 'blood_charge': 'a cracked red heart-shaped crystal giving up small warm red sparks to ignite a large blue lightning crystal, clear energy-for-vitality exchange, no gore',
 'double': 'two chunky steel swords executing two consecutive red-gold slash arcs against a straw dummy, energetic warm arena',
 'desperate_strength': 'a chipped red heart-shaped crystal resting near a sword that is charging with powerful sunrise-red energy, strength gathered for the next moment',
 'hunt_mark': 'a focused red magical targeting reticle without text highlighting a single crack in an armored wooden training dummy, one blade poised in foreground',
 'rage': 'an upright steel sword planted in stone with an unwavering warm red flame aura and golden sparks, steady determination, simple strong silhouette',
 'warcry': 'a brass battle horn releasing a strong crimson-gold shockwave across a training arena, a bright brief flare of power, no characters needed',
 'rage_slash': 'a cracked red heart crystal awakening with a fierce crown of red-gold flame above two crossed swords, dramatic comeback power, no lettering',
 'execute': 'a battered steel sword making one enormous red-gold finishing slash powered by a chipped red heart crystal behind it, dynamic heroic momentum, no body or gore',
 'triple': 'three consecutive silver blade streaks spiraling through the air in a fast crimson wind current, straw training dummy, crisp readable triple rhythm',
 'whirlwind': 'several curved steel blades swirling unpredictably around three straw training dummies, separated red-gold slash arcs targeting different directions',
 'bloodlust': 'a steel sword surrounded by red-gold life-energy ribbons flowing back into a glowing heart-shaped crystal, warm magical restoration through battle, no blood',
 'heavy_strike': 'a single huge steel greatsword committed to one dramatic downward gold-red impact, a cracked red crystal at the pommel, all-or-nothing attack on an empty stone target',
}
# 上方以语义记录场景，此处按现有游戏的稳定历史 ID 归位。
_semantic = SUBJECTS.copy()
for _id, _subject in {
 'focus':'battle_trance', 'stockpile':'brace', 'brace':'sting',
 'sweep':'cleave', 'cleave':'double', 'bloodlust':'blood_charge',
 'blood_charge':'execute', 'execute':'heavy_strike', 'battle_trance':'bloodlust',
 'shield_charge':'rampart', 'thorn_growth':'thorns', 'rampart':'bulwark',
 'sting':'poison_stab', 'toxic_guard':'poison_guard',
}.items():
 SUBJECTS[_id] = _semantic[_subject]

def save(path, value):
 path.parent.mkdir(parents=True, exist_ok=True)
 path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def prepare():
 cards = json.loads((WORKSPACE / 'output/卡牌拆分/卡牌数据.json').read_text(encoding='utf-8'))
 missing = [c['id'] for c in cards if c['id'] not in SUBJECTS]
 if missing:
  raise ValueError(f'缺少提示词: {missing}')
 manifest = {'version':1, 'date':'2026-11-13', 'shells':{}, 'cards':{}}
 for route, name in SHELL_NAMES.items():
  source = WORKSPACE / 'output/卡牌拆分/卡牌模板' / name
  relative = f'外壳/{name}'
  target = ASSETS / relative
  target.parent.mkdir(parents=True, exist_ok=True)
  shutil.copy2(source, target)
  manifest['shells'][route] = relative
 tasks = []
 for c in cards:
  relative = f"插图/{ROUTES[c['route']]}/{c['id']}_{c['name']}.webp"
  prompt = ('Use case: stylized-concept. Asset type: one landscape trading-card illustration for the warm whimsical 3D fantasy game 小泥团，出击！. '
   f"Card name: {c['name']}. Exact game effect for semantic reference only: {c['description']}. "
   f"Depict: {SUBJECTS[c['id']]}. "
   'Thick rounded toy-like geometry, polished hand-painted 3D mobile fantasy game aesthetic, clear broad shapes, warm upper-left directional light, strong readable silhouettes, uncluttered central composition. '
   'Landscape 1536x1024, keep essential subject within central 80 percent so it survives cropping into a wide 1.76:1 artwork window. Full-bleed illustrated environment, opaque image. '
   'No card frame, no lettering, no numbers, no border, no watermark, no UI, no gore. One illustration only. Depict equipment, inanimate training dummies and magical effects only; no living character, no person, no creature, no mascot.')
  manifest['cards'][c['id']] = {**c, 'illustration':relative, 'shell':manifest['shells'][c['route']], 'upgrade_art':'reuse_base', 'status':'pending'}
  tasks.append({'id':c['id'], 'name':c['name'], 'target':str(ASSETS/relative), 'prompt':prompt})
 save(ASSETS / '卡牌资产映射.json', manifest)
 save(RECORDS / '逐卡生成提示词.json', tasks)
 (RECORDS / '.gdignore').write_text('', encoding='utf-8')
 print(f'Prepared {len(tasks)} cards and {len(SHELL_NAMES)} exact original shells')

def encode_illustration(source: Path) -> tuple[bytes, dict]:
 """从原图编码，保留分辨率与Alpha，避免重复压缩已经有损的运行版。"""
 with Image.open(source) as original:
  original.load()
  image = original.convert('RGBA' if 'A' in original.getbands() else 'RGB')
  for quality in [95, 92, 90, 87, 84, 80, 75, 70]:
   output = BytesIO()
   image.save(output, format='WEBP', quality=quality, method=6,
              icc_profile=original.info.get('icc_profile', b''))
   payload = output.getvalue()
   if len(payload) <= ILLUSTRATION_MAX_BYTES:
    return payload, {'format':'WebP', 'quality':quality, 'method':6,
                     'max_bytes':ILLUSTRATION_MAX_BYTES, 'size':list(image.size)}
 raise ValueError(f'保留原分辨率时仍无法满足容量上限: {source}')

def ingest():
 manifest = json.loads((ASSETS / '卡牌资产映射.json').read_text(encoding='utf-8'))
 for card in json.loads((WORKSPACE / 'output/卡牌拆分/卡牌数据.json').read_text(encoding='utf-8')):
  manifest['cards'][card['id']].update(card)
 generated = RECORDS / '已生成图片.json'
 sources = json.loads(generated.read_text(encoding='utf-8')) if generated.exists() else {}
 for record in (RECORDS / '图片元数据').glob('*.json'):
  sources[record.stem] = json.loads(record.read_text(encoding='utf-8'))
 # 写入前检查全部原图，保留可重新编码的高质量来源。
 for id, record in sources.items():
  if not Path(record['source']).is_file(): raise FileNotFoundError(f"原图缺失: {id}")
 backup = RECORDS / '容量优化/压缩前映射.json'
 if not backup.exists(): save(backup, manifest)
 compression_rows = []
 retired_files = []
 for id, record in sources.items():
  source = Path(record['source'])
  card = manifest['cards'][id]
  previous = ASSETS / card['illustration']
  previous_bytes = previous.stat().st_size if previous.exists() else 0
  target = previous.with_suffix('.webp')
  target.parent.mkdir(parents=True, exist_ok=True)
  payload, compression = encode_illustration(source)
  target.write_bytes(payload)
  with Image.open(target) as im:
   record['size'] = list(im.size)
   record['mode'] = im.mode
   im.verify()
  record['sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
  record['compression'] = compression
  record['bytes'] = len(payload)
  card.update({'illustration':target.relative_to(ASSETS).as_posix(), 'status':'ready',
               'source':str(source), 'sha256':record['sha256'], 'size':record['size'],
               'bytes':len(payload), 'compression':compression})
  compression_rows.append({'id':id, 'name':card['name'], 'path':card['illustration'],
                           'previous_bytes':previous_bytes, 'bytes':len(payload),
                           'source_bytes':source.stat().st_size, **compression})
  if previous != target and previous.is_file(): retired_files.append(previous)
 manifest['illustration_policy'] = {'format':'WebP', 'max_bytes':ILLUSTRATION_MAX_BYTES,
                                    'preserve_resolution':True, 'preserve_original_source':True}
 save(ASSETS / '卡牌资产映射.json', manifest)
 save(generated, sources)
 tasks_path = RECORDS / '逐卡生成提示词.json'
 if tasks_path.exists():
  tasks = json.loads(tasks_path.read_text(encoding='utf-8'))
  for task in tasks:
   if task['id'] in sources:
    task['prompt'] = sources[task['id']]['prompt']
    task['source'] = sources[task['id']]['source']
    task['target'] = str(ASSETS / manifest['cards'][task['id']]['illustration'])
  save(tasks_path, tasks)
 # 仅清理本项目内已被正式WebP替代的PNG及其导入描述，外壳与原图不在此范围。
 illustration_root = (ASSETS / '插图').resolve()
 for previous in retired_files:
  if not previous.resolve().is_relative_to(illustration_root) or previous.suffix.lower() != '.png':
   raise ValueError(f'清理目标超出插图范围: {previous}')
  previous.unlink()
  previous.with_suffix(previous.suffix + '.import').unlink(missing_ok=True)
 report = {'count':len(compression_rows), 'max_allowed_bytes':ILLUSTRATION_MAX_BYTES,
           'previous_bytes':sum(row['previous_bytes'] for row in compression_rows),
           'total_bytes':sum(row['bytes'] for row in compression_rows),
           'largest_bytes':max(row['bytes'] for row in compression_rows),
           'all_within_limit':all(row['bytes'] <= ILLUSTRATION_MAX_BYTES for row in compression_rows),
           'cards':compression_rows}
 save(RECORDS / '容量优化/插图容量核验.json', report)
 print(f"Ingested {len(sources)}/{len(manifest['cards'])} illustrations")

def verify():
 manifest = json.loads((ASSETS / '卡牌资产映射.json').read_text(encoding='utf-8'))
 errors = []
 for route, name in SHELL_NAMES.items():
  source = WORKSPACE / 'output/卡牌拆分/卡牌模板' / name
  target = ASSETS / manifest['shells'][route]
  if source.read_bytes() != target.read_bytes(): errors.append('外壳像素被改动: ' + route)
 for id, c in manifest['cards'].items():
  path = ASSETS / c['illustration']
  if not path.exists(): errors.append('缺失: ' + id)
  elif c.get('sha256') != hashlib.sha256(path.read_bytes()).hexdigest(): errors.append('哈希不符: ' + id)
  if path.exists():
   if path.stat().st_size > ILLUSTRATION_MAX_BYTES: errors.append('插图超过0.5MB: ' + id)
   if path.stat().st_size != c.get('bytes'): errors.append('容量记录不符: ' + id)
   with Image.open(path) as image:
    if list(image.size) != c['size']: errors.append('尺寸记录不符: ' + id)
    image.verify()
 report = {'total':len(manifest['cards']), 'ready':sum(c['status']=='ready' for c in manifest['cards'].values()), 'shells':len(SHELL_NAMES),
           'illustration_max_bytes':ILLUSTRATION_MAX_BYTES,
           'largest_illustration_bytes':max((ASSETS / c['illustration']).stat().st_size for c in manifest['cards'].values()), 'errors':errors}
 save(RECORDS / '文件完整性核验.json', report)
 print(json.dumps(report, ensure_ascii=False))
 return bool(errors)

if __name__ == '__main__':
 parser = argparse.ArgumentParser(description=__doc__)
 parser.add_argument('action', choices=['prepare','ingest','verify'])
 args = parser.parse_args()
 if args.action == 'prepare': prepare()
 elif args.action == 'ingest': ingest()
 else: raise SystemExit(verify())
