extends RefCounted
class_name DeadlockDetector

## 死锁检测器 - 识别和预防AI陷入死锁状态

# 检测参数
const POSITION_HISTORY_SIZE = 20
const DIRECTION_HISTORY_SIZE = 10
const DEADLOCK_THRESHOLD = 0.8
const LOOP_DETECTION_THRESHOLD = 3

# 历史数据
var position_history: Array[Vector2] = []
var direction_history: Array[Vector2] = []
var decision_pattern_history: Array[String] = []

# 死锁状态追踪
var potential_deadlock_count = 0
var last_deadlock_warning_time = 0.0
var deadlock_warning_cooldown = 5.0  # 秒

# 空间分析缓存
var space_analysis_cache: Dictionary = {}
var cache_expiry_time = 2.0  # 秒

## 检测是否存在死锁风险
func detect_deadlock_risk(current_position: Vector2, game_state: Dictionary) -> Dictionary:
	_update_position_history(current_position)
	
	var deadlock_analysis = {
		"risk_level": 0.0,
		"deadlock_type": "none",
		"escape_suggestions": [],
		"confidence": 0.0,
		"details": {}
	}
	
	# 1. 位置循环检测
	var position_loop_risk = _detect_position_loops()
	
	# 2. 空间收缩检测
	var space_shrinking_risk = _detect_space_shrinking(current_position, game_state)
	
	# 3. 方向模式分析
	var direction_pattern_risk = _detect_direction_patterns()
	
	# 4. 可达空间分析
	var reachable_space_risk = _analyze_reachable_space(current_position, game_state)
	
	# 5. 出口可用性检测
	var exit_availability_risk = _analyze_exit_availability(current_position, game_state)
	
	# 综合风险评估
	var total_risk = (
		position_loop_risk.risk * 0.25 +
		space_shrinking_risk.risk * 0.25 +
		direction_pattern_risk.risk * 0.2 +
		reachable_space_risk.risk * 0.2 +
		exit_availability_risk.risk * 0.1
	)
	
	deadlock_analysis.risk_level = total_risk
	deadlock_analysis.confidence = _calculate_detection_confidence()
	
	# 确定死锁类型
	if total_risk > DEADLOCK_THRESHOLD:
		deadlock_analysis.deadlock_type = _determine_deadlock_type([
			position_loop_risk, space_shrinking_risk, direction_pattern_risk,
			reachable_space_risk, exit_availability_risk
		])
		
		# 生成逃生建议
		deadlock_analysis.escape_suggestions = _generate_escape_suggestions(
			current_position, game_state, deadlock_analysis.deadlock_type
		)
	
	# 详细信息
	deadlock_analysis.details = {
		"position_loops": position_loop_risk,
		"space_shrinking": space_shrinking_risk,
		"direction_patterns": direction_pattern_risk,
		"reachable_space": reachable_space_risk,
		"exit_availability": exit_availability_risk
	}
	
	# 发出警告
	if total_risk > DEADLOCK_THRESHOLD:
		_trigger_deadlock_warning(deadlock_analysis)
	
	return deadlock_analysis

## 获取逃生路径
func get_escape_path(current_position: Vector2, game_state: Dictionary, deadlock_type: String) -> Array[Vector2]:
	match deadlock_type:
		"position_loop":
			return _find_loop_breaking_path(current_position, game_state)
		"space_trap":
			return _find_space_expansion_path(current_position, game_state)
		"direction_lock":
			return _find_direction_diversification_path(current_position, game_state)
		"reachability_loss":
			return _find_connectivity_restoration_path(current_position, game_state)
		_:
			return _find_general_escape_path(current_position, game_state)

