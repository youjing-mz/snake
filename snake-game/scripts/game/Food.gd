## 食物类
## 负责食物的生成、渲染和管理
## 作者：课程示例
## 创建时间：2025-01-16

class_name Food
extends Node2D

# 食物相关信号
signal food_spawned(position: Vector2, value: int)
signal food_consumed(position: Vector2, value: int)

# 食物位置
var current_position: Vector2 = Vector2(-1, -1)
var active_state: bool = false

# 渲染节点
var food_visual: Node2D

# 食物类型（为后续扩展预留）
enum FoodType { NORMAL, BONUS, SPECIAL }
var food_type: FoodType = FoodType.NORMAL

# 食物值
var current_value: int = Constants.FOOD_SCORE

# 动画相关
var pulse_tween: Tween
var spawn_tween: Tween

func _ready() -> void:
	# 创建视觉节点
	_create_visual_node()
	
	# 初始化动画
	_setup_animations()
	
	print("Food initialized")

## 创建视觉节点
func _create_visual_node() -> void:
	food_visual = Node2D.new()
	add_child(food_visual)
	
	# 创建食物主体（圆形）
	var food_body = _create_food_shape()
	food_visual.add_child(food_body)
	
	# 添加装饰效果
	_add_food_decorations(food_visual)
	
	# 初始时隐藏
	food_visual.visible = false

## 创建食物形状
func _create_food_shape() -> Node2D:
	var shape_container = Node2D.new()
	
	# 主体圆形
	var main_circle = _create_circle(GameSizes.FOOD_SIZE, GameColors.FOOD_COLOR)
	shape_container.add_child(main_circle)
	
	# 高光效果
	var highlight = _create_circle(GameSizes.FOOD_SIZE * 0.4, GameColors.WHITE)
	highlight.position = Vector2(-GameSizes.FOOD_SIZE * 0.2, -GameSizes.FOOD_SIZE * 0.2)
	shape_container.add_child(highlight)
	
	return shape_container

## 创建圆形
func _create_circle(radius: float, color: Color) -> Polygon2D:
	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var segments = 16
	
	# 生成圆形顶点
	for i in range(segments):
		var angle = 2.0 * PI * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius * 0.5)
	
	circle.polygon = points
	circle.color = color
	return circle

## 添加食物装饰
func _add_food_decorations(parent: Node2D) -> void:
	# 添加小点装饰
	for i in range(3):
		var dot_color = Color(GameColors.WHITE.r * 0.5 + GameColors.FOOD_COLOR.r * 0.5, GameColors.WHITE.g * 0.5 + GameColors.FOOD_COLOR.g * 0.5, GameColors.WHITE.b * 0.5 + GameColors.FOOD_COLOR.b * 0.5)
		var dot = _create_circle(2, dot_color)
		var angle = 2.0 * PI * i / 3
		var offset = Vector2(cos(angle), sin(angle)) * GameSizes.FOOD_SIZE * 0.3
		dot.position = offset
		parent.add_child(dot)

## 设置动画
func _setup_animations() -> void:
	# 脉冲动画
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(food_visual, "scale", Vector2(1.1, 1.1), 0.8)
	pulse_tween.tween_property(food_visual, "scale", Vector2(1.0, 1.0), 0.8)
	pulse_tween.pause()

## 生成新食物
func spawn_new_food(occupied_positions: Array[Vector2]) -> void:
	spawn_food(occupied_positions)

## 生成食物（设计文档接口）
func spawn_food(occupied_positions: Array[Vector2]) -> void:
	print("Food spawn_food called")
	# 生成随机位置
	var new_position = _generate_random_position(occupied_positions)
	
	if new_position == Vector2(-1, -1):
		print("Warning: Cannot find valid position for food")
		return
	
	# 设置食物位置
	current_position = new_position
	active_state = true
	
	# 更新视觉位置
	_update_visual_position()
	
	# 显示食物
	food_visual.visible = true
	
	# 播放生成动画
	_play_spawn_animation()
	
	# 开始脉冲动画
	pulse_tween.play()
	
	# 发送信号
	food_spawned.emit(current_position, current_value)
	
	print("Food spawned at: ", current_position)
	print("Food visual visible: ", food_visual.visible)
	print("Food visual position: ", food_visual.position)

