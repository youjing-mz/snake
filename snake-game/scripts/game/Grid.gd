## 网格类
## 负责游戏网格的渲染和管理
## 作者：课程示例
## 创建时间：2025-01-16

class_name Grid
extends Node2D

# 网格属性
var grid_width: int = Constants.GRID_WIDTH
var grid_height: int = Constants.GRID_HEIGHT
var cell_size: int = Constants.GRID_SIZE

# 渲染相关
var background_rect: ColorRect
var grid_lines: Node2D
var border_lines: Node2D

# 网格样式
var show_grid_lines: bool = true
var show_border: bool = true
var grid_line_width: float = 1.0
var border_width: float = GameSizes.BORDER_WIDTH

func _ready() -> void:
	# 创建背景
	_create_background()
	
	# 创建网格线
	if show_grid_lines:
		_create_grid_lines()
	
	# 创建边框
	if show_border:
		_create_border()
	
	print("Grid initialized with size: ", grid_width, "x", grid_height)

## 创建背景
func _create_background() -> void:
	background_rect = ColorRect.new()
	background_rect.size = Vector2(grid_width * cell_size, grid_height * cell_size)
	background_rect.color = GameColors.BACKGROUND_DARK
	background_rect.position = Vector2.ZERO
	add_child(background_rect)

## 创建网格线
func _create_grid_lines() -> void:
	grid_lines = Node2D.new()
	add_child(grid_lines)
	
	# 垂直线
	for x in range(grid_width + 1):
		var line = Line2D.new()
		var x_pos = x * cell_size
		line.add_point(Vector2(x_pos, 0))
		line.add_point(Vector2(x_pos, grid_height * cell_size))
		line.width = grid_line_width
		line.default_color = GameColors.GRID_LINE_COLOR
		line.default_color.a = 0.3  # 半透明
		grid_lines.add_child(line)
	
	# 水平线
	for y in range(grid_height + 1):
		var line = Line2D.new()
		var y_pos = y * cell_size
		line.add_point(Vector2(0, y_pos))
		line.add_point(Vector2(grid_width * cell_size, y_pos))
		line.width = grid_line_width
		line.default_color = GameColors.GRID_LINE_COLOR
		line.default_color.a = 0.3  # 半透明
		grid_lines.add_child(line)

## 创建边框
func _create_border() -> void:
	border_lines = Node2D.new()
	add_child(border_lines)
	
	var total_width = grid_width * cell_size
	var total_height = grid_height * cell_size
	
	# 上边框
	var top_border = Line2D.new()
	top_border.add_point(Vector2(0, 0))
	top_border.add_point(Vector2(total_width, 0))
	top_border.width = border_width
	top_border.default_color = GameColors.WHITE
	border_lines.add_child(top_border)
	
	# 下边框
	var bottom_border = Line2D.new()
	bottom_border.add_point(Vector2(0, total_height))
	bottom_border.add_point(Vector2(total_width, total_height))
	bottom_border.width = border_width
	bottom_border.default_color = GameColors.WHITE
	border_lines.add_child(bottom_border)
	
	# 左边框
	var left_border = Line2D.new()
	left_border.add_point(Vector2(0, 0))
	left_border.add_point(Vector2(0, total_height))
	left_border.width = border_width
	left_border.default_color = GameColors.WHITE
	border_lines.add_child(left_border)
	
	# 右边框
	var right_border = Line2D.new()
	right_border.add_point(Vector2(total_width, 0))
	right_border.add_point(Vector2(total_width, total_height))
	right_border.width = border_width
	right_border.default_color = GameColors.WHITE
	border_lines.add_child(right_border)

## 网格坐标转世界坐标
func grid_to_world(grid_pos: Vector2) -> Vector2:
	return grid_pos * cell_size + Vector2(cell_size / 2, cell_size / 2)

## 世界坐标转网格坐标
func world_to_grid(world_pos: Vector2) -> Vector2:
	return Vector2(int(world_pos.x / cell_size), int(world_pos.y / cell_size))

