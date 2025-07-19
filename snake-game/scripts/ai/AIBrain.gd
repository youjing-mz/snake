## AI决策核心系统
## 整合各种AI算法，为贪吃蛇AI提供智能决策功能
## 作者：课程示例
## 创建时间：2025-01-16

class_name AIBrain
extends Node

# 信号定义
signal decision_made(direction: Vector2, reasoning: String)
signal thinking_started()
signal thinking_finished()

# 决策权重配置
var DECISION_WEIGHTS: Dictionary = {
	"safety": 1.0,          # 安全性权重
	"food_distance": 0.6,   # 食物距离权重
	"space_available": 0.4, # 空间可用性权重
	"future_safety": 0.8    # 未来安全性权重
}

# AI组件引用
var pathfinder: PathFinder
var risk_analyzer: RiskAnalyzer
var space_analyzer: SpaceAnalyzer

# AI参数
var risk_tolerance: float = 0.5      # 风险容忍度
var food_priority: float = 0.6       # 食物优先级
var look_ahead_steps: int = 3        # 前瞻步数
var decision_confidence: float = 0.0 # 决策置信度

# 决策历史
var recent_decisions: Array[Dictionary] = []
const MAX_DECISION_HISTORY: int = 10

# 位置历史（避免死循环）
var position_history: Array[Vector2] = []
const MAX_POSITION_HISTORY: int = 12  # 增加历史长度
var loop_detection_threshold: int = 2  # 降低阈值，更敏感地检测循环

# 反循环状态
var anti_loop_mode: bool = false
var anti_loop_steps_remaining: int = 0
const ANTI_LOOP_DURATION: int = 8  # 反循环模式持续8步

# 性能监控
var last_decision_time: float = 0.0
var total_decisions: int = 0
var successful_decisions: int = 0

# 调试信息存储
var last_decision_scores: Dictionary = {}
var last_evaluation_details: Dictionary = {}

func _ready() -> void:
	# 初始化AI组件
	_initialize_ai_components()
	print("AIBrain initialized")

## 初始化AI组件
func _initialize_ai_components() -> void:
	# 创建AI分析组件
	pathfinder = PathFinder.new()
	risk_analyzer = RiskAnalyzer.new()
	space_analyzer = SpaceAnalyzer.new()
	
	# 添加到节点树
	add_child(pathfinder)
	add_child(risk_analyzer)
	add_child(space_analyzer)
	
	# 配置组件参数
	risk_analyzer.set_risk_tolerance(risk_tolerance)

