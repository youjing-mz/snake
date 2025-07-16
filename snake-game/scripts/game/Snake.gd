## 蛇类
## 负责蛇的移动、增长和渲染逻辑
## 作者：课程示例
## 创建时间：2025-01-16

class_name Snake
extends Node2D

# 蛇相关信号
signal food_eaten(food_value: int)
signal wall_hit
signal self_hit
signal direction_changed(new_direction: Vector2)

# 使用CollisionDetector的碰撞类型枚举

# 蛇身数据
var body: Array[Vector2] = []
var direction: Vector2 = Vector2.RIGHT
var next_direction: Vector2 = Vector2.RIGHT
var is_growing: bool = false
var is_alive: bool = true
var move_interval: float = 0.2

# 渲染相关
var segment_nodes: Array[Node2D] = []
var head_node: Node2D

# 初始位置和长度
const INITIAL_LENGTH: int = 3
const INITIAL_POSITION: Vector2 = Vector2(10, 15)

func _ready() -> void:
	# 初始化蛇身
	_initialize_snake()
	
	# 创建渲染节点
	_create_visual_nodes()
	
	print("Snake initialized")

## 初始化蛇身
func _initialize_snake() -> void:
	body.clear()
	
	# 创建初始蛇身（从头到尾）
	for i in range(INITIAL_LENGTH):
		body.append(INITIAL_POSITION - Vector2(i, 0))
	
	# 设置初始方向
	direction = Vector2.RIGHT
	next_direction = Vector2.RIGHT
	is_growing = false
	is_alive = true

## 创建视觉节点
func _create_visual_nodes() -> void:
	# 清除现有节点
	_clear_visual_nodes()
	
	# 为每个身体段创建节点
	for i in range(body.size()):
		var segment = _create_segment_node(i == 0)
		segment_nodes.append(segment)
		add_child(segment)
	
	# 设置头部节点引用
	if segment_nodes.size() > 0:
		head_node = segment_nodes[0]
	
	# 更新显示位置
	_update_visual_positions()

## 创建身体段节点
func _create_segment_node(is_head: bool = false) -> Node2D:
	var segment = Node2D.new()
	
	if is_head:
		# 创建头部（三角形）
		var head_shape = Polygon2D.new()
		var size = GameSizes.SNAKE_SEGMENT_SIZE
		var points = PackedVector2Array([
			Vector2(size * 0.8, 0),
			Vector2(-size * 0.2, -size * 0.4),
			Vector2(-size * 0.2, size * 0.4)
		])
		head_shape.polygon = points
		head_shape.color = GameColors.SNAKE_HEAD_COLOR
		segment.add_child(head_shape)
		
		# 添加眼睛
		_add_eyes_to_head(segment)
	else:
		# 创建身体（圆角矩形）
		var body_shape = ColorRect.new()
		var size = GameSizes.SNAKE_SEGMENT_SIZE
		body_shape.size = Vector2(size * 0.9, size * 0.9)
		body_shape.position = Vector2(-size * 0.45, -size * 0.45)
		body_shape.color = GameColors.SNAKE_BODY_COLOR
		segment.add_child(body_shape)
	
	return segment

## 为头部添加眼睛
func _add_eyes_to_head(head_segment: Node2D) -> void:
	var eye_size = 3
	var eye_offset = GameSizes.SNAKE_SEGMENT_SIZE * 0.2
	
	# 左眼
	var left_eye = ColorRect.new()
	left_eye.size = Vector2(eye_size, eye_size)
	left_eye.position = Vector2(eye_offset, -eye_offset)
	left_eye.color = GameColors.WHITE
	head_segment.add_child(left_eye)
	
	# 右眼
	var right_eye = ColorRect.new()
	right_eye.size = Vector2(eye_size, eye_size)
	right_eye.position = Vector2(eye_offset, eye_offset - eye_size)
	right_eye.color = GameColors.WHITE
	head_segment.add_child(right_eye)

## 清除视觉节点
func _clear_visual_nodes() -> void:
	for segment in segment_nodes:
		if segment:
			segment.queue_free()
	segment_nodes.clear()
	head_node = null

