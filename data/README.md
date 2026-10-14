# 科学参数与展示参数

`planets.json` 中 `definitions` 统一说明单位、定义及来源，`reviewed_at` 记录校对日期。
`radius_km`、`period_years`、`rotation_days` 来自 JPL 物理参数表；`a_au`、`eccentricity` 来自 J2000 拟合参数初值。
`display_radius`、`display_a`、`phase` 仅用于展示；它们不替代科学数值。
实际模拟使用固定、共面椭圆与任意相位，不实现完整星历。
程序化纹理不是真实地表地图。月球约 27.3 天的简化周期参考 NASA Moon Facts。