## 主要思考函数：分析游戏状态并返回最佳方向
func think(game_state: Dictionary) -> Vector2:
	thinking_started.emit()
	var start_time = Time.get_time_dict_from_system()
	
	# 获取当前位置和可能的方向
	var current_head = game_state.get("snake_head", Vector2.ZERO)
	var current_direction = game_state.get("current_direction", Vector2.RIGHT)
	var possible_directions = get_possible_directions(current_direction)
	
	# 更新位置历史并检查循环
	_update_position_history(current_head)
	var is_in_loop = _detect_position_loop()
	
	# 调试信息：显示位置历史
	if position_history.size() >= 4:
		var recent = position_history.slice(-4)
		print("AIBrain: 最近4个位置: ", recent)
	
	if is_in_loop:
		print("AIBrain: 检测到位置循环，启动反循环模式")
		# 启动反循环模式
		anti_loop_mode = true
		anti_loop_steps_remaining = ANTI_LOOP_DURATION
		# 不清空历史，而是保留用于持续监控
		# 选择一个随机方向
		possible_directions.shuffle()
		var random_direction = possible_directions[0]
		thinking_finished.emit()
		decision_made.emit(random_direction, "反循环模式: 随机移动")
		return random_direction
	
	if possible_directions.is_empty():
		print("AIBrain: No possible directions!")
		thinking_finished.emit()
		return Vector2.ZERO
	
	# 检查是否可以直接吃掉食物
	var food_position = game_state.get("food_position", Vector2(-1, -1))
	if food_position.x >= 0 and food_position.y >= 0:
		for direction in possible_directions:
			var target_pos = current_head + direction
			if target_pos == food_position:
				# 可以直接吃掉食物，立即选择这个方向
				var reasoning = "直接吃掉食物"
				var direct_scores = {"direct_food": 1.0, "total": 1.0}
				_update_decision_scores(direction, direct_scores)
				thinking_finished.emit()
				decision_made.emit(direction, reasoning)
				return direction
		
		# 如果无法直接吃掉食物，尝试朝向食物的方向移动
		# 但只有在没有检测到循环且不在反循环模式下才这样做
		if not is_in_loop and not anti_loop_mode:
			var food_direction = _get_direction_towards_food(current_head, food_position, possible_directions, game_state)
			if food_direction != Vector2.ZERO:
				# 检查这个方向是否会导致循环
				var next_pos = current_head + food_direction
				if _would_create_loop(next_pos):
					print("AIBrain: 朝向食物的方向会造成循环，使用综合评估")
				else:
					var reasoning = "朝向食物移动"
					var food_scores = {"food_direction": 0.8, "total": 0.8}
					_update_decision_scores(food_direction, food_scores)
					thinking_finished.emit()
					decision_made.emit(food_direction, reasoning)
					return food_direction
	
	# 评估每个可能的方向
	var evaluations: Array[Dictionary] = []
	for direction in possible_directions:
		var evaluation = evaluate_direction(direction, game_state)
		
		# 在反循环模式下，调整评估权重
		if anti_loop_mode:
			# 降低朝向食物的权重，增加安全性权重
			var food_score = evaluation.get("food_score", 0.0)
			var safety_score = evaluation.get("safety_score", 0.0)
			var total_score = safety_score * 2.0 + food_score * 0.3  # 大幅提高安全性权重
			evaluation["total_score"] = total_score
			evaluation["anti_loop_adjusted"] = true
		
		evaluations.append(evaluation)
	
	# 更新评估详情（用于调试）
	_update_evaluation_details(possible_directions, evaluations)
	
	# 选择最佳方向
	var best_evaluation = _select_best_direction(evaluations)
	var chosen_direction = best_evaluation.get("direction", Vector2.ZERO)
	
	# 更新决策评分（用于调试）
	_update_decision_scores(chosen_direction, best_evaluation)
	
	# 记录决策
	_record_decision(best_evaluation, game_state)
	
	# 计算决策时间
	var end_time = Time.get_time_dict_from_system()
	last_decision_time = _calculate_time_diff(start_time, end_time)
	
	# 生成决策理由
	var reasoning = _generate_reasoning(best_evaluation)
	
	# 调试信息：打印决策详情
	print("AIBrain Decision: ", chosen_direction, " - ", reasoning)
	print("  Food position: ", food_position, " Distance: ", current_head.distance_to(food_position))
	print("  Best score: ", best_evaluation.get("total_score", 0.0))
	print("  Food score: ", best_evaluation.get("food_score", 0.0))
	print("  Food bonus: ", best_evaluation.get("food_bonus", 0.0))
	
	# 打印所有方向的评估
	print("  All directions evaluation:")
	for eval in evaluations:
		var dir = eval.get("direction", Vector2.ZERO)
		var score = eval.get("total_score", 0.0)
		var food_score = eval.get("food_score", 0.0)
		var food_bonus = eval.get("food_bonus", 0.0)
		print("    ", dir, ": total=", score, " food=", food_score, " bonus=", food_bonus)
	
	# 处理反循环模式
	if anti_loop_mode:
		anti_loop_steps_remaining -= 1
		print("AIBrain: 反循环模式，剩余步数: ", anti_loop_steps_remaining)
		if anti_loop_steps_remaining <= 0:
			anti_loop_mode = false
			_clear_position_history()  # 现在才清空历史
			print("AIBrain: 退出反循环模式，历史已清空")
	
	thinking_finished.emit()
	decision_made.emit(chosen_direction, reasoning)
	
	return chosen_direction

