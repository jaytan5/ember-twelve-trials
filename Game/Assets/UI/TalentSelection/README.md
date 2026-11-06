# 天赋选择页：已接入确认版 v2（2026-11-06）

当前界面使用 [定稿_v2/接入说明.md](定稿_v2/接入说明.md) 中的分层方案：渐变虚化背景、独立人物与随身投影、框架、三类卡包、木托盘、普通／选中按钮。原生文字按字形边界居中，带少量暖棕投影；三类选中光晕内缘向内缩进 10 像素，藏在卡包下方。

当前入口仍为 `Game/Scenes/MainMenu/Components/TalentScreen.tscn`。它使用专用的 `TalentArtButton.gd` 和 `TalentText.gd`，保留选择、返回、确认与续玩锁定。原主页、其他菜单及共享 ArtButton 不受这次样式替换影响。

## 以下为旧 Premium Stylized 3D 方案记录

下面的旧素材、旧 modules.json、SelectionOutline 动态效果与复现命令保留用于历史回看，不再是当前天赋页的生产资源。

只修改天赋选择页；主页 HomeView、HomeMenuButton、视频、Logo 和原主页按钮保持原样。

三张路线卡牌和四个难度按钮分别使用独立透明 PNG。统一圆润金边、暖色木质、干净的立体材质、左上方柔光，保持精品 3D 卡通冒险风格。没有从整屏截图切下带背景的按钮。

| 模块 | 资源 | 内容 |
| --- | --- | --- |
| 红砖村落与展示木架 | VillageDisplayBackground.png | 低细节背景、柔和景深、与木架连接的墨绿展示板；原村落背景保留 |
| 蚀毒／狂刃／铁壁 | RouteVenom / RouteFury / RouteBastion.png | 各自独立的 3D 卡牌，狂刃居中 |
| 四个难度 | DifficultyEasy / Normal / Hard / Legendary.png | 独立绘制，蓝／棕金／紫／红 |
| 标题、开始／继续、返回 | RedGoldBar.png | 统一红金底框，文字由引擎绘制 |

运行场景：Game/Scenes/MainMenu/Components/TalentScreen.tscn。九个交互控件分别接收输入；标题及装饰不拦截鼠标。所有标题、卡名、八字介绍、难度名称均是独立 Label，支持后续调整位置与字号。

ArtButton 使用图片 alpha 生成点击遮罩。SelectionOutline 着色器在控件边界外扩展 30 像素，不改变点击区域；绘制暖色柔投影、选中状态约 2.5 秒一周期的呼吸光圈及沿边移动的亮光；外光采用高斯径向积分平滑衰减，避免多层硬边。选中项放大至 1.035 倍，未选项缩至 0.98 倍并降低亮度与饱和度。路线下方显示“✓ 已选择”，难度右上显示勾选徽记。键盘焦点和悬停只有轻光，不冒充选中状态。悬停显示轻光，按下微缩，键盘焦点同样可见。光圈与阴影不烘焙在图片中。透明边缘采样抑制原图极低 alpha 噪点，保留平滑轮廓。主体不随呼吸闪烁。

继续冒险沿用存档路线和难度，七个选择项锁定；确认仍进入地图并完整保留存档。新冒险按钮为“开始冒险”。

## 原图与复现

当前原图和完整提示词：Source/Premium3D/，使用内置 image_gen（非 CLI/API）。八份独立透明素材均留存原始 alpha，展示板背景另外保留完整原图。旧 Source 根目录仅作历史参考。

运行 Godot --headless --path . --script res://tools/split_menu_art.gd：从 Premium3D 原图按实体 alpha 范围规整透明外边距，保留抗锯齿边缘，导出八张透明生产 PNG、完整展示板背景和当前 modules.json。随后执行编辑器 --import。不会恢复旧版截图裁切素材。

modules.json 使用 1672×941 归一化坐标，项目仍采用 1600×900 的 16:9 逻辑画布。

## 验证

tests/test_talent_ui.gd：86 项渲染检查，覆盖九个独立控件、透明点击区域、唯一选中、键盘顺序、八字介绍、难度文字、选中标记唯一性、缩放/亮度/饱和度差异、焦点不冒充选中、两类光圈的跨帧像素变化、不同窗口尺寸、续玩锁定与返回原主页。ui_feedback 和 ui_smoke 检查原主页及完整导航流程。
