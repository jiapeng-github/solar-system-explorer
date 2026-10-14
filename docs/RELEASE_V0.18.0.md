# v0.18.0 · 圆角青蓝 Logo

使用内置 image_gen 重设计与界面一致的青蓝色行星轨道标志，替换原有金色高光方案。

- 桌面/传统启动图标使用深蓝圆角底板，透明外边距；可见轮廓宽度为 1024 画布中的 832 像素，避免旧版满幅方形显得过大。
- 顶部品牌使用无底板透明标志；Android 自适应图标使用独立透明前景与深蓝背景，最终外形由设备启动器遮罩决定。
- 保留“出发”作为默认启动页。
- 图标源文件：assets/ui/app-logo-v3-master.png、assets/ui/brand-mark-v3-master.png；打包资源由 tools/prepare_logo.gd 做尺寸与安全边距处理，保留透明通道。
- 提示词：docs/design/app-logo-v3-prompt.txt。

验证：图标透明角与可见轮廓尺寸检查、首页实际渲染及横竖屏布局检查；APK 版本/资源/签名验证。桌面 Dock 和不同 Android 启动器的最终显示仍以实际设备为准。