## 评估特定方向的好坏程度
func evaluate_direction(direction: Vector2, game_state: Dictionary) -> Dictionary:
	var current_head = game_state.get("snake_head", Vector2.ZERO)
	var target_position = current_head + direction
	
	# 基本可行性检查
	if not _is_direction_safe(direction, game_state):
		return {
			"direction": direction,
			"total_score": -1000.0,
			"safety_score": 0.0,
			"food_score": 0.0,
			"space_score": 0.0,
			"future_safety_score": 0.0,
			"viable": false,
			"reason": "Immediate danger"
		}
	
	# 计算各项评分
	var safety_score = _calculate_safety_score(target_position, game_state)
	var food_score = _calculate_food_score(target_position, game_state)
	var space_score = _calculate_space_score(target_position, game_state)
	var future_safety_score = _calculate_future_safety_score(target_position, direction, game_state)
	
	# 检查这个方向是否朝向食物
	var food_bonus = 0.0
	var food_position = game_state.get("food_position", Vector2(-1, -1))
	if food_position.x >= 0 and food_position.y >= 0:
		var distance_before = current_head.distance_to(food_position)
		var distance_after = target_position.distance_to(food_position)
		if distance_after < distance_before:
			food_bonus = 0.5  # 朝向食物给予额外奖励
	
	# 计算加权总分
	var total_score = (
		safety_score * DECISION_WEIGHTS.safety +
		food_score * DECISION_WEIGHTS.food_distance +
		space_score * DECISION_WEIGHTS.space_available +
		future_safety_score * DECISION_WEIGHTS.future_safety +
		food_bonus  # 添加朝向食物的奖励
	)
	
	return {
		"direction": direction,
		"target_position": target_position,
		"total_score": total_score,
		"safety_score": safety_score,
		"food_score": food_score,
		"space_score": space_score,
		"future_safety_score": future_safety_score,
		"food_bonus": food_bonus,
		"viable": true,
		"confidence": _calculate_confidence(safety_score, space_score)
	}

## 获取可能的移动方向（排除反方向）
func get_possible_directions(current_direction: Vector2) -> Array[Vector2]:
	var all_directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var possible: Array[Vector2] = []
	
	for direction in all_directions:
		# 排除反方向（避免撞击自己）
		if direction != -current_direction:
			possible.append(direction)
	
	return possible

## 设置风险容忍度
func set_risk_tolerance(tolerance: float) -> void:
	risk_tolerance = clamp(tolerance, 0.0, 1.0)
	if risk_analyzer:
		risk_analyzer.set_risk_tolerance(tolerance)
	print("AIBrain: Risk tolerance set to ", risk_tolerance)

## 设置食物优先级
func set_food_priority(priority: float) -> void:
	food_priority = clamp(priority, 0.0, 1.0)
	print("AIBrain: Food priority set to ", food_priority)

## 设置前瞻步数
func set_look_ahead_steps(steps: int) -> void:
	look_ahead_steps = max(1, steps)
	print("AIBrain: Look ahead steps set to ", look_ahead_steps)

## 获取AI统计信息
func get_ai_stats() -> Dictionary:
	var success_rate = 0.0
	if total_decisions > 0:
		success_rate = float(successful_decisions) / float(total_decisions)
	
	return {
		"total_decisions": total_decisions,
		"successful_decisions": successful_decisions,
		"success_rate": success_rate,
		"last_decision_time": last_decision_time,
		"decision_confidence": decision_confidence,
		"risk_tolerance": risk_tolerance,
		"food_priority": food_priority,
		"look_ahead_steps": look_ahead_steps
	}

## 检查方向是否安全
func _is_direction_safe(direction: Vector2, game_state: Dictionary) -> bool:
	var current_head = game_state.get("snake_head", Vector2.ZERO)
	var target_position = current_head + direction
	
	# 使用风险分析器检查安全性
	if risk_analyzer:
		return risk_analyzer.is_position_safe(target_position, game_state)
	
	# 备用安全检查
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	var snake_body = game_state.get("snake_body", [])
	
	# 检查边界
	if target_position.x < 0 or target_position.x >= grid_width or target_position.y < 0 or target_position.y >= grid_height:
		return false
	
	# 检查蛇身碰撞
	if target_position in snake_body:
		return false
	
	return true

## 计算安全性评分
func _calculate_safety_score(position: Vector2, game_state: Dictionary) -> float:
	if risk_analyzer:
		return risk_analyzer.calculate_safety_score(position, game_state)
	return 0.5  # 默认中等安全