## 设置移动方向
func set_direction(new_direction: Vector2) -> void:
	# 防止反向移动
	if new_direction == -direction:
		return
	
	# 防止重复设置相同方向
	if new_direction == next_direction:
		return
	
	next_direction = new_direction
	direction_changed.emit(new_direction)

## 改变方向（设计文档接口）
func change_direction(new_direction: Vector2) -> void:
	set_direction(new_direction)

## 移动蛇
func move() -> void:
	if not is_alive:
		return
	
	# 更新方向
	direction = next_direction
	
	# 计算新的头部位置
	var new_head_pos = body[0] + direction
	
	# 添加新头部
	body.insert(0, new_head_pos)
	
	# 如果不在增长，移除尾部
	if not is_growing:
		body.pop_back()
	else:
		is_growing = false
		# 增长时需要添加新的视觉节点
		_add_segment_node()
	
	# 更新视觉显示
	_update_visual_positions()
	
	# 更新头部朝向
	_update_head_rotation()

## 增长蛇身
func grow() -> void:
	is_growing = true
	print("Snake growing, new length will be: ", body.size() + 1)

## 添加身体段节点
func _add_segment_node() -> void:
	var new_segment = _create_segment_node(false)
	segment_nodes.append(new_segment)
	add_child(new_segment)

## 更新视觉位置
func _update_visual_positions() -> void:
	for i in range(min(body.size(), segment_nodes.size())):
		if segment_nodes[i]:
			# 转换网格坐标到像素坐标
			var pixel_pos = _grid_to_pixel(body[i])
			segment_nodes[i].position = pixel_pos

## 更新头部旋转
func _update_head_rotation() -> void:
	if head_node:
		# 根据移动方向旋转头部
		var angle = direction.angle()
		head_node.rotation = angle

## 网格坐标转像素坐标
func _grid_to_pixel(grid_pos: Vector2) -> Vector2:
	return grid_pos * Constants.GRID_SIZE + Vector2(Constants.GRID_SIZE / 2, Constants.GRID_SIZE / 2)

## 检查自身碰撞
func check_self_collision() -> bool:
	if body.size() < 4:  # 长度小于4不可能自撞
		return false
	
	var head_pos = body[0]
	# 检查头部是否与身体其他部分重叠（跳过前3段避免误判）
	for i in range(3, body.size()):
		if head_pos == body[i]:
			return true
	return false

## 检查碰撞（设计文档接口）
func check_collision(head_pos: Vector2) -> CollisionDetector.CollisionType:
	# 获取当前网格尺寸
	var grid_size = Constants.get_current_grid_size()
	# 使用CollisionDetector进行检测
	return CollisionDetector.detect_collision(
		head_pos, body, Vector2(-1, -1), false, grid_size.x, grid_size.y
	)

## 设置移动速度
func set_move_speed(speed: float) -> void:
	move_interval = speed

## 获取头部位置
func get_head_position() -> Vector2:
	if body.size() > 0:
		return body[0]
	return Vector2.ZERO

## 获取身体所有位置
func get_body_positions() -> Array[Vector2]:
	return body.duplicate()

## 获取蛇身长度
func get_length() -> int:
	return body.size()

## 检查位置是否被蛇身占据
func is_position_occupied(pos: Vector2) -> bool:
	return pos in body

## 更新显示（外部调用）
func update_display() -> void:
	_update_visual_positions()

## 重置蛇到初始状态
func reset() -> void:
	_initialize_snake()
	_create_visual_nodes()
	print("Snake reset to initial state")

## 杀死蛇
func kill() -> void:
	is_alive = false
	print("Snake died")
	
	# 可以添加死亡动画效果
	_play_death_animation()

## 播放死亡动画（公开接口）
func play_death_animation() -> void:
	_play_death_animation()

## 播放死亡动画
func _play_death_animation() -> void:
	# 简单的闪烁效果
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(self, "modulate:a", 0.3, 0.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

## 检查蛇是否存活
func is_snake_alive() -> bool:
	return is_alive

## 获取当前移动方向
func get_direction() -> Vector2:
	return direction

## 获取下一个移动方向
func get_next_direction() -> Vector2:
	return next_direction

## 设置暂停状态
func set_paused(paused: bool) -> void:
	# 暂停时可以停止动画或其他效果
	# 目前蛇的移动由GameManager的计时器控制，所以这里主要是预留接口
	pass
