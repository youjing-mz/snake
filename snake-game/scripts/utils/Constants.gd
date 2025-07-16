## 游戏常量定义
## 包含所有游戏中使用的常量值
## 作者：课程示例
## 创建时间：2025-01-16

extends Node

# 网格配置
const GRID_SIZE: int = 20  # 每个网格单元的像素大小
const MIN_GRID_WIDTH: int = 40    # 最小网格宽度
const MIN_GRID_HEIGHT: int = 30   # 最小网格高度
const MAX_GRID_WIDTH: int = 60    # 最大网格宽度  
const MAX_GRID_HEIGHT: int = 45   # 最大网格高度

# 默认网格尺寸（用于备用）
const DEFAULT_GRID_WIDTH: int = 40
const DEFAULT_GRID_HEIGHT: int = 30

# 网格边距
const GRID_MARGIN: int = 50  # 网格周围的边距

# 游戏配置
const BASE_MOVE_SPEED: float = 5.0
const MAX_MOVE_SPEED: float = 15.0
const FOOD_SCORE: int = 10

# 文件路径
const SAVE_FILE_PATH: String = "user://save_game.dat"

# 速度递增配置
const SPEED_INCREASE_RATE: float = 0.5
const SPEED_INCREASE_INTERVAL: int = 5  # 每吃5个食物增加速度

## 根据窗口大小计算最佳网格尺寸
static func calculate_grid_size(window_size: Vector2) -> Vector2i:
	# 计算可用空间（减去边距和UI空间）
	var available_width = window_size.x - GRID_MARGIN * 2
	var available_height = window_size.y - GRID_MARGIN * 2 - 100  # 100px用于UI
	
	# 根据可用空间计算网格数量
	var grid_width = int(available_width / GRID_SIZE)
	var grid_height = int(available_height / GRID_SIZE)
	
	# 限制在最小和最大值之间
	grid_width = clamp(grid_width, MIN_GRID_WIDTH, MAX_GRID_WIDTH)
	grid_height = clamp(grid_height, MIN_GRID_HEIGHT, MAX_GRID_HEIGHT)
	
	return Vector2i(grid_width, grid_height)

## 获取当前游戏窗口的网格尺寸
static func get_current_grid_size() -> Vector2i:
	var window_size = DisplayServer.window_get_size()
	return calculate_grid_size(Vector2(window_size))

## 获取网格总像素尺寸
static func get_grid_pixel_size(grid_size: Vector2i) -> Vector2i:
	return Vector2i(grid_size.x * GRID_SIZE, grid_size.y * GRID_SIZE)

## 兼容性函数：获取网格宽度
static func get_grid_width() -> int:
	return get_current_grid_size().x

## 兼容性函数：获取网格高度  
static func get_grid_height() -> int:
	return get_current_grid_size().y

## 获取网格尺寸（返回Vector2格式，用于AI系统兼容性）
static func get_grid_size() -> Vector2:
	var size = get_current_grid_size()
	return Vector2(size.x, size.y)