## 计算食物评分
func _calculate_food_score(position: Vector2, game_state: Dictionary) -> float:
	var food_position = game_state.get("food_position", Vector2(-1, -1))
	
	# 如果没有食物，返回中性评分
	if food_position.x < 0 or food_position.y < 0:
		return 0.5
	
	# 计算到食物的距离
	var distance = position.distance_to(food_position)
	
	# 如果就在食物旁边，给予最高评分
	if distance <= 1.0:
		return 1.0 * food_priority
	
	# 使用新的方向获取方法来评估食物可达性
	var food_direction_score = 0.0
	if pathfinder:
		var next_direction = pathfinder.get_next_direction_to_target(position, food_position, game_state)
		if next_direction != Vector2.ZERO:
			# 如果找到了方向，给予较高评分
			food_direction_score = 0.8
		else:
			# 如果找不到方向，给予较低评分
			food_direction_score = 0.3
	else:
		# 备用：基于距离
		food_direction_score = 1.0 / (1.0 + distance * 0.1)
	
	# 应用食物优先级，并增加近距离奖励
	var final_score = food_direction_score * food_priority
	if distance < 5.0:  # 距离食物5格以内给予额外奖励
		final_score *= (1.0 + (5.0 - distance) * 0.1)
	
	# 考虑饥饿程度
	var hunger_level = game_state.get("hunger_level", 0.0)
	if hunger_level > 0.5:  # 饥饿时增加食物评分
		final_score *= (1.0 + hunger_level * 0.5)
	
	return final_score

## 计算空间评分
func _calculate_space_score(position: Vector2, game_state: Dictionary) -> float:
	if space_analyzer:
		return space_analyzer.calculate_space_score(position, game_state)
	return 0.5  # 默认中等空间

## 计算未来安全性评分
func _calculate_future_safety_score(position: Vector2, direction: Vector2, game_state: Dictionary) -> float:
	if risk_analyzer:
		var future_risk = risk_analyzer.predict_future_risk(position, direction, game_state, look_ahead_steps)
		return 1.0 - future_risk  # 风险越低，安全性评分越高
	return 0.5  # 默认中等安全

## 选择最佳方向
func _select_best_direction(evaluations: Array[Dictionary]) -> Dictionary:
	var viable_evaluations = evaluations.filter(func(eval): return eval.get("viable", false))
	
	if viable_evaluations.is_empty():
		print("AIBrain Warning: No viable directions found!")
		# 返回第一个评估作为紧急选择
		return evaluations[0] if evaluations.size() > 0 else {}
	
	# 按总分排序
	viable_evaluations.sort_custom(func(a, b): return a.total_score > b.total_score)
	
	var best = viable_evaluations[0]
	decision_confidence = _calculate_overall_confidence(viable_evaluations)
	
	return best

## 记录决策
func _record_decision(decision: Dictionary, game_state: Dictionary) -> void:
	total_decisions += 1
	
	var decision_record = {
		"timestamp": Time.get_time_dict_from_system(),
		"direction": decision.get("direction", Vector2.ZERO),
		"score": decision.get("total_score", 0.0),
		"confidence": decision.get("confidence", 0.0),
		"game_state_snapshot": {
			"snake_length": game_state.get("snake_body", []).size(),
			"food_position": game_state.get("food_position", Vector2.ZERO)
		}
	}
	
	recent_decisions.append(decision_record)
	
	# 保持历史记录在限制内
	if recent_decisions.size() > MAX_DECISION_HISTORY:
		recent_decisions.remove_at(0)

## 生成决策理由
func _generate_reasoning(evaluation: Dictionary) -> String:
	var reasoning_parts: Array[String] = []
	
	var safety = evaluation.get("safety_score", 0.0)
	var food = evaluation.get("food_score", 0.0)
	var space = evaluation.get("space_score", 0.0)
	var future = evaluation.get("future_safety_score", 0.0)
	var food_bonus = evaluation.get("food_bonus", 0.0)
	
	# 分析主要决策因素
	if safety > 0.8:
		reasoning_parts.append("高安全性")
	elif safety < 0.3:
		reasoning_parts.append("风险较高")
	
	if food > 0.7:
		reasoning_parts.append("接近食物")
	elif food < 0.3:
		reasoning_parts.append("远离食物")
	
	if food_bonus > 0:
		reasoning_parts.append("朝向食物")
	
	if space > 0.7:
		reasoning_parts.append("空间充裕")
	elif space < 0.3:
		reasoning_parts.append("空间受限")
	
	if future > 0.7:
		reasoning_parts.append("未来安全")
	elif future < 0.3:
		reasoning_parts.append("未来风险")
	
	var reasoning = "决策基于: " + ", ".join(reasoning_parts)
	
	# 添加置信度信息
	var confidence = evaluation.get("confidence", 0.0)
	if confidence > 0.8:
		reasoning += " (高置信度)"
	elif confidence < 0.4:
		reasoning += " (低置信度)"
	
	return reasoning

