# v0.7.0 · 科普内容与学习流程

## 新增功能
- 八颗行星的离线知识卡：核心特征，以及可展开的内部结构、大气、卫星内容。探索资料卡进入，提供与地球比较及 NASA 原文入口。
- 比较页新增恒星自转和恒星公转周期。采用地球日作为统一单位，线性条形展示时长、显示 B/A 比值；逆行取周期绝对值作图并单独标注方向。恒星自转周期不等同于两次日出间隔。
- 两条任务：认识岩石行星、寻找巨行星。探索对应四颗行星、查看指定比较后开放答题；答对记录完成并展示回顾。之前的探索记录也计入任务。
- 独立进度页：行星、实验、任务状态与继续入口。任务与比较记录持久保存在本机；旧版记录自动补充新字段。
- 重置需要应用内确认，取消或返回不修改记录。确认清除探索、实验、任务及比较记录，保留画质设置。

## 验证
桌面图形回归通过：原有探索、相机、实验和画质流程，八卡字段完整性、周期单位与逆行时长、一键比较、两条任务全流程、错误答案、前置条件、持久保存、确认与取消重置。增加旧版记录兼容测试。
已查看知识卡展开、自转比较、任务完成及手机进度页面实际截图。Android 调试包资源、版本和签名验证见 BUILD_VERIFICATION_V0.7.0.json。
安卓平板真机验收仍按用户要求暂缓；未验证真实设备触控、帧率及系统浏览器跳转。iOS 未构建签名。

## 内容来源
核对日期：2026-10-08。周期数值沿用项目 JPL 物理参数表（data/planets.json），新文案为简要中文转述。巨行星卫星数持续变化，本版采用代表性卫星说明，不维护总数。
- 水星：https://science.nasa.gov/mercury/facts/
- 金星：https://science.nasa.gov/venus/venus-facts/
- 地球：https://science.nasa.gov/earth/facts/
- 火星：https://science.nasa.gov/mars/facts/
- 木星：https://science.nasa.gov/jupiter/jupiter-facts/
- 土星：https://science.nasa.gov/saturn/facts/
- 天王星：https://science.nasa.gov/uranus/facts/
- 海王星：https://science.nasa.gov/neptune/neptune-facts/
- 行星分类：https://science.nasa.gov/solar-system/planets/