## 预测未来死锁风险
func predict_future_deadlock(current_position: Vector2, planned_direction: Vector2, game_state: Dictionary, steps_ahead: int = 5) -> Dictionary:
	var prediction = {
		"risk_in_steps": [],
		"max_risk": 0.0,
		"critical_step": -1,
		"prevention_suggestions": []
	}
	
	# 模拟未来几步
	var simulated_position = current_position
	var simulated_game_state = game_state.duplicate(true)
	
	for step in range(steps_ahead):
		simulated_position += planned_direction
		
		# 更新模拟游戏状态
		_update_simulated_game_state(simulated_game_state, simulated_position)
		
		# 检测该步的死锁风险
		var step_risk = detect_deadlock_risk(simulated_position, simulated_game_state)
		prediction.risk_in_steps.append({
			"step": step + 1,
			"position": simulated_position,
			"risk_level": step_risk.risk_level,
			"deadlock_type": step_risk.deadlock_type
		})
		
		# 更新最大风险
		if step_risk.risk_level > prediction.max_risk:
			prediction.max_risk = step_risk.risk_level
			prediction.critical_step = step + 1
		
		# 如果风险过高，停止模拟
		if step_risk.risk_level > DEADLOCK_THRESHOLD:
			break
	
	# 生成预防建议
	if prediction.max_risk > 0.6:
		prediction.prevention_suggestions = _generate_prevention_suggestions(prediction)
	
	return prediction

## 私有方法

func _update_position_history(position: Vector2):
	position_history.append(position)
	if position_history.size() > POSITION_HISTORY_SIZE:
		position_history.pop_front()

func _update_direction_history(direction: Vector2):
	direction_history.append(direction)
	if direction_history.size() > DIRECTION_HISTORY_SIZE:
		direction_history.pop_front()

## 位置循环检测
func _detect_position_loops() -> Dictionary:
	if position_history.size() < 6:
		return {"risk": 0.0, "loop_length": 0, "repetitions": 0}
	
	var max_loop_risk = 0.0
	var best_loop_length = 0
	var max_repetitions = 0
	
	# 检测不同长度的循环
	for loop_length in range(2, min(8, position_history.size() / 2)):
		var repetitions = _count_position_loop_repetitions(loop_length)
		if repetitions >= LOOP_DETECTION_THRESHOLD:
			var risk = min(1.0, repetitions / 5.0)
			if risk > max_loop_risk:
				max_loop_risk = risk
				best_loop_length = loop_length
				max_repetitions = repetitions
	
	return {
		"risk": max_loop_risk,
		"loop_length": best_loop_length,
		"repetitions": max_repetitions
	}

func _count_position_loop_repetitions(loop_length: int) -> int:
	if position_history.size() < loop_length * 2:
		return 0
	
	var recent_positions = position_history.slice(-loop_length)
	var repetitions = 0
	var check_start = position_history.size() - loop_length * 2
	
	while check_start >= 0:
		var check_positions = position_history.slice(check_start, check_start + loop_length)
		if _positions_match(recent_positions, check_positions):
			repetitions += 1
			check_start -= loop_length
		else:
			break
	
	return repetitions

func _positions_match(positions1: Array, positions2: Array) -> bool:
	if positions1.size() != positions2.size():
		return false
	
	for i in range(positions1.size()):
		if positions1[i] != positions2[i]:
			return false
	
	return true

## 空间收缩检测
func _detect_space_shrinking(current_position: Vector2, game_state: Dictionary) -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0
	var cache_key = str(current_position)
	
	# 检查缓存
	if space_analysis_cache.has(cache_key):
		var cached_data = space_analysis_cache[cache_key]
		if current_time - cached_data.timestamp < cache_expiry_time:
			return cached_data.result
	
	# 计算当前可用空间
	var current_available_space = _calculate_available_space(current_position, game_state)
	
	# 与历史数据比较
	var space_trend = _analyze_space_trend(current_available_space)
	
	var result = {
		"risk": space_trend.shrinking_rate,
		"available_space": current_available_space,
		"space_trend": space_trend.trend,
		"shrinking_rate": space_trend.shrinking_rate
	}
	
	# 缓存结果
	space_analysis_cache[cache_key] = {
		"result": result,
		"timestamp": current_time
	}
	
	return result

func _calculate_available_space(position: Vector2, game_state: Dictionary) -> int:
	var visited = {}
	var queue = [position]
	var available_count = 0
	
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	var snake_body = game_state.get("snake_body", [])
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var key = str(current)
		
		if visited.has(key):
			continue
		
		visited[key] = true
		
		# 检查边界
		if current.x < 0 or current.x >= grid_width or current.y < 0 or current.y >= grid_height:
			continue
		
		# 检查蛇身
		if current in snake_body:
			continue
		
		available_count += 1
		
		# 添加邻居到队列
		for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var neighbor = current + direction
			var neighbor_key = str(neighbor)
			if not visited.has(neighbor_key):
				queue.append(neighbor)
		
		# 限制搜索范围，避免性能问题
		if available_count > 1000:
			break
	
	return available_count