## 生成随机位置
func _generate_random_position(occupied_positions: Array[Vector2]) -> Vector2:
	var max_attempts = 100
	var attempts = 0
	
	while attempts < max_attempts:
		var grid_size = Constants.get_current_grid_size()
		var x = randi() % grid_size.x
		var y = randi() % grid_size.y
		var pos = Vector2(x, y)
		
		# 检查位置是否被占据
		if not pos in occupied_positions:
			return pos
		
		attempts += 1
	
	# 如果找不到位置，返回无效位置
	return Vector2(-1, -1)

## 更新视觉位置
func _update_visual_position() -> void:
	if food_visual:
		# 转换网格坐标到像素坐标
		var pixel_pos = _grid_to_pixel(current_position)
		food_visual.position = pixel_pos

## 网格坐标转像素坐标（备用方法）
func _grid_to_pixel(grid_pos: Vector2) -> Vector2:
	# 由于Food节点已经设置了position偏移，这里只需要计算相对坐标
	return grid_pos * Constants.GRID_SIZE + Vector2(Constants.GRID_SIZE / 2, Constants.GRID_SIZE / 2)

## 播放生成动画
func _play_spawn_animation() -> void:
	if spawn_tween:
		spawn_tween.kill()
	
	spawn_tween = create_tween()
	
	# 从小到大的缩放动画
	food_visual.scale = Vector2.ZERO
	spawn_tween.tween_property(food_visual, "scale", Vector2(1.2, 1.2), 0.2)
	spawn_tween.tween_property(food_visual, "scale", Vector2(1.0, 1.0), 0.1)

## 播放被吃动画
func _play_eaten_animation() -> void:
	if spawn_tween:
		spawn_tween.kill()
	
	spawn_tween = create_tween()
	
	# 缩放和旋转动画（食物已经被隐藏，这里只是视觉效果）
	spawn_tween.parallel().tween_property(food_visual, "scale", Vector2.ZERO, 0.2)
	spawn_tween.parallel().tween_property(food_visual, "rotation", PI * 2, 0.2)
	# 移除_hide_food回调，因为食物已经在consume_food中被隐藏

## 隐藏食物
func _hide_food() -> void:
	food_visual.visible = false
	active_state = false
	pulse_tween.pause()

## 食物被吃
func eat_food() -> int:
	return consume_food()

## 消费食物（设计文档接口）
func consume_food() -> int:
	if not active_state:
		return 0
	
	print("Food eaten at: ", current_position)
	
	# 立即隐藏食物，避免与新食物生成冲突
	_hide_food()
	
	# 播放被吃动画（在隐藏后播放，避免视觉冲突）
	_play_eaten_animation()
	
	# 发送信号
	food_consumed.emit(current_position, current_value)
	
	# 返回食物价值
	return current_value

## 获取当前位置（设计文档接口）
func get_current_position() -> Vector2:
	return current_position


## 检查是否激活（设计文档接口）
func is_active() -> bool:
	return active_state

## 检查碰撞（设计文档接口）
func check_collision(position_to_check: Vector2) -> bool:
	return active_state and position_to_check == current_position


## 获取当前价值（设计文档接口）
func get_current_value() -> int:
	return current_value

## 设置食物类型
func set_food_type(type: FoodType) -> void:
	food_type = type
	
	# 根据类型设置不同的属性
	match type:
		FoodType.NORMAL:
			current_value = Constants.FOOD_SCORE
			_update_food_appearance(GameColors.FOOD_COLOR)
		FoodType.BONUS:
			current_value = Constants.FOOD_SCORE * 2
			_update_food_appearance(GameColors.ACCENT_BLUE)
		FoodType.SPECIAL:
			current_value = Constants.FOOD_SCORE * 5
			_update_food_appearance(GameColors.PRIMARY_GREEN)

## 更新食物外观
func _update_food_appearance(color: Color) -> void:
	if food_visual and food_visual.get_child_count() > 0:
		var shape_container = food_visual.get_child(0)
		if shape_container.get_child_count() > 0:
			var main_circle = shape_container.get_child(0) as Polygon2D
			if main_circle:
				main_circle.color = color

## 更新显示（外部调用）
func update_display() -> void:
	_update_visual_position()

## 重置食物状态
func reset() -> void:
	active_state = false
	food_visual.visible = false
	pulse_tween.pause()
	
	if spawn_tween:
		spawn_tween.kill()
	
	print("Food reset")

## 设置暂停状态
func set_paused(paused: bool) -> void:
	if paused:
		if pulse_tween:
			pulse_tween.pause()
		if spawn_tween:
			spawn_tween.pause()
	else:
		if pulse_tween and active_state:
			pulse_tween.play()
		if spawn_tween:
			spawn_tween.play()

## 销毁食物
func destroy() -> void:
	reset()
	queue_free()
