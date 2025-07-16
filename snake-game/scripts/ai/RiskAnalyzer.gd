## 风险评估系统
## 为贪吃蛇AI提供安全性分析和风险评估功能
## 作者：课程示例
## 创建时间：2025-01-16

class_name RiskAnalyzer
extends Node

# 风险评估参数
var risk_tolerance: float = 0.5  # 风险容忍度（0-1）

# 安全距离阈值
const MIN_SAFE_DISTANCE_TO_WALL: int = 2
const MIN_SAFE_DISTANCE_TO_BODY: int = 1
const MIN_ESCAPE_ROUTES: int = 2

# 评分权重
const BORDER_WEIGHT: float = 0.3
const BODY_WEIGHT: float = 0.4
const ESCAPE_WEIGHT: float = 0.3

## 检查位置是否安全
func is_position_safe(position: Vector2, game_state: Dictionary) -> bool:
	var safety_score = calculate_safety_score(position, game_state)
	return safety_score >= risk_tolerance

## 计算位置的安全评分（0-1，1为最安全）
func calculate_safety_score(position: Vector2, game_state: Dictionary) -> float:
	# 边界安全性
	var border_safety = calculate_border_safety(position, game_state)
	
	# 蛇身安全性
	var body_safety = calculate_body_safety(position, game_state)
	
	# 逃生路线安全性
	var escape_routes = count_escape_routes(position, game_state)
	var escape_safety = min(1.0, float(escape_routes) / float(MIN_ESCAPE_ROUTES))
	
	# 综合评分
	var total_score = (
		border_safety * BORDER_WEIGHT +
		body_safety * BODY_WEIGHT +
		escape_safety * ESCAPE_WEIGHT
	)
	
	return clamp(total_score, 0.0, 1.0)

## 计算边界安全性
func calculate_border_safety(position: Vector2, game_state: Dictionary) -> float:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	# 计算到各边界的距离
	var distance_to_left = position.x
	var distance_to_right = grid_width - 1 - position.x
	var distance_to_top = position.y
	var distance_to_bottom = grid_height - 1 - position.y
	
	# 找到最近的边界距离
	var min_distance = min(
		min(distance_to_left, distance_to_right),
		min(distance_to_top, distance_to_bottom)
	)
	
	# 转换为安全评分
	if min_distance >= MIN_SAFE_DISTANCE_TO_WALL:
		return 1.0
	else:
		return float(min_distance) / float(MIN_SAFE_DISTANCE_TO_WALL)

## 计算蛇身安全性
func calculate_body_safety(position: Vector2, game_state: Dictionary) -> float:
	var snake_body = game_state.get("snake_body", [])
	
	if snake_body.is_empty():
		return 1.0
	
	# 找到最近的蛇身部分
	var min_distance = INF
	for body_part in snake_body:
		var distance = position.distance_to(body_part)
		min_distance = min(min_distance, distance)
	
	# 转换为安全评分
	if min_distance >= MIN_SAFE_DISTANCE_TO_BODY:
		return 1.0
	else:
		return min_distance / float(MIN_SAFE_DISTANCE_TO_BODY)

## 计算逃生路线数量
func count_escape_routes(position: Vector2, game_state: Dictionary) -> int:
	var escape_routes = 0
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		var test_pos = position + direction
		if _is_walkable(test_pos, game_state):
			# 检查该方向是否有足够的空间
			if _has_sufficient_space(test_pos, direction, game_state):
				escape_routes += 1
	
	return escape_routes

## 检测死路（递归搜索）
func detect_dead_end(position: Vector2, game_state: Dictionary, max_depth: int = 10) -> bool:
	return _detect_dead_end_recursive(position, game_state, max_depth, {})

## 递归检测死路
func _detect_dead_end_recursive(position: Vector2, game_state: Dictionary, depth: int, visited: Dictionary) -> bool:
	if depth <= 0:
		return false  # 搜索深度已到，假设不是死路
	
	# 标记当前位置为已访问
	visited[position] = true
	
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var valid_moves = 0
	
	for direction in directions:
		var next_pos = position + direction
		
		# 跳过已访问的位置
		if visited.has(next_pos):
			continue
		
		# 检查是否可行走
		if _is_walkable(next_pos, game_state):
			valid_moves += 1
			
			# 递归检查该方向
			if not _detect_dead_end_recursive(next_pos, game_state, depth - 1, visited.duplicate()):
				# 找到了出路
				return false
	
	# 如果没有有效移动或所有方向都是死路
	return valid_moves == 0

