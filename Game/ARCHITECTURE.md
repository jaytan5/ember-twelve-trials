# 工程结构与编辑入口

| 目录 | 职责 |
| --- | --- |
| Scenes/MainMenu、Battle、Map、Card、Enemy、UI | 各自的场景和视图构建脚本；GameShell协调导航、输入与弹窗，视图读取战斗状态 |
| Scenes/Battle/BattleAnimator.gd | 依次播放受击震动、护盾/治疗闪光和血条插值；GameShell在隔离副本上生成事件，播放完成后才提交状态、随机数状态与存档 |
| Scenes/Card/CardNameButton.gd | 卡组管理的卡名按钮，原生鼠标悬停弹出完整卡牌；沿用独立副本的拖动与升级信息 |
| Scenes/MainMenu/HomeView.gd | 开场 Logo、开始界面菜单和无声 OGV 循环背景；背景播放器跨界面重绘保留，由 GameShell 按 title/home 状态启停 |
| Scenes/Map/AdventureMapScreen.gd、MapArtButton.gd | 独立 1600×900 地图美术画布、12 关浏览热区、主角与光圈、真实血量、固定轮廓的透明图像按钮；MapView 负责实例化 |
| Assets/UI/AdventureMap/定稿_v1 | v4 审核素材的工程内版本，第二章含字名牌更正为街口集市；背景含底座、数字、皇冠与路线，外部投影按独立 JSON 坐标放置 |
| Scripts/Combat/CombatState.gd | 对局生命周期、玩家伤害、回合、关卡转换 |
| Scripts/CardSystem/CardEffects.gd | 卡牌结算，支持普通费用与X费用 |
| Scripts/CardSystem/DeckSystem.gd | 洗牌、抽牌、手牌上限 |
| Scripts/CardSystem/DeckManager.gd | 出战与备用卡库交互 |
| Scripts/CardSystem/CardCatalog.gd | 读取独立资源，提供运行时副本和自动文案 |
| Scripts/EnemySystem/EnemySystem.gd | 敌方行动、毒素、冰冻、多段攻击 |
| Scripts/LevelSystem/RewardSystem.gd | 根据奖励资源生成卡牌选项 |
| Scripts/SaveSystem/AppSettings.gd | 独立保存音量和显示偏好，管理音频总线、按钮音效与菜单循环 BGM；GameShell 按界面状态启停音乐 |
| Scripts/SaveSystem/SaveSystem.gd | 序列化、旧存档迁移、恢复随机状态 |
| Resources/Cards、Enemies、Bosses、Levels、Relics、Rewards | 每个内容条目对应独立.tres文件 |
| Data/Config/game_rules.tres | 开局卡组、抽牌数量、手牌上限、路线与难度 |
| Assets | 角色、卡牌/标题、背景、特效、音频及原始美术归档 |
| Assets/Videos/MainMenu | 开始界面视频资源，实际引用项目内 OGV，可随项目打包 |
| Assets/UI/Titles | 开场透明 Logo 及素材来源、布局登记 |
| Scenes/UI/GameCursor.gd、Assets/UI/Cursors | 内置星芒小剑 PNG，48×48 硬件指针，剑尖热点 (5,1)，各鼠标形态统一使用 |
| Assets/Fonts | 阿里妈妈方圆体 VF、MiSans Regular、FontVariation 标题样式与版权说明；GameShell 统一设置字体角色 |
| Data/Localization | 后续翻译表位置，目前中文文案仍在资源中 |

## 自定义Resource

冒险地图中 `selected_stage` 仅属于视图，不写入对局状态；所有 01–12 可点击查看，`GameShell.enter_map_stage` 仍只允许当前 `s.stage`，入口不重建战斗。右下文案随 battle/reward/relic/camp/结束阶段变化，返回主页调用原有存档逻辑。头像圆形裁剪、血条按真实生命裁切，UI 与地图统一等比缩放。`tests/test_adventure_map_art.gd` 覆盖真实点击、全部节点、进度/随机数保持、弹窗阻挡及窗口缩放；美术来源和提示词在工程根 `美术接入记录/冒险地图/`。

