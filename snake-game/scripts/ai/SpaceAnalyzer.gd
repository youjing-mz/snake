## 空间分析系统
## 为贪吃蛇AI提供空间利用率分析和连通性检测功能
## 作者：课程示例
## 创建时间：2025-01-16

class_name SpaceAnalyzer
extends Node

# 空间分析参数
const FLOOD_FILL_MAX_ITERATIONS: int = 2000  # 防止无限循环
const MIN_VIABLE_SPACE: int = 10  # 最小可行空间大小

## 计算位置的空间评分（0-1，1为空间最大）
func calculate_space_score(position: Vector2, game_state: Dictionary) -> float:
	var available_space = calculate_available_space(position, game_state)
	var total_space = _get_total_game_area(game_state)
	
	if total_space <= 0:
		return 0.0
	
	# 将可用空间转换为评分
	var space_ratio = float(available_space) / float(total_space)
	return clamp(space_ratio, 0.0, 1.0)

## 计算从给定位置可达的空间大小
func calculate_available_space(start_position: Vector2, game_state: Dictionary) -> int:
	if not _is_walkable(start_position, game_state):
		return 0
	
	var visited: Dictionary = {}
	var space_count = 0
	var to_visit: Array[Vector2] = [start_position]
	var iterations = 0
	
	while to_visit.size() > 0 and iterations < FLOOD_FILL_MAX_ITERATIONS:
		iterations += 1
		var current = to_visit.pop_back()
		
		# 跳过已访问的位置
		if visited.has(current):
			continue
		
		# 标记为已访问
		visited[current] = true
		space_count += 1
		
		# 检查相邻位置
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for direction in directions:
			var neighbor = current + direction
			if not visited.has(neighbor) and _is_walkable(neighbor, game_state):
				to_visit.append(neighbor)
	
	return space_count

## 分析空间分布情况
func analyze_space_distribution(game_state: Dictionary) -> Dictionary:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	var visited: Dictionary = {}
	var spaces: Array[Dictionary] = []
	
	# 遍历所有位置，找到连通区域
	for x in range(grid_width):
		for y in range(grid_height):
			var position = Vector2(x, y)
			
			if not visited.has(position) and _is_walkable(position, game_state):
				var space_info = _analyze_connected_space(position, game_state, visited)
				if space_info.size > 0:
					spaces.append(space_info)
	
	# 按大小排序
	spaces.sort_custom(func(a, b): return a.size > b.size)
	
	# 计算统计信息
	var total_free_space = 0
	for space in spaces:
		total_free_space += space.size
	
	return {
		"spaces": spaces,
		"largest_space": spaces[0] if spaces.size() > 0 else null,
		"total_spaces": spaces.size(),
		"total_free_space": total_free_space,
		"average_space_size": float(total_free_space) / float(max(1, spaces.size())),
		"fragmentation_ratio": float(spaces.size()) / float(max(1, total_free_space))
	}

## 找到最大的连通空间
func find_largest_connected_space(game_state: Dictionary) -> int:
	var distribution = analyze_space_distribution(game_state)
	var largest_space = distribution.get("largest_space")
	
	if largest_space != null:
		return largest_space.size
	return 0

## 检查位置是否可达
func is_position_accessible(position: Vector2, game_state: Dictionary) -> bool:
	if not _is_walkable(position, game_state):
		return false
	
	# 检查是否有相邻的可行走位置
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for direction in directions:
		var neighbor = position + direction
		if _is_walkable(neighbor, game_state):
			return true
	
	return false

## 计算空间的紧凑度（空间是否紧凑连接）
func calculate_space_compactness(start_position: Vector2, game_state: Dictionary) -> float:
	var available_positions = _get_connected_positions(start_position, game_state)
	
	if available_positions.size() <= 1:
		return 1.0
	
	# 计算所有位置的重心
	var center_x = 0.0
	var center_y = 0.0
	for pos in available_positions:
		center_x += pos.x
		center_y += pos.y
	
	center_x /= available_positions.size()
	center_y /= available_positions.size()
	var center = Vector2(center_x, center_y)
	
	# 计算到重心的平均距离
	var total_distance = 0.0
	for pos in available_positions:
		total_distance += pos.distance_to(center)
	
	var average_distance = total_distance / available_positions.size()
	
	# 理论上最紧凑的配置是正方形，计算理论最小距离
	var theoretical_radius = sqrt(available_positions.size()) / 2.0
	
	# 紧凑度 = 理论最小距离 / 实际平均距离
	if average_distance > 0:
		return clamp(theoretical_radius / average_distance, 0.0, 1.0)
	else:
		return 1.0

