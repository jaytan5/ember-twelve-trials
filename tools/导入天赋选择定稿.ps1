$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$previewRoot = Join-Path (Split-Path $projectRoot -Parent) 'UI拆分预览\天赋路线_v2'
$target = Join-Path $projectRoot 'Game\Assets\UI\TalentSelection\定稿_v2'
New-Item -ItemType Directory -Force -Path $target | Out-Null
Get-ChildItem -LiteralPath (Join-Path $previewRoot '透明素材') -Filter '*.png' | Where-Object {$_.Name -notlike '文字层_*'} | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $target}
$previewSource = [System.IO.File]::ReadAllText((Join-Path $previewRoot '制作记录\组装预览.ps1'))
$classSource = [regex]::Match($previewSource,"(?s)\`$code = @'\r?\n(.*?)\r?\n'@").Groups[1].Value
if (-not $classSource) {throw 'Cannot read approved alpha processing source'}
$classSource = $classSource.Substring(0,$classSource.IndexOf(' public static void Compose')) + '}'
# Reuse the approved inset/blur algorithm without rerunning the preview.
$classSource = $classSource.Replace('public static void Glow()','public static void Glow(string sprite, string output)')
$classSource = $classSource.Replace('Draw(g,"卡包_狂刃_无字.png",28,25,284,377,false)','Draw(g,sprite,28,25,284,377,false)')
$classSource = $classSource.Replace('"选中_狂刃轮廓光晕.png"','output')
Add-Type -TypeDefinition $classSource -ReferencedAssemblies System.Drawing
$work = Join-Path $projectRoot 'test-results\天赋资源处理'
New-Item -ItemType Directory -Force -Path (Join-Path $work '透明素材') | Out-Null
Get-ChildItem -LiteralPath $target -Filter '*.png' | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $work '透明素材')}
[UiPreview]::Root=$work
Get-ChildItem -LiteralPath (Join-Path $work '透明素材') -Filter '*.png' | ForEach-Object {
 $bitmap = [System.Drawing.Bitmap]::new($_.FullName)
 try {[UiPreview]::Body[$_.Name]=[UiPreview]::Bounds($bitmap,24)} finally {$bitmap.Dispose()}
}
foreach($name in @('蚀毒','铁壁')) {
 [UiPreview]::Glow("卡包_${name}_无字.png","选中_${name}轮廓光晕.png")
 Copy-Item -LiteralPath (Join-Path $work "透明素材\选中_${name}轮廓光晕.png") -Destination $target
}
function Fit-Rect([string]$name,[double]$x,[double]$y,[double]$width,[double]$height) {
 $body=[UiPreview]::Body[$name];$image=[System.Drawing.Bitmap]::new((Join-Path $target $name))
 try {return @(($x-$body.X*$width/$body.Width),($y-$body.Y*$height/$body.Height),($image.Width*$width/$body.Width),($image.Height*$height/$body.Height))} finally {$image.Dispose()}
}
$normal=[System.IO.File]::ReadAllText((Join-Path $previewRoot '制作记录\布局_普通态.json')) | ConvertFrom-Json
function Preview-Rect($list,[string]$name) {$v=$list | Where-Object {$_.file -eq "透明素材/$name"} | Select-Object -First 1;return @($v.x,$v.y,$v.w,$v.h)}
$decorations=@()
foreach($entry in @(@('TalentFrame','框架_灯笼旗帜空白牌匾.png'),@('TalentCharacter','人物_含随身投影.png'),@('TalentTray','底部_木质托盘.png'))) {
 $decorations+=@{name=$entry[0];file=$entry[1];rect=(Preview-Rect $normal $entry[1])}
}
$routes=@();$routeIds=@('venom','fury','bastion');$routeNames=@('蚀毒','狂刃','铁壁');$centers=@(@(606,583),@(931,592),@(1251,589));$xs=@(464,790,1109)
for($i=0;$i -lt 3;$i++) {
 $name=$routeNames[$i];$file="卡包_${name}_无字.png";$n=Preview-Rect $normal $file;$s=Fit-Rect $file $xs[$i] 256 284 377
 $selectedCenter=@(($s[0]+($centers[$i][0]-$n[0])/$n[2]*$s[2]),($s[1]+($centers[$i][1]-$n[1])/$n[3]*$s[3]))
 if($i -eq 1){$selectedCenter=@(931,582)}
 $routes+=@{id=$routeIds[$i];title=$name;file=$file;normal_rect=$n;selected_rect=$s;normal_center=$centers[$i];selected_center=$selectedCenter;glow="选中_${name}轮廓光晕.png";glow_rect=@(($xs[$i]-28),231,340,435);badge_rect=@(($centers[$i][0]-111.8362),622.7031,223.6723,63.59375);badge_center=@(($centers[$i][0]+20),652)}
}
$difficulties=@();$diffIds=@('easy','normal','hard','legendary');$diffNames=@('轻松','标准','勇者','传奇');$diffXs=@(383,584,786,987)
for($i=0;$i -lt 4;$i++) {$difficulties+=@{id=$diffIds[$i];title=$diffNames[$i];normal_rect=(Fit-Rect '按钮_难度普通_无字.png' $diffXs[$i] 787 177 88);selected_rect=(Fit-Rect '按钮_难度选中_含勾_无字.png' $diffXs[$i] 777 188 101);normal_center=@(($diffXs[$i]+88),831);selected_center=@(($diffXs[$i]+88),835)}}
$manifest=@{design_size=@(1672,941);background='背景_村庄庭院.png';decorations=$decorations;routes=$routes;difficulties=$difficulties;difficulty_normal='按钮_难度普通_无字.png';difficulty_selected='按钮_难度选中_含勾_无字.png';badge='徽章_卡包已选择_无字.png';back=@{file='按钮_返回_含箭头_无字.png';rect=(Preview-Rect $normal '按钮_返回_含箭头_无字.png');center=@(166,66)};confirm=@{file='按钮_开始冒险_无字.png';rect=(Preview-Rect $normal '按钮_开始冒险_无字.png');center=@(1415,832)}}
[System.IO.File]::WriteAllText((Join-Path $target '界面布局.json'),($manifest|ConvertTo-Json -Depth 12),[System.Text.UTF8Encoding]::new($false))
Write-Output '已导入确认版素材、三类向内留余量的光晕与界面布局。'
# Production display is smaller than source artwork; use mipmaps for clean material transitions.
Get-ChildItem -LiteralPath $target -Filter '*.png.import' | ForEach-Object {
 $metadata=[System.IO.File]::ReadAllText($_.FullName).Replace('mipmaps/generate=false','mipmaps/generate=true')
 [System.IO.File]::WriteAllText($_.FullName,$metadata,[System.Text.UTF8Encoding]::new($false))
}
