## 游戏常量定义
## 包含所有游戏中使用的常量值
## 作者：课程示例
## 创建时间：2025-01-16

extends Node

# 网格配置
const GRID_SIZE: int = 20
const GRID_WIDTH: int = 40
const GRID_HEIGHT: int = 30

# 游戏配置
const BASE_MOVE_SPEED: float = 5.0
const MAX_MOVE_SPEED: float = 15.0
const FOOD_SCORE: int = 10

# 文件路径
const SAVE_FILE_PATH: String = "user://save_game.dat"

# 游戏区域配置
const GAME_WIDTH: int = GRID_WIDTH * GRID_SIZE
const GAME_HEIGHT: int = GRID_HEIGHT * GRID_SIZE

# 速度递增配置
const SPEED_INCREASE_RATE: float = 0.5
const SPEED_INCREASE_INTERVAL: int = 5  # 每吃5个食物增加速度