## 检查网格坐标是否有效
func is_valid_grid_position(grid_pos: Vector2) -> bool:
	return (grid_pos.x >= 0 and grid_pos.x < grid_width and 
			grid_pos.y >= 0 and grid_pos.y < grid_height)

## 获取网格边界
func get_grid_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(grid_width, grid_height))

## 获取网格中心位置
func get_grid_center() -> Vector2:
	return Vector2(grid_width / 2.0, grid_height / 2.0)

## 获取随机网格位置
func get_random_grid_position() -> Vector2:
	return Vector2(randi() % grid_width, randi() % grid_height)

## 获取网格总大小（像素）
func get_total_size() -> Vector2:
	return Vector2(grid_width * cell_size, grid_height * cell_size)

## 设置网格线可见性
func set_grid_lines_visible(visible: bool) -> void:
	show_grid_lines = visible
	if grid_lines:
		grid_lines.visible = visible

## 设置边框可见性
func set_border_visible(visible: bool) -> void:
	show_border = visible
	if border_lines:
		border_lines.visible = visible

## 高亮网格单元格
func highlight_cell(grid_pos: Vector2, color: Color = GameColors.ACCENT_BLUE, duration: float = 0.5) -> void:
	if not is_valid_grid_position(grid_pos):
		return
	
	# 创建高亮矩形
	var highlight = ColorRect.new()
	highlight.size = Vector2(cell_size, cell_size)
	highlight.position = grid_pos * cell_size
	highlight.color = color
	highlight.color.a = 0.5  # 半透明
	add_child(highlight)
	
	# 动画效果
	var tween = create_tween()
	tween.tween_property(highlight, "color:a", 0.0, duration)
	tween.tween_callback(highlight.queue_free)

## 在网格上绘制路径
func draw_path(path: Array[Vector2], color: Color = GameColors.ACCENT_BLUE, width: float = 2.0) -> void:
	if path.size() < 2:
		return
	
	# 创建路径线
	var path_line = Line2D.new()
	path_line.width = width
	path_line.default_color = color
	
	# 添加路径点
	for grid_pos in path:
		var world_pos = grid_to_world(grid_pos)
		path_line.add_point(world_pos)
	
	add_child(path_line)
	
	# 自动移除路径（可选）
	var tween = create_tween()
	tween.tween_delay(2.0)
	tween.tween_callback(path_line.queue_free)

## 清除所有高亮和路径
func clear_highlights() -> void:
	# 移除所有临时添加的高亮和路径
	for child in get_children():
		if child is ColorRect and child != background_rect:
			child.queue_free()
		elif child is Line2D and child.get_parent() == self:
			# 只移除直接添加到Grid的Line2D，保留网格线和边框
			if child.get_parent() != grid_lines and child.get_parent() != border_lines:
				child.queue_free()

## 获取网格信息
func get_grid_info() -> Dictionary:
	return {
		"width": grid_width,
		"height": grid_height,
		"cell_size": cell_size,
		"total_cells": grid_width * grid_height,
		"pixel_width": grid_width * cell_size,
		"pixel_height": grid_height * cell_size
	}

## 调整网格大小
func resize_grid(new_width: int, new_height: int) -> void:
	grid_width = new_width
	grid_height = new_height
	
	# 重新创建网格
	_recreate_grid()
	
	print("Grid resized to: ", grid_width, "x", grid_height)

## 重新创建网格
func _recreate_grid() -> void:
	# 清除现有元素
	for child in get_children():
		child.queue_free()
	
	# 等待一帧后重新创建
	await get_tree().process_frame
	
	# 重新创建所有元素
	_create_background()
	if show_grid_lines:
		_create_grid_lines()
	if show_border:
		_create_border()

## 设置背景颜色
func set_background_color(color: Color) -> void:
	if background_rect:
		background_rect.color = color

## 设置网格线颜色
func set_grid_line_color(color: Color) -> void:
	if grid_lines:
		for child in grid_lines.get_children():
			if child is Line2D:
				child.default_color = color

## 设置边框颜色
func set_border_color(color: Color) -> void:
	if border_lines:
		for child in border_lines.get_children():
			if child is Line2D:
				child.default_color = color