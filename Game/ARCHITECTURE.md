# 工程结构与编辑入口

| 目录 | 职责 |
| --- | --- |
| Scenes/MainMenu、Battle、Map、Card、Enemy、UI | 各自的场景和视图构建脚本；GameShell协调导航、输入与弹窗，视图读取战斗状态 |
| Scripts/Combat/CombatState.gd | 对局生命周期、玩家伤害、回合、关卡转换 |
| Scripts/CardSystem/CardEffects.gd | 卡牌结算，支持普通费用与X费用 |
| Scripts/CardSystem/DeckSystem.gd | 洗牌、抽牌、手牌上限 |
| Scripts/CardSystem/DeckManager.gd | 出战与备用卡库交互 |
| Scripts/CardSystem/CardCatalog.gd | 读取独立资源，提供运行时副本和自动文案 |
| Scripts/EnemySystem/EnemySystem.gd | 敌方行动、毒素、冰冻、多段攻击 |
| Scripts/LevelSystem/RewardSystem.gd | 根据奖励资源生成卡牌选项 |
| Scripts/SaveSystem/AppSettings.gd | 独立保存音量和显示偏好，管理音频总线与按钮音效 |
| Scripts/SaveSystem/SaveSystem.gd | 序列化、旧存档迁移、恢复随机状态 |
| Resources/Cards、Enemies、Bosses、Levels、Relics、Rewards | 每个内容条目对应独立.tres文件 |
| Data/Config/game_rules.tres | 开局卡组、抽牌数量、手牌上限、路线与难度 |
| Assets | 角色、卡牌/标题、背景、特效、音频及原始美术归档 |
| Data/Localization | 后续翻译表位置，目前中文文案仍在资源中 |

## 自定义Resource

Godot“新建资源”可选择 CardData、EnemyData、BossData、LevelData、RelicData、RewardData、GameConfig。
CardData的effects保存效果参数，upgrade保存升级覆盖值；不会修改共享资源以记录战斗状态。
BossData继承EnemyData，LevelData直接引用其敌人资源。
遗物效果也由资源参数驱动，卡牌目录与遗物目录会自动加载新增.tres。

新增已有机制的卡牌：复制一份Cards资源，更改唯一id、title、cost、effects和upgrade即可。
新增机制：在CardEffects实现效果、CardCatalog.describe添加说明，并在tests/test_rules.gd验证。
调整敌人：编辑对应Enemy/Boss资源中的生命和行动循环。调整关卡：编辑LevelData的enemies引用。
目前仍是12关固定流程；扩展关卡数量需要同步流程和地图。场景视图仍以代码构建控件，可逐步改成编辑器内布局。

## 新效果参数

heal：直接回血；armor_damage：移除护甲后伤害倍率；store_energy：X能量转下回合；stored_bonus：升级额外能量；freeze_all：冻结下一次敌方行动；barrier：抵挡次数；exhaust：使用后本场移出。

金钟罩先于护甲抵挡正伤害，包括自伤；重复使用增加次数。冻结不累加，毒素仍按回合结算。全才伤害在本牌增加力量之前结算。

## 导航与显示

GameShell 的 screen 状态分别为 home（开始界面）、routes（路线确认）、map（四场景地图）、run（战斗/奖励/补给/结局）。HomeView、MainMenuView、MapView、BattleView 和 SettingsView 分别负责视图。

新冒险创建战斗状态后先显示地图；点击当前关卡只切换视图，不重新洗牌或调用 start_battle。营火完成后由 next_stage 初始化下一关，再显示地图。继续冒险读取后锁定路线与难度，确认后回到地图。地图与弹窗阻止战斗快捷键。

逻辑画布为 1600×900，canvas_items + keep 保持 16:9；非 16:9 窗口留边。头像用 AtlasTexture 引用现有主角四视图，不改动原始图片。基础声音设置写入 settings.cfg，与 run_save.json 独立。