func _analyze_space_trend(current_space: int) -> Dictionary:
	# 这里简化处理，实际实现可以维护历史空间数据
	return {
		"trend": "stable",
		"shrinking_rate": 0.0
	}

## 方向模式分析
func _detect_direction_patterns() -> Dictionary:
	if direction_history.size() < 4:
		return {"risk": 0.0, "pattern_type": "none", "rigidity": 0.0}
	
	# 分析方向多样性
	var direction_counts = {}
	for direction in direction_history:
		var key = str(direction)
		direction_counts[key] = direction_counts.get(key, 0) + 1
	
	# 计算方向偏好强度
	var total_directions = direction_history.size()
	var max_count = 0
	for count in direction_counts.values():
		max_count = max(max_count, count)
	
	var rigidity = float(max_count) / float(total_directions)
	
	# 检测重复模式
	var pattern_risk = _detect_repeating_direction_patterns()
	
	var final_risk = max(rigidity - 0.4, pattern_risk) # 正常情况下某个方向占40%以下是合理的
	
	return {
		"risk": final_risk,
		"pattern_type": "direction_bias" if rigidity > 0.6 else "pattern_repeat",
		"rigidity": rigidity
	}

func _detect_repeating_direction_patterns() -> float:
	# 检测简单的重复模式，如左右左右或上下上下
	if direction_history.size() < 4:
		return 0.0
	
	var recent_directions = direction_history.slice(-4)
	
	# 检测ABAB模式
	if recent_directions[0] == recent_directions[2] and recent_directions[1] == recent_directions[3] and recent_directions[0] != recent_directions[1]:
		return 0.7
	
	# 检测AAA模式
	var same_count = 1
	for i in range(1, recent_directions.size()):
		if recent_directions[i] == recent_directions[i-1]:
			same_count += 1
		else:
			break
	
	if same_count >= 3:
		return 0.5
	
	return 0.0

## 可达空间分析
func _analyze_reachable_space(current_position: Vector2, game_state: Dictionary) -> Dictionary:
	# 分析从当前位置能到达的关键区域
	var food_position = game_state.get("food_position", Vector2(-1, -1))
	var reachable_food = false
	var reachable_exits = 0
	
	if food_position.x >= 0:
		reachable_food = _is_position_reachable(current_position, food_position, game_state)
	
	# 检测到边界的可达性
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	var border_positions = [
		Vector2(0, grid_height / 2), Vector2(grid_width - 1, grid_height / 2),
		Vector2(grid_width / 2, 0), Vector2(grid_width / 2, grid_height - 1)
	]
	
	for border_pos in border_positions:
		if _is_position_reachable(current_position, border_pos, game_state):
			reachable_exits += 1
	
	var risk = 0.0
	if not reachable_food:
		risk += 0.5
	if reachable_exits == 0:
		risk += 0.5
	elif reachable_exits == 1:
		risk += 0.3
	
	return {
		"risk": risk,
		"reachable_food": reachable_food,
		"reachable_exits": reachable_exits
	}

func _is_position_reachable(from: Vector2, to: Vector2, game_state: Dictionary) -> bool:
	# 简化的可达性检测，使用BFS
	var visited = {}
	var queue = [from]
	var max_iterations = 1000
	var iterations = 0
	
	while queue.size() > 0 and iterations < max_iterations:
		iterations += 1
		var current = queue.pop_front()
		var key = str(current)
		
		if visited.has(key):
			continue
		
		visited[key] = true
		
		if current == to:
			return true
		
		# 添加邻居
		for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var neighbor = current + direction
			if _is_valid_position(neighbor, game_state) and not visited.has(str(neighbor)):
				queue.append(neighbor)
	
	return false

