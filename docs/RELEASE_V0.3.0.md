# v0.3.0 视觉改版

2026-10-08，按已确认的地球探索概念图实现。工程：`/Users/penn/Projects/solar-system-explorer`。

## 可体验内容

- 应用默认打开探索页并聚焦上次选择的行星；首次为地球。默认暂停，便于观察，点“继续”启动模拟。
- 深蓝星空背景、居中导航、浅青选中态、右侧资料卡、八颗行星的图像导航。
- 地球采用 NASA 全球贴图、独立云层、蓝色大气边缘和海面高光；月球使用 NASA LROC 贴图。
- 其他七颗行星使用 Solar System Scope 的 CC BY 4.0 纹理，署名、许可和处理说明位于应用“资料与说明”及 `docs/ASSET_CREDITS.md`。
- 点击行星缩略图切换近景；拖动旋转、双指缩放、暂停/继续、速度选择、轨道开关、返回全景。
- 保留昼夜与公转实验、大小与距离比较、离线学习记录。点左上角品牌可返回原“出发”页。
- 横屏为左右布局；竖屏为上下布局与四列行星栏，可滚动。16:9 平板横屏保持完整首屏。

## 安装

`builds/android/solar-system-explorer-v0.3.0-debug.apk` 为 ARM64 调试安装包。最低 Android API 24，需要 OpenGL ES 3.0。开发包名与签名延续 v0.2.0，可覆盖安装保留学习记录。

构建：`./tools/build_android.sh`。
校验：`python3 tools/verify_android.py builds/android/solar-system-explorer-v0.3.0-debug.apk`。
渲染检查：`/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/run_tests.gd --log-file work/visual-tests.log -- --visual`。
重新生成缩略图：运行 `tools/bake_thumbnails.gd`，随后在 Godot 编辑器重新导入资源。

## 模型边界

概念图是视觉参考；运行中的球体、日照和轨道由真实 3D 场景渲染，界面控件可操作。不是把概念图作为背景。

地球云层是历史合成图，不是实时天气；大气、高光和海洋色彩为简化视觉表达。行星贴图存在艺术增强、补绘与色彩调整。土星环为程序化示意，未做颗粒物理或真实环影。

轨道保持固定椭圆、共面、任意初始相位；尺寸和间距经过调整。自转和公转仍采用原数据周期，没有实时星历、真实轴倾角、四季、月相或日月食模型。近景选择从明亮侧建立初始相机视角，日照方向始终指向场景中的太阳。

## 验证与限制

桌面 Godot Compatibility 渲染检查及回归测试覆盖：8 颗行星数据、24 项轨道检查、损坏存储恢复、页面切换、暂停与时间保留、实验答题、行星按钮、云层/大气、轨道开关、相机拖动与双指输入事件、16:10/16:9/竖屏布局。触摸测试为事件注入，不能替代真机验收。

Android 包结构、版本、启动入口、ARM64、离线资源与签名结果见 `docs/BUILD_VERIFICATION_V0.3.0.json`。

没有连接安卓平板，尚未验证真机触控、GPU 兼容性、持续运行帧率和温升。iOS 未配置签名或构建。此版本为开发验收包，不是商店正式发布版。