## 计算单个评估的置信度
func _calculate_confidence(safety_score: float, space_score: float) -> float:
	# 置信度主要基于安全性和空间可用性
	return (safety_score + space_score) / 2.0

## 计算整体置信度
func _calculate_overall_confidence(evaluations: Array[Dictionary]) -> float:
	if evaluations.is_empty():
		return 0.0
	
	var best_score = evaluations[0].get("total_score", 0.0)
	var second_best_score = 0.0
	
	if evaluations.size() > 1:
		second_best_score = evaluations[1].get("total_score", 0.0)
	
	# 如果最佳选择明显优于次佳选择，置信度更高
	var score_difference = best_score - second_best_score
	return clamp(score_difference / 2.0, 0.0, 1.0)

## 计算时间差（毫秒）
func _calculate_time_diff(start_time: Dictionary, end_time: Dictionary) -> float:
	var start_ms = start_time.hour * 3600000 + start_time.minute * 60000 + start_time.second * 1000
	var end_ms = end_time.hour * 3600000 + end_time.minute * 60000 + end_time.second * 1000
	return float(end_ms - start_ms)

## 获取朝向食物的方向（带循环检测）
func _get_direction_towards_food(current_head: Vector2, food_position: Vector2, possible_directions: Array[Vector2], game_state: Dictionary) -> Vector2:
	if not pathfinder:
		return Vector2.ZERO
	
	# 使用PathFinder获取到食物的下一个方向
	var next_direction = pathfinder.get_next_direction_to_target(current_head, food_position, game_state)
	
	# 检查这个方向是否在可能的方向列表中，并且不会造成循环
	if next_direction in possible_directions:
		var next_pos = current_head + next_direction
		if not _would_create_loop(next_pos):
			print("AIBrain: Moving towards food with direction: ", next_direction)
			return next_direction
		else:
			print("AIBrain: PathFinder方向会造成循环，尝试其他方向")
	
	# 如果PathFinder的方向不可行，尝试简单的方向引导
	var dx = food_position.x - current_head.x
	var dy = food_position.y - current_head.y
	
	# 优先选择距离较大的方向
	var preferred_directions: Array[Vector2] = []
	
	if abs(dx) > abs(dy):
		# 水平距离更大
		if dx > 0 and Vector2.RIGHT in possible_directions:
			preferred_directions.append(Vector2.RIGHT)
		elif dx < 0 and Vector2.LEFT in possible_directions:
			preferred_directions.append(Vector2.LEFT)
		
		if dy > 0 and Vector2.DOWN in possible_directions:
			preferred_directions.append(Vector2.DOWN)
		elif dy < 0 and Vector2.UP in possible_directions:
			preferred_directions.append(Vector2.UP)
	else:
		# 垂直距离更大
		if dy > 0 and Vector2.DOWN in possible_directions:
			preferred_directions.append(Vector2.DOWN)
		elif dy < 0 and Vector2.UP in possible_directions:
			preferred_directions.append(Vector2.UP)
		
		if dx > 0 and Vector2.RIGHT in possible_directions:
			preferred_directions.append(Vector2.RIGHT)
		elif dx < 0 and Vector2.LEFT in possible_directions:
			preferred_directions.append(Vector2.LEFT)
	
	# 返回第一个可行且不会造成循环的方向
	for direction in preferred_directions:
		var next_pos = current_head + direction
		if not _would_create_loop(next_pos):
			print("AIBrain: Using simple direction towards food: ", direction)
			return direction
	
	# 如果所有朝向食物的方向都会造成循环，返回空向量让AI使用综合评估
	print("AIBrain: 所有朝向食物的方向都会造成循环，放弃简单路径")
	return Vector2.ZERO

