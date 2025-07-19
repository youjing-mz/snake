## A*寻路算法实现
## 为贪吃蛇AI提供智能路径寻找功能
## 作者：课程示例
## 创建时间：2025-01-16

class_name PathFinder
extends Node

# A*节点类
class AStarNode:
	var position: Vector2
	var g_cost: float = 0.0  # 从起点到当前点的实际距离
	var h_cost: float = 0.0  # 当前点到终点的估计距离
	var f_cost: float = 0.0  # 总评分 = g_cost + h_cost
	var parent: AStarNode = null
	
	func _init(pos: Vector2):
		position = pos
		calculate_f_cost()
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

# 搜索参数
const MAX_SEARCH_ITERATIONS: int = 1000  # 防止无限循环
const DIAGONAL_COST: float = 1.414  # sqrt(2)
const STRAIGHT_COST: float = 1.0

# 方向向量（上下左右）
const DIRECTIONS: Array[Vector2] = [
	Vector2.UP,
	Vector2.DOWN, 
	Vector2.LEFT,
	Vector2.RIGHT
]

## 使用A*算法寻找从起点到目标的路径
func find_path(start: Vector2, goal: Vector2, game_state: Dictionary) -> Array[Vector2]:
	var open_list: Array[AStarNode] = []
	var closed_list: Array[AStarNode] = []
	var open_positions: Dictionary = {}  # 位置到节点的快速查找
	var closed_positions: Dictionary = {}
	
	# 创建起始节点
	var start_node = AStarNode.new(start)
	start_node.g_cost = 0
	start_node.h_cost = calculate_heuristic(start, goal)
	start_node.calculate_f_cost()
	
	open_list.append(start_node)
	open_positions[start] = start_node
	
	var iterations = 0
	
	while open_list.size() > 0 and iterations < MAX_SEARCH_ITERATIONS:
		iterations += 1
		
		# 找到F值最小的节点
		var current_node = _get_lowest_f_cost_node(open_list)
		
		# 从开放列表移除，加入关闭列表
		open_list.erase(current_node)
		open_positions.erase(current_node.position)
		closed_list.append(current_node)
		closed_positions[current_node.position] = current_node
		
		# 检查是否到达目标
		if current_node.position == goal:
			return _reconstruct_path(current_node)
		
		# 探索相邻节点
		for direction in DIRECTIONS:
			var neighbor_pos = current_node.position + direction
			
			# 检查是否在关闭列表中
			if closed_positions.has(neighbor_pos):
				continue
			
			# 检查是否是有效位置
			if not _is_walkable(neighbor_pos, game_state):
				continue
			
			# 计算移动成本
			var movement_cost = STRAIGHT_COST
			var tentative_g_cost = current_node.g_cost + movement_cost
			
			# 检查是否在开放列表中
			var neighbor_node: AStarNode = null
			if open_positions.has(neighbor_pos):
				neighbor_node = open_positions[neighbor_pos]
				# 如果新路径更短，更新节点
				if tentative_g_cost < neighbor_node.g_cost:
					neighbor_node.g_cost = tentative_g_cost
					neighbor_node.parent = current_node
					neighbor_node.calculate_f_cost()
			else:
				# 创建新节点加入开放列表
				neighbor_node = AStarNode.new(neighbor_pos)
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.h_cost = calculate_heuristic(neighbor_pos, goal)
				neighbor_node.parent = current_node
				neighbor_node.calculate_f_cost()
				
				open_list.append(neighbor_node)
				open_positions[neighbor_pos] = neighbor_node
	
	# 没有找到路径
	print("PathFinder: No path found from ", start, " to ", goal, " (iterations: ", iterations, ")")
	return []

## 计算启发式距离（曼哈顿距离）
func calculate_heuristic(from: Vector2, to: Vector2) -> float:
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	return dx + dy

