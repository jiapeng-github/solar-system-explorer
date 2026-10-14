# v0.17.0 · 出发页启动与新应用图标

- App 启动直接显示“出发”，通过首页主按钮进入太阳系探索。
- 使用内置 image_gen 重新设计金色太阳、蓝色轨道与行星组成的图标；原始素材保存在 assets/ui/app-logo-v2.png，提示词记录在 docs/design/app-logo-v2-prompt.txt。
- 替换项目应用图标、所有页面顶部品牌图标、Android 传统启动图标和自适应前景/背景。自适应资源增加安全边距以适应启动器裁切。
- 首页与全应用回归测试覆盖默认启动页、主按钮进入探索、品牌图标引用和已有功能。

Android 0.17.0 / versionCode 23。APK 校验见 BUILD_VERIFICATION_V0.17.0.json。桌面 Godot 验证通过；安卓启动器实际显示和真机性能待设备验收。