## 更新决策权重
func update_decision_weights(new_weights: Dictionary) -> void:
	for key in new_weights:
		if DECISION_WEIGHTS.has(key):
			DECISION_WEIGHTS[key] = new_weights[key]
	
	print("AIBrain: Decision weights updated: ", DECISION_WEIGHTS)

## 重置AI状态
func reset_ai_state() -> void:
	recent_decisions.clear()
	total_decisions = 0
	successful_decisions = 0
	decision_confidence = 0.0
	print("AIBrain: AI state reset")

## 分析最近的决策表现
func analyze_recent_performance() -> Dictionary:
	if recent_decisions.is_empty():
		return {"performance": "no_data"}
	
	var total_confidence = 0.0
	var high_confidence_decisions = 0
	
	for decision in recent_decisions:
		var confidence = decision.get("confidence", 0.0)
		total_confidence += confidence
		if confidence > 0.7:
			high_confidence_decisions += 1
	
	var avg_confidence = total_confidence / recent_decisions.size()
	var confidence_ratio = float(high_confidence_decisions) / float(recent_decisions.size())
	
	return {
		"average_confidence": avg_confidence,
		"high_confidence_ratio": confidence_ratio,
		"recent_decisions_count": recent_decisions.size(),
		"performance": "good" if avg_confidence > 0.6 else "needs_improvement"
	}

## 获取最近决策的评分详情
func get_last_decision_scores() -> Dictionary:
	return last_decision_scores

## 获取最近决策的评估详情
func get_last_evaluation_details() -> Dictionary:
	return last_evaluation_details

## 更新决策评分（在做决策时调用）
func _update_decision_scores(direction: Vector2, scores: Dictionary) -> void:
	last_decision_scores = {
		"direction": direction,
		"safety_score": scores.get("safety", 0.0),
		"food_score": scores.get("food_distance", 0.0),
		"space_score": scores.get("space_available", 0.0),
		"future_score": scores.get("future_safety", 0.0),
		"total_score": scores.get("total", 0.0),
		"timestamp": Time.get_ticks_msec() / 1000.0
	}

## 更新评估详情
func _update_evaluation_details(all_directions: Array, evaluations: Array) -> void:
	last_evaluation_details = {
		"evaluated_directions": all_directions,
		"direction_scores": evaluations,
		"best_direction": evaluations[0] if evaluations.size() > 0 else {},
		"alternatives": evaluations.slice(1, min(3, evaluations.size())),
		"evaluation_time": Time.get_ticks_msec() / 1000.0
	}

## 更新位置历史
func _update_position_history(position: Vector2) -> void:
	position_history.append(position)
	
	# 限制历史长度
	if position_history.size() > MAX_POSITION_HISTORY:
		position_history.remove_at(0)

## 检测位置循环
func _detect_position_loop() -> bool:
	if position_history.size() < 6:
		return false
	
	# 检查最近8步中是否有重复的位置模式
	var recent_positions = position_history.slice(-8)
	
	# 简单检测：如果当前位置在最近4步中出现过，就认为是循环
	var current_pos = recent_positions[-1]  # 最新位置
	var earlier_positions = recent_positions.slice(0, -1)  # 除了最新位置的其他位置
	
	for i in range(earlier_positions.size()):
		if earlier_positions[i].distance_to(current_pos) < 0.1:
			print("AIBrain: 检测到循环 - 当前位置 ", current_pos, " 在 ", i+1, " 步前出现过")
			return true
	
	return false

## 清空位置历史
func _clear_position_history() -> void:
	position_history.clear()
	print("AIBrain: 位置历史已清空")

## 检查某个位置是否会造成循环
func _would_create_loop(position: Vector2) -> bool:
	if position_history.size() < 3:
		return false
	
	# 简单检测：如果这个位置在最近4步中出现过，认为会造成循环
	var recent_positions = position_history.slice(-4)
	for pos in recent_positions:
		if pos.distance_to(position) < 0.1:  # 基本相同位置
			print("AIBrain: 预测循环 - 位置 ", position, " 在最近历史中出现过")
			return true
	
	return false