## 获取指定位置的有效邻居
func get_neighbors(position: Vector2, game_state: Dictionary) -> Array[Vector2]:
	var neighbors: Array[Vector2] = []
	
	for direction in DIRECTIONS:
		var neighbor_pos = position + direction
		if _is_walkable(neighbor_pos, game_state):
			neighbors.append(neighbor_pos)
	
	return neighbors

## 寻找安全方向（当无法到达目标时的备选策略）
func find_safe_direction(from: Vector2, game_state: Dictionary) -> Vector2:
	var safe_directions: Array[Vector2] = []
	
	# 检查所有方向的安全性
	for direction in DIRECTIONS:
		var test_pos = from + direction
		if _is_walkable(test_pos, game_state):
			# 进一步检查该方向是否会导致死路
			var future_neighbors = get_neighbors(test_pos, game_state)
			if future_neighbors.size() > 1:  # 至少有一个逃生路线
				safe_directions.append(direction)
	
	# 如果有安全方向，选择最好的
	if safe_directions.size() > 0:
		# 优先选择远离边界的方向
		var grid_width = game_state.get("grid_width", 40)
		var grid_height = game_state.get("grid_height", 30)
		var center = Vector2(grid_width / 2, grid_height / 2)
		
		var best_direction = safe_directions[0]
		var best_distance = -1.0
		
		for direction in safe_directions:
			var target_pos = from + direction
			var distance_to_center = target_pos.distance_to(center)
			if distance_to_center > best_distance:
				best_distance = distance_to_center
				best_direction = direction
		
		return best_direction
	
	# 如果没有安全方向，返回任意可行方向
	for direction in DIRECTIONS:
		var test_pos = from + direction
		if _is_walkable(test_pos, game_state):
			return direction
	
	# 完全没有可行方向
	return Vector2.ZERO

## 获取F值最小的节点
func _get_lowest_f_cost_node(open_list: Array[AStarNode]) -> AStarNode:
	var lowest_node = open_list[0]
	
	for node in open_list:
		if node.f_cost < lowest_node.f_cost:
			lowest_node = node
		elif node.f_cost == lowest_node.f_cost and node.h_cost < lowest_node.h_cost:
			# F值相同时，选择H值更小的（更接近目标）
			lowest_node = node
	
	return lowest_node

## 重构路径
func _reconstruct_path(end_node: AStarNode) -> Array[Vector2]:
	var path: Array[Vector2] = []
	var current_node = end_node
	
	while current_node != null:
		path.append(current_node.position)
		current_node = current_node.parent
	
	# 反转路径（从起点到终点）
	path.reverse()
	
	# 移除起点（因为我们从起点开始）
	if path.size() > 1:
		path.remove_at(0)
	
	return path

## 检查位置是否可行走
func _is_walkable(position: Vector2, game_state: Dictionary) -> bool:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	# 检查边界
	if position.x < 0 or position.x >= grid_width or position.y < 0 or position.y >= grid_height:
		return false
	
	# 检查蛇身（排除尾部，因为蛇移动时尾部会离开）
	var snake_body = game_state.get("snake_body", [])
	if snake_body.size() > 0:
		# 排除蛇的尾部，因为蛇移动时尾部会离开当前位置
		var body_without_tail = snake_body.slice(0, -1)
		if position in body_without_tail:
			return false
	
	return true

## 计算路径长度
func calculate_path_length(path: Array[Vector2]) -> float:
	if path.size() < 2:
		return 0.0
	
	var length = 0.0
	for i in range(path.size() - 1):
		length += path[i].distance_to(path[i + 1])
	
	return length

## 获取到目标的下一个方向
func get_next_direction_to_target(from: Vector2, to: Vector2, game_state: Dictionary) -> Vector2:
	# 首先尝试直接寻路
	var path = find_path(from, to, game_state)
	
	if path.size() > 0:
		# 返回路径的第一步方向
		var next_pos = path[0]
		var direction = next_pos - from
		print("PathFinder: Found path to food, next direction: ", direction)
		return direction
	
	# 如果找不到路径，使用简单的方向引导
	return _get_simple_direction_to_target(from, to, game_state)

