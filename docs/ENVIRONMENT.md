# 开发环境与验证记录

检查日期：2026-10-07。

## 已检测到

- Godot：`4.6.3.stable.official.7d41c59c4`。
- 可执行文件：`/Applications/Godot.app/Contents/MacOS/Godot`。
- 对应导出模板目录：`~/Library/Application Support/Godot/export_templates/4.6.3.stable` 存在。
- Android SDK：`~/Library/Android/sdk` 下存在 platform-tools、platforms/android-35 和 build-tools/35.0.1。
- Xcode 应用目录：`/Applications/Xcode.app/Contents/Developer` 存在。
- 当前 `xcode-select -p` 返回 `/Library/Developer/CommandLineTools`。

目录存在不等于完整工具链已通过：JDK、NDK、CMake、SDK 许可、Godot 编辑器路径配置、签名和实际导出仍在 M1 验证。
未修改现有 SDK、全局 Godot 编辑器配置或 Xcode 选择。

## 本轮验证

1. 工程可导入，三份 GDScript 无解析错误。
2. 桌面 Compatibility 渲染器成功启动并绘制主场景。
3. 主场景实例化、暂停不推进时间、地球示意轨道半径、月球相对地球轨道、场景复位、相机复位均通过检查。
4. 桌面截图已检查：中文标题与提示可读，三个天体和底部控件可见。

验证环境：macOS、Apple M5、Godot Compatibility（OpenGL API 4.1 Metal）。
这不是移动设备性能测试。触屏、多指手势、后台行为、Android 返回键、手机安全区、两端安装包仍未通过真机验收。

## 后续工具链动作

- Android：按 Godot 4.6 官方要求核对 JDK / SDK / NDK / CMake，并完成调试 APK 导出。
- iPad：使用进程级 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 选择工具链，完成许可和签名检查；不必先修改全局 `xcode-select`。
- iOS Team ID 和开发签名待可用团队配置。不要把证书密码或私钥提交到项目。
- 未发布应用、未生成正式签名包，预设包名仍是占位值。

## 2026-10-08 增量验证

JDK 17、Android SDK、Godot 模板已完成实际 APK 导出链路；使用非 Gradle 模板导出，因此未更改现有 NDK / CMake。
已启用 ETC2 / ASTC 资源导入，并显式设置应用列表启动入口。
Android ARM64 调试 APK 已构建；包内容、启动入口和签名通过校验。
ADB 检查未发现已连接的授权设备，真机安装及性能未验收。
通过进程级 DEVELOPER_DIR 确认 Xcode 27.0 可用，未修改全局 xcode-select；iOS 签名和构建未完成。
此更新取代上文关于“尚未生成 Android 安装包”的早期状态。


## 2026-10-08 v0.3.0

已完成概念图视觉改版、图形回归测试与 Android v0.3.0 导出。APK 44,918,926 字节，包校验报告见 BUILD_VERIFICATION_V0.3.0.json。Godot 图形验证日志为 work/visual-final.stdout；Android 真机和 iOS 签名仍未验收。
