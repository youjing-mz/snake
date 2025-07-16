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

# 性能监控
var last_decision_time: float = 0.0
var total_decisions: int = 0
var successful_decisions: int = 0

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
	
	if possible_directions.is_empty():
		print("AIBrain: No possible directions!")
		thinking_finished.emit()
		return Vector2.ZERO
	
	# 评估每个可能的方向
	var evaluations: Array[Dictionary] = []
	for direction in possible_directions:
		var evaluation = evaluate_direction(direction, game_state)
		evaluations.append(evaluation)
	
	# 选择最佳方向
	var best_evaluation = _select_best_direction(evaluations)
	var chosen_direction = best_evaluation.get("direction", Vector2.ZERO)
	
	# 记录决策
	_record_decision(best_evaluation, game_state)
	
	# 计算决策时间
	var end_time = Time.get_time_dict_from_system()
	last_decision_time = _calculate_time_diff(start_time, end_time)
	
	# 生成决策理由
	var reasoning = _generate_reasoning(best_evaluation)
	
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
	
	# 计算加权总分
	var total_score = (
		safety_score * DECISION_WEIGHTS.safety +
		food_score * DECISION_WEIGHTS.food_distance +
		space_score * DECISION_WEIGHTS.space_available +
		future_safety_score * DECISION_WEIGHTS.future_safety
	)
	
	return {
		"direction": direction,
		"target_position": target_position,
		"total_score": total_score,
		"safety_score": safety_score,
		"food_score": food_score,
		"space_score": space_score,
		"future_safety_score": future_safety_score,
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
	
	# 尝试寻找到食物的路径
	var path_score = 0.0
	if pathfinder:
		var path = pathfinder.find_path(position, food_position, game_state)
		if path.size() > 0:
			# 路径长度越短评分越高
			var path_length = pathfinder.calculate_path_length(path)
			path_score = 1.0 / (1.0 + path_length * 0.1)
		else:
			# 如果找不到路径，基于直线距离评分
			path_score = 1.0 / (1.0 + distance * 0.2)
	else:
		# 备用：基于曼哈顿距离
		var manhattan_distance = abs(position.x - food_position.x) + abs(position.y - food_position.y)
		path_score = 1.0 / (1.0 + manhattan_distance * 0.1)
	
	# 应用食物优先级
	return path_score * food_priority

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
	
	# 分析主要决策因素
	if safety > 0.8:
		reasoning_parts.append("高安全性")
	elif safety < 0.3:
		reasoning_parts.append("风险较高")
	
	if food > 0.7:
		reasoning_parts.append("接近食物")
	elif food < 0.3:
		reasoning_parts.append("远离食物")
	
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