func _is_valid_position(position: Vector2, game_state: Dictionary) -> bool:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	var snake_body = game_state.get("snake_body", [])
	
	# 边界检查
	if position.x < 0 or position.x >= grid_width or position.y < 0 or position.y >= grid_height:
		return false
	
	# 蛇身检查
	return not (position in snake_body)

## 出口可用性分析
func _analyze_exit_availability(current_position: Vector2, game_state: Dictionary) -> Dictionary:
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var available_exits = 0
	var blocked_exits = 0
	
	for direction in directions:
		var test_position = current_position + direction
		if _is_valid_position(test_position, game_state):
			available_exits += 1
		else:
			blocked_exits += 1
	
	var risk = 0.0
	if available_exits == 0:
		risk = 1.0  # 完全被困
	elif available_exits == 1:
		risk = 0.7  # 只有一个出口，很危险
	elif available_exits == 2:
		risk = 0.3  # 两个出口，有些风险
	
	return {
		"risk": risk,
		"available_exits": available_exits,
		"blocked_exits": blocked_exits
	}

## 死锁类型确定
func _determine_deadlock_type(risk_analyses: Array) -> String:
	var max_risk = 0.0
	var deadlock_type = "none"
	
	var risk_types = ["position_loop", "space_trap", "direction_lock", "reachability_loss", "exit_block"]
	
	for i in range(risk_analyses.size()):
		if risk_analyses[i].risk > max_risk:
			max_risk = risk_analyses[i].risk
			deadlock_type = risk_types[i]
	
	return deadlock_type

## 逃生建议生成
func _generate_escape_suggestions(current_position: Vector2, game_state: Dictionary, deadlock_type: String) -> Array:
	var suggestions = []
	
	match deadlock_type:
		"position_loop":
			suggestions.append("尝试打破重复的移动模式")
			suggestions.append("选择与最近几步不同的方向")
			suggestions.append("暂时远离当前区域")
		
		"space_trap":
			suggestions.append("寻找通向更开阔区域的路径")
			suggestions.append("避免进入狭窄通道")
			suggestions.append("优先考虑空间扩展方向")
		
		"direction_lock":
			suggestions.append("增加移动方向的多样性")
			suggestions.append("避免连续使用相同方向")
			suggestions.append("考虑螺旋式移动模式")
		
		"reachability_loss":
			suggestions.append("重新建立与食物的连接")
			suggestions.append("寻找替代路径")
			suggestions.append("考虑迂回策略")
		
		"exit_block":
			suggestions.append("立即寻找最近的可用出口")
			suggestions.append("避免进入死胡同")
			suggestions.append("保持至少两个逃生方向")
	
	return suggestions

## 具体逃生路径查找
func _find_loop_breaking_path(current_position: Vector2, game_state: Dictionary) -> Array[Vector2]:
	# 找一条与最近路径不同的路径
	var avoid_positions = position_history.slice(-6) if position_history.size() >= 6 else []
	return _find_path_avoiding_positions(current_position, game_state, avoid_positions)

func _find_space_expansion_path(current_position: Vector2, game_state: Dictionary) -> Array[Vector2]:
	# 找一条通向更开阔空间的路径
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	var center = Vector2(grid_width / 2, grid_height / 2)
	
	# 朝向中心方向或远离边界的方向
	var target_direction = (center - current_position).normalized()
	var suggested_direction = _round_to_direction(target_direction)
	
	return [current_position + suggested_direction]

func _find_direction_diversification_path(current_position: Vector2, game_state: Dictionary) -> Array[Vector2]:
	# 选择最近最少使用的方向
	var direction_counts = {}
	for direction in direction_history:
		var key = str(direction)
		direction_counts[key] = direction_counts.get(key, 0) + 1
	
	var all_directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var best_direction = all_directions[0]
	var min_count = direction_counts.get(str(best_direction), 0)
	
	for direction in all_directions:
		var count = direction_counts.get(str(direction), 0)
		if count < min_count and _is_valid_position(current_position + direction, game_state):
			min_count = count
			best_direction = direction
	
	return [current_position + best_direction]

func _find_connectivity_restoration_path(current_position: Vector2, game_state: Dictionary) -> Array[Vector2]:
	# 寻找恢复连通性的路径
	var food_position = game_state.get("food_position", Vector2(-1, -1))
	if food_position.x >= 0:
		return _find_path_to_target(current_position, food_position, game_state)
	
	return _find_general_escape_path(current_position, game_state)

