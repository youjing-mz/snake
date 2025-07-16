## 游戏颜色常量定义
## 定义游戏中使用的所有颜色
## 作者：课程示例
## 创建时间：2025-01-16

extends Node

# 主色调
const PRIMARY_GREEN: Color = Color(0.153, 0.682, 0.376)  # #27AE60
const PRIMARY_DARK: Color = Color(0.173, 0.243, 0.314)   # #2C3E50
const ACCENT_RED: Color = Color(0.906, 0.298, 0.235)     # #E74C3C
const ACCENT_BLUE: Color = Color(0.204, 0.596, 0.859)    # #3498DB
const ACCENT_GREEN: Color = Color(0.247, 0.784, 0.620)    # #2ECC71

# 中性色
const WHITE: Color = Color(1.0, 1.0, 1.0)                # #FFFFFF
const LIGHT_GRAY: Color = Color(0.741, 0.765, 0.780)     # #BDC3C7
const DARK_GRAY: Color = Color(0.584, 0.647, 0.651)      # #95A5A6
const BACKGROUND_DARK: Color = Color(0.173, 0.243, 0.314) # #2C3E50

# 游戏元素颜色
const SNAKE_HEAD_COLOR: Color = PRIMARY_GREEN
const SNAKE_BODY_COLOR: Color = Color(0.153, 0.545, 0.345)  # PRIMARY_GREEN.lerp(PRIMARY_DARK, 0.3)
const FOOD_COLOR: Color = ACCENT_RED
const GRID_LINE_COLOR: Color = DARK_GRAY
const UI_TEXT_COLOR: Color = WHITE
const BUTTON_COLOR: Color = ACCENT_BLUE
const BUTTON_HOVER_COLOR: Color = Color(0.367, 0.717, 0.887)  # ACCENT_BLUE.lerp(WHITE, 0.2)