Godot“新建资源”可选择 CardData、EnemyData、BossData、LevelData、RelicData、RewardData、GameConfig。
CardData的effects保存效果参数，upgrade保存升级覆盖值；不会修改共享资源以记录战斗状态。
BossData继承EnemyData，LevelData直接引用其敌人资源。
遗物效果也由资源参数驱动，卡牌目录与遗物目录会自动加载新增.tres。

新增已有机制的卡牌：复制一份Cards资源，更改唯一id、title、cost、effects和upgrade即可。
新增机制：在CardEffects实现效果、CardCatalog.describe添加说明，并在tests/test_rules.gd验证。
调整敌人：编辑对应Enemy/Boss资源中的生命和行动循环。调整关卡：编辑LevelData的enemies引用。
目前仍是12关固定流程；扩展关卡数量需要同步流程和地图。场景视图仍以代码构建控件，可逐步改成编辑器内布局。

## 新效果参数

heal：直接回血；armor_damage：移除护甲后伤害倍率；store_energy：X能量转下回合；energy：本回合立即获得能量（厚积薄发升级为1）；freeze_all：冻结下一次敌方行动；barrier：抵挡次数；exhaust：使用后本场移出。

金钟罩先于护甲抵挡正伤害，包括自伤；重复使用增加次数。`barrier_reflects` 按施放顺序记录各次护罩的反弹比例，升级为50%，反弹给传入 `take_player_damage` 的实际攻击者，自伤不反弹。冻结不累加，毒素仍按回合结算。全才伤害在本牌增加力量之前结算。

`weak`、`vulnerable` 记录剩余回合，基础1、升级2，敌方阶段结束统一递减，防御、蓄力与冰冻均计时；重复施加取较长剩余时间。`low_hp_crit_threshold` 记录暴力执法的35%／50%生命门槛，每段重新判断。`self_damage_unless_kill` 在破阵攻击结算后检查目标，存活才扣10生命。药水规则上限2瓶，永久删牌接口与商店入口已移除。

## 导航与显示

GameShell 的 screen 状态分别为 title（启动时的纯背景、Logo 与开始提示）、home（开始菜单）、routes（路线确认）、map（四场景地图）、run（战斗/奖励/补给/结局）。HomeView、MainMenuView、MapView、BattleView 和 SettingsView 分别负责视图。title 不创建页眉、页脚或菜单，_input 消耗首次按键/点击/触摸/手柄按键后切换 home，保留背景视频和音乐进度；返回主界面直接进入 home。

新冒险创建战斗状态后先显示地图；点击当前关卡只切换视图，不重新洗牌或调用 start_battle。营火完成后由 next_stage 初始化下一关，再显示地图。继续冒险读取后锁定路线与难度，确认后回到地图。地图与弹窗阻止战斗快捷键。弹窗使用绝对 `z_index=100` 并接收焦点，覆盖选中卡包和难度按钮的局部层级。

默认窗口为 1280×720，逻辑画布为 1600×900，canvas_items + keep 保持 16:9；非 16:9 窗口留边。头像用 AtlasTexture 引用现有主角四视图，不改动原始图片。基础声音设置写入 settings.cfg，与 run_save.json 独立。

应用显示名称为「小泥团，出击！」；`application/config/custom_user_dir_name` 固定原有的 `Godot/app_userdata/余烬十二关 · 卡牌 Demo`，兼容原存档和设置。项目目录无需随显示名称变更。

## 遗物与小关重试

遗物沿用 fang/shell/spikes 的稳定 ID，分别更新为进阶宝石、连击齿轮、逆命护符，已有存档保留持有关系。`relic_bonus()` 同时计算通用与当前路线的 `route_bonuses`。开战护甲在首个 `begin_turn()` 清理旧护甲之后发放，避免被首回合清零；首次毒加成沿用整场共用的 first_poison。

