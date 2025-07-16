## 碰撞检测器
## 静态工具类，负责各种碰撞检测逻辑
## 作者：课程示例
## 创建时间：2025-01-16

extends Node

# 碰撞类型枚举
enum CollisionType { NONE, WALL, SELF, FOOD }

## 检查墙壁碰撞
static func check_wall_collision(position: Vector2, grid_width: int, grid_height: int) -> bool:
	return (position.x < 0 or position.x >= grid_width or 
			position.y < 0 or position.y >= grid_height)

## 检查自身碰撞
static func check_self_collision(head_position: Vector2, body_positions: Array[Vector2]) -> bool:
	# 蛇身长度小于4时不可能自撞
	if body_positions.size() < 4:
		return false
	
	# 检查头部是否与身体其他部分重叠（跳过前3段避免误判）
	for i in range(3, body_positions.size()):
		if head_position == body_positions[i]:
			return true
	return false

## 检查食物碰撞
static func check_food_collision(position: Vector2, food_position: Vector2, food_active: bool) -> bool:
	if not food_active:
		return false
	return position == food_position

## 综合碰撞检测
static func detect_collision(head_position: Vector2, body_positions: Array[Vector2], 
							food_position: Vector2, food_active: bool, grid_width: int, grid_height: int) -> CollisionType:
	# 优先级：墙壁 > 自身 > 食物
	
	# 1. 检查墙壁碰撞（最高优先级）
	if check_wall_collision(head_position, grid_width, grid_height):
		return CollisionType.WALL
	
	# 2. 检查自身碰撞
	if check_self_collision(head_position, body_positions):
		return CollisionType.SELF
	
	# 3. 检查食物碰撞（最低优先级）
	if check_food_collision(head_position, food_position, food_active):
		return CollisionType.FOOD
	
	# 无碰撞
	return CollisionType.NONE

## 检查位置是否在网格范围内
static func is_position_in_bounds(position: Vector2, grid_width: int, grid_height: int) -> bool:
	return not check_wall_collision(position, grid_width, grid_height)

## 检查位置是否被占据
static func is_position_occupied(position: Vector2, occupied_positions: Array[Vector2]) -> bool:
	return position in occupied_positions

## 获取有效的相邻位置
static func get_valid_adjacent_positions(position: Vector2, grid_width: int, grid_height: int, 
											occupied_positions: Array[Vector2] = []) -> Array[Vector2]:
	var adjacent_positions: Array[Vector2] = []
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		var new_pos = position + direction
		if is_position_in_bounds(new_pos, grid_width, grid_height) and not is_position_occupied(new_pos, occupied_positions):
			adjacent_positions.append(new_pos)
	
	return adjacent_positions

## 计算两点之间的曼哈顿距离
static func manhattan_distance(pos1: Vector2, pos2: Vector2) -> int:
	return int(abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y))

## 计算两点之间的欧几里得距离
static func euclidean_distance(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_to(pos2)

## 检查路径是否有效（无碰撞）
static func is_path_valid(path: Array[Vector2], grid_width: int, grid_height: int, 
						 occupied_positions: Array[Vector2] = []) -> bool:
	for position in path:
		if not is_position_in_bounds(position, grid_width, grid_height):
			return false
		if is_position_occupied(position, occupied_positions):
			return false
	return true

## 获取所有空闲位置
static func get_free_positions(grid_width: int, grid_height: int, 
							  occupied_positions: Array[Vector2]) -> Array[Vector2]:
	var free_positions: Array[Vector2] = []
	
	for x in range(grid_width):
		for y in range(grid_height):
			var pos = Vector2(x, y)
			if not is_position_occupied(pos, occupied_positions):
				free_positions.append(pos)
	
	return free_positions

## 检查方向是否有效（不能反向）
static func is_direction_valid(current_direction: Vector2, new_direction: Vector2) -> bool:
	# 防止反向移动
	return new_direction != -current_direction and new_direction != Vector2.ZERO

## 获取方向向量
static func get_direction_vector(from_pos: Vector2, to_pos: Vector2) -> Vector2:
	var diff = to_pos - from_pos
	# 标准化为单位向量
	if abs(diff.x) > abs(diff.y):
		return Vector2(sign(diff.x), 0)
	else:
		return Vector2(0, sign(diff.y))

## 预测下一个位置
static func predict_next_position(current_position: Vector2, direction: Vector2) -> Vector2:
	return current_position + direction

## 检查区域是否安全（无碰撞风险）
static func is_area_safe(center_position: Vector2, radius: int, grid_width: int, grid_height: int, 
						 occupied_positions: Array[Vector2]) -> bool:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var check_pos = center_position + Vector2(x, y)
			if not is_position_in_bounds(check_pos, grid_width, grid_height):
				return false
			if is_position_occupied(check_pos, occupied_positions):
				return false
	return true

## 获取碰撞类型的字符串描述
static func get_collision_type_string(collision_type: CollisionType) -> String:
	match collision_type:
		CollisionType.NONE:
			return "无碰撞"
		CollisionType.WALL:
			return "墙壁碰撞"
		CollisionType.SELF:
			return "自身碰撞"
		CollisionType.FOOD:
			return "食物碰撞"
		_:
			return "未知碰撞"