func _find_general_escape_path(current_position: Vector2, game_state: Dictionary) -> Array[Vector2]:
	# 通用逃生路径：朝向最安全的方向
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var best_direction = Vector2.ZERO
	var best_safety = -1.0
	
	for direction in directions:
		var test_position = current_position + direction
		if _is_valid_position(test_position, game_state):
			var safety = _evaluate_position_safety(test_position, game_state)
			if safety > best_safety:
				best_safety = safety
				best_direction = direction
	
	if best_direction != Vector2.ZERO:
		return [current_position + best_direction]
	
	return []

## 辅助方法
func _round_to_direction(vector: Vector2) -> Vector2:
	if abs(vector.x) > abs(vector.y):
		return Vector2.RIGHT if vector.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if vector.y > 0 else Vector2.UP

func _find_path_avoiding_positions(current_position: Vector2, game_state: Dictionary, avoid_positions: Array) -> Array[Vector2]:
	# 简化实现：选择不在避免列表中的方向
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		var test_position = current_position + direction
		if _is_valid_position(test_position, game_state) and not (test_position in avoid_positions):
			return [test_position]
	
	# 如果都在避免列表中，选择最安全的
	return _find_general_escape_path(current_position, game_state)

func _find_path_to_target(from: Vector2, to: Vector2, game_state: Dictionary) -> Array[Vector2]:
	# 简化的A*路径查找
	var direction = (to - from).normalized()
	var suggested_direction = _round_to_direction(direction)
	
	if _is_valid_position(from + suggested_direction, game_state):
		return [from + suggested_direction]
	
	return []

func _evaluate_position_safety(position: Vector2, game_state: Dictionary) -> float:
	var safety = 1.0
	
	# 边界距离
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	var border_distance = min(
		position.x, grid_width - 1 - position.x,
		position.y, grid_height - 1 - position.y
	)
	
	safety *= min(1.0, border_distance / 3.0)  # 距离边界至少3格比较安全
	
	# 周围空间
	var available_neighbors = 0
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if _is_valid_position(position + direction, game_state):
			available_neighbors += 1
	
	safety *= available_neighbors / 4.0
	
	return safety

func _calculate_detection_confidence() -> float:
	# 基于历史数据量计算检测置信度
	var position_confidence = min(1.0, position_history.size() / float(POSITION_HISTORY_SIZE))
	var direction_confidence = min(1.0, direction_history.size() / float(DIRECTION_HISTORY_SIZE))
	
	return (position_confidence + direction_confidence) / 2.0

func _trigger_deadlock_warning(analysis: Dictionary):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_deadlock_warning_time > deadlock_warning_cooldown:
		print("DeadlockDetector: 检测到死锁风险 - 类型: %s, 风险等级: %.2f" % [analysis.deadlock_type, analysis.risk_level])
		last_deadlock_warning_time = current_time
		potential_deadlock_count += 1

## 预防建议生成
func _generate_prevention_suggestions(prediction: Dictionary) -> Array:
	var suggestions = []
	
	if prediction.critical_step <= 2:
		suggestions.append("立即改变当前方向")
		suggestions.append("寻找替代路径")
	elif prediction.critical_step <= 4:
		suggestions.append("提前规划避免策略")
		suggestions.append("考虑长期路径规划")
	
	suggestions.append("增加移动模式的随机性")
	suggestions.append("定期检查逃生路线")
	
	return suggestions

func _update_simulated_game_state(game_state: Dictionary, new_head_position: Vector2):
	# 更新模拟的游戏状态
	var snake_body = game_state.get("snake_body", [])
	
	# 添加新头部位置
	snake_body.push_front(new_head_position)
	
	# 移除尾部（假设没吃到食物）
	if snake_body.size() > 1:
		snake_body.pop_back()
	
	game_state["snake_body"] = snake_body
	game_state["snake_head"] = new_head_position

## 重置检测器状态
func reset():
	position_history.clear()
	direction_history.clear()
	decision_pattern_history.clear()
	potential_deadlock_count = 0
	space_analysis_cache.clear() 