`turn_cards_played` 仅在成功出牌后计数，begin_turn 清零；第2、4、6张卡牌效果结束且角色存活时处理连击齿轮，再统一检查胜负。齿轮走 hit_enemy，因此使用已有伤害动画队列。`fate_triggers` 在 start_battle 清零，begin_turn 检查生命严格低于50%，每场最多3次发放额外抽牌与能量；两字段均随存档保存。

存档 v7 在 start_battle 完成首回合初始化后保存 `battle_checkpoint`（无嵌套快照的完整开战状态，以及用字符串保存的 RNG state）。前三档仅在 defeat 可重试；可先调整卡组，重试从快照恢复开战资源，保留调整后的出战与备用卡组，沿用当前随机状态重新洗牌、抽牌并重建快照，界面提交结果后保存；legendary 的 allow_retry=false，规则层也禁止调用重试。新关覆盖快照，界面动画的隔离副本会携带它，战败动画播放完成后才展示重试按钮。v1–v6 存档缺少开战快照时保留现有资源、满血重建本关，下一关起使用完整快照。旧战斗中已经产生的属性不追溯扣回，新遗物的开战效果在下一次开战时生效。

当前存档v8：加载主状态与开战快照时统一迁移药水上限、暴力执法门槛、护罩反弹队列、旧持续状态；v8的2回合状态与混合护罩队列读写保持原样。

## 天赋页独立美术组件

MainMenuView 只实例化 Components/TalentScreen.tscn。该场景组合静态背景/标题与九个独立 TextureButton；RouteCard、DifficultyButton 采用同一 ArtButton 状态实现，SelectionOutline 提供扩展到控件外的柔和阴影、呼吸光圈与流动边缘亮光。卡牌与难度各自使用独立 Premium Stylized 3D 素材，文字由引擎单独排版。按钮在选择时原地更新，不改写对局数据。新冒险和存档确认仍调用 GameShell 的原有服务。

资源与导出说明见 Assets/UI/TalentSelection/README.md。主页 HomeView 与 HomeMenuButton 已恢复本次修改前内容；新样式仅用于天赋页。

2026-11-12：暴力执法门槛更新为35%／50%，加载时同步迁移原30%／45%的主状态与重试快照。厚积薄发升级在扣除全部能量并记录X后，本回合立即通过energy获得1点；下回合仅发放X，不包含这1点。

## 2026-11-12 卡牌扩充

新增9个独立Resource，当前为通用20张、三路线各12张，总计56张。奖励与商店自动收录，图鉴数量动态读取。

`stun`控制单体跳过行动；`mark_crit/mark_turns`为敌方标记，只有攻击牌通过hit_enemy的attack参数享受加成；与低血暴击相加后统一掷一次。EnemySystem在敌方阶段结束递减标记。

`autoplay`通过CardEffects.resolve_card共用出牌流程；整批预取，不占手牌位，免费结算、正常计数和移出。单次手动出牌共用64次自动结算预算，胜负后剩余预取牌回弃牌堆。自动X牌读取当前能量但不扣费。

`bomb_damage`写入状态bombs队列，记录目标、到期回合和伤害；CombatState.end_turn在敌方行动前结算，随后检查胜负。目标死亡自动转向首个存活目标。

怒吼的`turn_strength`立即增加力量，本玩家回合结束移除；`lost_hp_next_strength`在出牌时计算失血百分比并加入next_strength，沿用下一回合临时力量机制。存档v8增加可选字段，主状态与重试快照加载时补齐，不追溯改写旧存档已经排定的next_strength。

铁壁：consume_block_damage先消耗护甲，thorns_attack读取永久与临时反伤；蚀毒：trigger_poison立即结算毒伤，preserve_poison控制是否减层，poison_damage_cap限定毒层对普通攻击的加成。