## 简单的方向引导（当A*失败时使用）
func _get_simple_direction_to_target(from: Vector2, to: Vector2, game_state: Dictionary) -> Vector2:
	var dx = to.x - from.x
	var dy = to.y - from.y
	
	# 优先选择距离较大的方向
	var possible_directions: Array[Vector2] = []
	
	if abs(dx) > abs(dy):
		# 水平距离更大，优先水平移动
		if dx > 0:
			possible_directions.append(Vector2.RIGHT)
		else:
			possible_directions.append(Vector2.LEFT)
		
		# 然后尝试垂直移动
		if dy > 0:
			possible_directions.append(Vector2.DOWN)
		elif dy < 0:
			possible_directions.append(Vector2.UP)
	else:
		# 垂直距离更大，优先垂直移动
		if dy > 0:
			possible_directions.append(Vector2.DOWN)
		else:
			possible_directions.append(Vector2.UP)
		
		# 然后尝试水平移动
		if dx > 0:
			possible_directions.append(Vector2.RIGHT)
		elif dx < 0:
			possible_directions.append(Vector2.LEFT)
	
	# 检查哪个方向是可行的
	for direction in possible_directions:
		var test_pos = from + direction
		if _is_walkable(test_pos, game_state):
			print("PathFinder: Using simple direction to food: ", direction)
			return direction
	
	# 如果所有方向都不可行，寻找安全方向
	print("PathFinder: No direct path to food, using safe direction")
	return find_safe_direction(from, game_state)

## 检查位置是否可行走（增强版）
func _is_walkable_enhanced(position: Vector2, game_state: Dictionary) -> bool:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	# 检查边界
	if position.x < 0 or position.x >= grid_width or position.y < 0 or position.y >= grid_height:
		return false
	
	# 检查蛇身（排除尾部，因为蛇移动时尾部会离开）
	var snake_body = game_state.get("snake_body", [])
	if snake_body.size() > 0:
		# 排除蛇的尾部，因为蛇移动时尾部会离开当前位置
		var body_without_tail = snake_body.slice(0, -1)
		if position in body_without_tail:
			return false
	
	# 额外检查：确保这个位置不会立即导致死路
	var neighbors = get_neighbors(position, game_state)
	if neighbors.size() <= 1:  # 如果只有一个或没有邻居，可能是死路
		return false
	
	return true

## 优化路径（移除不必要的节点）
func optimize_path(path: Array[Vector2], game_state: Dictionary) -> Array[Vector2]:
	if path.size() <= 2:
		return path
	
	var optimized: Array[Vector2] = [path[0]]
	var i = 0
	
	while i < path.size() - 1:
		var j = path.size() - 1
		var found_shortcut = false
		
		# 从终点向回找，看能否直接到达
		while j > i + 1:
			if _has_clear_line_of_sight(path[i], path[j], game_state):
				optimized.append(path[j])
				i = j
				found_shortcut = true
				break
			j -= 1
		
		if not found_shortcut:
			i += 1
			if i < path.size():
				optimized.append(path[i])
	
	return optimized

## 检查两点间是否有清晰的视线（无障碍物）
func _has_clear_line_of_sight(from: Vector2, to: Vector2, game_state: Dictionary) -> bool:
	# 简化版本：只检查直线路径（水平或垂直）
	if from.x != to.x and from.y != to.y:
		return false  # 不是直线
	
	var step = Vector2.ZERO
	if from.x != to.x:
		step.x = 1 if to.x > from.x else -1
	else:
		step.y = 1 if to.y > from.y else -1
	
	var current = from + step
	while current != to:
		if not _is_walkable(current, game_state):
			return false
		current += step
	
	return true 