## 预测未来风险（模拟N步后的状态）
func predict_future_risk(position: Vector2, direction: Vector2, game_state: Dictionary, steps: int = 3) -> float:
	var future_state = game_state.duplicate()
	var current_pos = position
	var total_risk = 0.0
	
	for step in range(steps):
		current_pos += direction
		
		# 检查是否仍然可行走
		if not _is_walkable(current_pos, future_state):
			return 1.0  # 最高风险
		
		# 计算当前步的风险
		var step_risk = 1.0 - calculate_safety_score(current_pos, future_state)
		total_risk += step_risk
		
		# 更新未来状态（模拟蛇身移动）
		_update_future_state(future_state, current_pos)
	
	return total_risk / float(steps)

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

## 检查方向是否有足够空间
func _has_sufficient_space(position: Vector2, direction: Vector2, game_state: Dictionary, min_space: int = 3) -> bool:
	var current_pos = position
	var space_count = 0
	
	for i in range(min_space):
		current_pos += direction
		if _is_walkable(current_pos, game_state):
			space_count += 1
		else:
			break
	
	return space_count >= min_space

## 更新未来状态（简化版本）
func _update_future_state(future_state: Dictionary, new_head_pos: Vector2) -> void:
	var snake_body = future_state.get("snake_body", [])
	
	if snake_body.size() > 0:
		# 移除尾部
		snake_body.pop_back()
		# 添加新头部
		snake_body.insert(0, new_head_pos)
		future_state["snake_body"] = snake_body

## 分析周围环境的整体安全性
func analyze_surrounding_safety(position: Vector2, game_state: Dictionary, radius: int = 3) -> Dictionary:
	var analysis = {
		"safe_positions": 0,
		"dangerous_positions": 0,
		"total_positions": 0,
		"average_safety": 0.0,
		"escape_routes": []
	}
	
	var total_safety = 0.0
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	# 检查周围区域
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var check_pos = position + Vector2(x, y)
			analysis.total_positions += 1
			
			if _is_walkable(check_pos, game_state):
				var safety = calculate_safety_score(check_pos, game_state)
				total_safety += safety
				
				if safety >= 0.7:  # 相对安全的阈值
					analysis.safe_positions += 1
				elif safety <= 0.3:  # 危险的阈值
					analysis.dangerous_positions += 1
	
	# 计算平均安全性
	if analysis.total_positions > 0:
		analysis.average_safety = total_safety / analysis.total_positions
	
	# 查找逃生路线
	for direction in directions:
		var escape_pos = position + direction
		if _is_walkable(escape_pos, game_state):
			var escape_safety = calculate_safety_score(escape_pos, game_state)
			analysis.escape_routes.append({
				"direction": direction,
				"safety": escape_safety,
				"position": escape_pos
			})
	
	# 按安全性排序逃生路线
	analysis.escape_routes.sort_custom(func(a, b): return a.safety > b.safety)
	
	return analysis

## 设置风险容忍度
func set_risk_tolerance(tolerance: float) -> void:
	risk_tolerance = clamp(tolerance, 0.0, 1.0)
	print("RiskAnalyzer: Risk tolerance set to ", risk_tolerance)

## 获取当前风险容忍度
func get_risk_tolerance() -> float:
	return risk_tolerance

## 判断是否应该采取保守策略
func should_play_conservatively(position: Vector2, game_state: Dictionary) -> bool:
	var safety_score = calculate_safety_score(position, game_state)
	var escape_routes = count_escape_routes(position, game_state)
	
	# 如果安全评分低或逃生路线少，采取保守策略
	return safety_score < 0.5 or escape_routes < 2

## 获取最安全的相邻位置
func get_safest_neighbor(position: Vector2, game_state: Dictionary) -> Vector2:
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var best_pos = position
	var best_safety = -1.0
	
	for direction in directions:
		var neighbor = position + direction
		if _is_walkable(neighbor, game_state):
			var safety = calculate_safety_score(neighbor, game_state)
			if safety > best_safety:
				best_safety = safety
				best_pos = neighbor
	
	return best_pos 