## 评估空间利用效率
func evaluate_space_efficiency(game_state: Dictionary) -> Dictionary:
	var snake_body = game_state.get("snake_body", [])
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	var total_area = grid_width * grid_height
	var occupied_area = snake_body.size()
	var free_area = total_area - occupied_area
	
	var distribution = analyze_space_distribution(game_state)
	var largest_space = distribution.get("largest_space", {"size": 0})
	
	return {
		"total_area": total_area,
		"occupied_area": occupied_area,
		"free_area": free_area,
		"utilization_ratio": float(occupied_area) / float(total_area),
		"largest_free_space": largest_space.size,
		"space_fragmentation": distribution.fragmentation_ratio,
		"efficiency_score": _calculate_efficiency_score(distribution)
	}

## 找到最佳的移动方向（基于空间考虑）
func find_best_direction_for_space(position: Vector2, game_state: Dictionary) -> Vector2:
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var best_direction = Vector2.ZERO
	var best_score = -1.0
	
	for direction in directions:
		var test_pos = position + direction
		if _is_walkable(test_pos, game_state):
			var space_score = calculate_space_score(test_pos, game_state)
			if space_score > best_score:
				best_score = space_score
				best_direction = direction
	
	return best_direction

## 检查是否会创建孤立区域
func would_create_isolated_area(from_position: Vector2, to_position: Vector2, game_state: Dictionary) -> bool:
	# 创建临时状态，模拟移动
	var temp_state = game_state.duplicate()
	var snake_body = temp_state.get("snake_body", [])
	
	# 模拟移动（添加新头部，移除尾部）
	if snake_body.size() > 0:
		snake_body.insert(0, to_position)
		snake_body.pop_back()
		temp_state["snake_body"] = snake_body
	
	# 分析新状态下的空间分布
	var distribution = analyze_space_distribution(temp_state)
	var spaces = distribution.get("spaces", [])
	
	# 检查是否有小的孤立区域
	for space in spaces:
		if space.size < MIN_VIABLE_SPACE and space.size > 0:
			return true
	
	return false

## 获取总游戏区域
func _get_total_game_area(game_state: Dictionary) -> int:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	return grid_width * grid_height

## 检查位置是否可行走
func _is_walkable(position: Vector2, game_state: Dictionary) -> bool:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	# 检查边界
	if position.x < 0 or position.x >= grid_width or position.y < 0 or position.y >= grid_height:
		return false
	
	# 检查蛇身
	var snake_body = game_state.get("snake_body", [])
	if position in snake_body:
		return false
	
	return true

## 分析连通空间
func _analyze_connected_space(start_position: Vector2, game_state: Dictionary, visited: Dictionary) -> Dictionary:
	var positions: Array[Vector2] = []
	var to_visit: Array[Vector2] = [start_position]
	var iterations = 0
	
	var min_x = start_position.x
	var max_x = start_position.x
	var min_y = start_position.y
	var max_y = start_position.y
	
	while to_visit.size() > 0 and iterations < FLOOD_FILL_MAX_ITERATIONS:
		iterations += 1
		var current = to_visit.pop_back()
		
		if visited.has(current):
			continue
		
		visited[current] = true
		positions.append(current)
		
		# 更新边界
		min_x = min(min_x, current.x)
		max_x = max(max_x, current.x)
		min_y = min(min_y, current.y)
		max_y = max(max_y, current.y)
		
		# 检查相邻位置
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for direction in directions:
			var neighbor = current + direction
			if not visited.has(neighbor) and _is_walkable(neighbor, game_state):
				to_visit.append(neighbor)
	
	return {
		"positions": positions,
		"size": positions.size(),
		"bounds": {
			"min_x": min_x,
			"max_x": max_x,
			"min_y": min_y,
			"max_y": max_y,
			"width": max_x - min_x + 1,
			"height": max_y - min_y + 1
		},
		"center": Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
	}

## 获取连通位置列表
func _get_connected_positions(start_position: Vector2, game_state: Dictionary) -> Array[Vector2]:
	var visited: Dictionary = {}
	var positions: Array[Vector2] = []
	var to_visit: Array[Vector2] = [start_position]
	var iterations = 0
	
	while to_visit.size() > 0 and iterations < FLOOD_FILL_MAX_ITERATIONS:
		iterations += 1
		var current = to_visit.pop_back()
		
		if visited.has(current):
			continue
		
		visited[current] = true
		positions.append(current)
		
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for direction in directions:
			var neighbor = current + direction
			if not visited.has(neighbor) and _is_walkable(neighbor, game_state):
				to_visit.append(neighbor)
	
	return positions

## 计算效率评分
func _calculate_efficiency_score(distribution: Dictionary) -> float:
	var total_spaces = distribution.get("total_spaces", 1)
	var total_free_space = distribution.get("total_free_space", 0)
	var fragmentation = distribution.get("fragmentation_ratio", 1.0)
	
	if total_free_space <= 0:
		return 0.0
	
	# 效率评分考虑空间大小和碎片化程度
	var size_score = min(1.0, float(total_free_space) / 100.0)  # 标准化到100个单位
	var fragment_score = 1.0 - min(1.0, fragmentation)  # 碎片化越少越好
	
	return (size_score + fragment_score) / 2.0 