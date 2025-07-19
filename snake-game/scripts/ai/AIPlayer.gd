## AI玩家主控制器
## 管理AI难度、决策调度和性能监控
## 作者：课程示例
## 创建时间：2025-01-16

class_name AIPlayer
extends Node2D

# 信号定义
signal ai_decision_made(direction: Vector2, reasoning: String)
signal ai_died(survival_time: float, score: int)
signal ai_stats_updated(stats: Dictionary)
signal difficulty_changed(new_difficulty: Difficulty)

# 新增调试信号
signal decision_made(direction: Vector2, reasoning: String, confidence: float, scores: Dictionary)
signal performance_updated(metrics: Dictionary)
signal behavior_analyzed(behavior_data: Dictionary)
signal risk_assessed(risk_data: Dictionary)
signal path_calculated(path_data: Dictionary)

# 难度枚举
enum Difficulty { EASY, NORMAL, HARD, EXPERT }

# 难度配置
const DIFFICULTY_CONFIGS: Dictionary = {
	Difficulty.EASY: {
		"reaction_delay": 0.5,
		"error_rate": 0.2,
		"look_ahead_steps": 1,
		"risk_tolerance": 0.8,
		"food_priority": 0.3,
		"decision_weights": {
			"safety": 1.5,
			"food_distance": 0.3,
			"space_available": 0.2,
			"future_safety": 0.5
		}
	},
	Difficulty.NORMAL: {
		"reaction_delay": 0.2,
		"error_rate": 0.1,
		"look_ahead_steps": 3,
		"risk_tolerance": 0.5,
		"food_priority": 0.6,
		"decision_weights": {
			"safety": 1.0,
			"food_distance": 0.6,
			"space_available": 0.4,
			"future_safety": 0.8
		}
	},
	Difficulty.HARD: {
		"reaction_delay": 0.1,
		"error_rate": 0.05,
		"look_ahead_steps": 5,
		"risk_tolerance": 0.3,
		"food_priority": 0.8,
		"decision_weights": {
			"safety": 0.8,
			"food_distance": 0.9,
			"space_available": 0.6,
			"future_safety": 1.0
		}
	},
	Difficulty.EXPERT: {
		"reaction_delay": 0.05,
		"error_rate": 0.01,
		"look_ahead_steps": 8,
		"risk_tolerance": 0.2,
		"food_priority": 1.5,  # 增加食物优先级
		"decision_weights": {
			"safety": 0.6,      # 稍微降低安全性权重
			"food_distance": 1.5,  # 大幅增加食物距离权重
			"space_available": 0.6,
			"future_safety": 1.0
		}
	}
}

# 组件引用
var ai_snake: Snake
var ai_brain: AIBrain
var decision_timer: Timer
var error_timer: Timer

# AI状态
var difficulty: Difficulty = Difficulty.NORMAL
var reaction_delay: float = 0.2
var error_rate: float = 0.1
var is_active: bool = false
var is_thinking: bool = false
var look_ahead_steps: int = 3  # 添加前瞻步数变量

# 性能统计
var start_time: float = 0.0
var survival_time: float = 0.0
var score: int = 0
var foods_eaten: int = 0
var total_moves: int = 0
var successful_moves: int = 0
var last_food_time: float = 0.0  # 上次吃到食物的时间
var hunger_level: float = 0.0    # 饥饿程度

# 行为分析数据
var behavior_data: Dictionary = {
	"direction_preferences": {"UP": 0, "DOWN": 0, "LEFT": 0, "RIGHT": 0},
	"last_decisions": [],
	"decision_reasons": {}
}

# 错误处理
var last_error_time: float = 0.0
var consecutive_errors: int = 0
const MAX_CONSECUTIVE_ERRORS: int = 3

func _ready() -> void:
	# 初始化AI系统
	_initialize_ai_system()
	
	# 设置节点组
	add_to_group("ai_players")
	
	print("AIPlayer initialized with difficulty: ", Difficulty.keys()[difficulty])

## 初始化AI系统
func _initialize_ai_system() -> void:
	# 创建AI大脑
	ai_brain = AIBrain.new()
	add_child(ai_brain)
	
	# 创建决策计时器
	decision_timer = Timer.new()
	decision_timer.wait_time = reaction_delay
	decision_timer.one_shot = true
	decision_timer.timeout.connect(_on_decision_timer_timeout)
	add_child(decision_timer)
	
	# 创建错误计时器（用于模拟AI错误）
	error_timer = Timer.new()
	error_timer.wait_time = 1.0  # 每秒检查一次是否应该产生错误
	error_timer.timeout.connect(_on_error_timer_timeout)
	add_child(error_timer)
	
	# 连接AI大脑信号
	ai_brain.decision_made.connect(_on_ai_decision_made)
	ai_brain.thinking_started.connect(_on_thinking_started)
	ai_brain.thinking_finished.connect(_on_thinking_finished)
	
	# 应用初始难度设置
	set_difficulty(difficulty)

## 启动AI
func start_ai(snake: Snake) -> void:
	if not snake:
		print("AIPlayer Error: Cannot start AI without snake reference")
		return
	
	ai_snake = snake
	is_active = true
	start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	# 重置统计数据
	_reset_stats()
	
	# 启动计时器
	if error_timer:
		error_timer.start()
	
	# 启动定期决策
	start_periodic_decisions()
	
	print("AIPlayer: AI started for snake ", snake.name)

## 停止AI
func stop_ai() -> void:
	is_active = false
	is_thinking = false
	
	# 停止所有计时器
	if decision_timer:
		decision_timer.stop()
	if error_timer:
		error_timer.stop()
	
	# 计算生存时间
	if start_time > 0:
		var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		survival_time = current_time - start_time
	
	# 发送死亡信号
	ai_died.emit(survival_time, score)
	
	print("AIPlayer: AI stopped. Survival time: ", survival_time, "s, Score: ", score)

## 进行AI决策
func make_ai_decision() -> void:
	if not is_active or not ai_snake or is_thinking:
		return
	
	# 获取游戏状态
	var game_state = _get_current_game_state()
	
	# 启动决策计时器（模拟反应延迟）
	decision_timer.wait_time = reaction_delay
	decision_timer.start()
	
	# 开始思考
	is_thinking = true
	ai_brain.think(game_state)

## 启动定期决策（每秒调用一次）
func start_periodic_decisions() -> void:
	if not is_active:
		return
	
	# 创建决策循环计时器
	var decision_loop_timer = Timer.new()
	decision_loop_timer.wait_time = 0.2  # 每0.2秒尝试决策一次
	decision_loop_timer.timeout.connect(_on_decision_loop)
	decision_loop_timer.autostart = true
	add_child(decision_loop_timer)

## 设置难度
func set_difficulty(new_difficulty: Difficulty) -> void:
	if new_difficulty < 0 or new_difficulty >= Difficulty.size():
		print("AIPlayer Error: Invalid difficulty level")
		return
	
	var old_difficulty = difficulty
	difficulty = new_difficulty
	
	# 应用难度配置
	var config = DIFFICULTY_CONFIGS[difficulty]
	reaction_delay = config.reaction_delay
	error_rate = config.error_rate
	
	# 配置AI大脑
	if ai_brain:
		ai_brain.set_risk_tolerance(config.risk_tolerance)
		ai_brain.set_food_priority(config.food_priority)
		ai_brain.set_look_ahead_steps(config.look_ahead_steps)
		ai_brain.update_decision_weights(config.decision_weights)
	
	print("AIPlayer: Difficulty changed from ", Difficulty.keys()[old_difficulty], " to ", Difficulty.keys()[difficulty])
	difficulty_changed.emit(difficulty)

## 获取AI统计信息
func get_ai_stats() -> Dictionary:
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	var current_survival_time = current_time - start_time if start_time > 0 else 0.0
	
	var move_success_rate = 0.0
	if total_moves > 0:
		move_success_rate = float(successful_moves) / float(total_moves)
	
	var stats = {
		"difficulty": Difficulty.keys()[difficulty],
		"is_active": is_active,
		"survival_time": current_survival_time,
		"score": score,
		"foods_eaten": foods_eaten,
		"total_moves": total_moves,
		"successful_moves": successful_moves,
		"move_success_rate": move_success_rate,
		"reaction_delay": reaction_delay,
		"error_rate": error_rate,
		"consecutive_errors": consecutive_errors
	}
	
	# 合并AI大脑的统计信息
	if ai_brain:
		var brain_stats = ai_brain.get_ai_stats()
		stats.merge(brain_stats)
	
	return stats

## 更新分数
func update_score(points: int) -> void:
	score += points
	if points > 0:
		foods_eaten += 1
		last_food_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		hunger_level = 0.0  # 重置饥饿程度
		print("AIPlayer: Food eaten! Hunger reset.")

## 获取当前游戏状态
func _get_current_game_state() -> Dictionary:
	if not ai_snake:
		return {}
	
	# 更新饥饿程度
	_update_hunger_level()
	
	# 获取网格信息
	var grid_size = Constants.get_grid_size()
	
	# 构建游戏状态字典
	var game_state = {
		"snake_head": ai_snake.get_head_position(),
		"snake_body": ai_snake.get_body_positions(),
		"current_direction": ai_snake.get_direction(),
		"grid_width": grid_size.x,
		"grid_height": grid_size.y,
		"hunger_level": hunger_level  # 添加饥饿程度
	}
	
	# 获取食物位置（从游戏场景中）
	var food = get_tree().get_first_node_in_group("food")
	if food and food.has_method("get_current_position"):
		game_state["food_position"] = food.get_current_position()
	else:
		game_state["food_position"] = Vector2(-1, -1)
	
	return game_state

## 更新饥饿程度
func _update_hunger_level() -> void:
	if last_food_time > 0:
		var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		var time_since_food = current_time - last_food_time
		hunger_level = min(1.0, time_since_food / 10.0)  # 10秒后达到最大饥饿
		
		if hunger_level > 0.8:
			print("AIPlayer: Very hungry! Hunger level: ", hunger_level)

## 重置统计数据
func _reset_stats() -> void:
	survival_time = 0.0
	score = 0
	foods_eaten = 0
	total_moves = 0
	successful_moves = 0
	consecutive_errors = 0
	last_food_time = 0.0
	hunger_level = 0.0

## 检查是否应该产生错误
func _should_make_error() -> bool:
	return randf() < error_rate

## 产生随机错误方向
func _generate_error_direction(correct_direction: Vector2) -> Vector2:
	var all_directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	all_directions.erase(correct_direction)  # 移除正确方向
	
	if all_directions.size() > 0:
		return all_directions[randi() % all_directions.size()]
	return correct_direction

## 决策计时器超时处理
func _on_decision_timer_timeout() -> void:
	# 决策延迟结束，可以执行决策
	pass

## AI决策完成处理
func _on_ai_decision_made(direction: Vector2, reasoning: String) -> void:
	if not is_active or not ai_snake:
		return
	
	is_thinking = false
	total_moves += 1
	
	# 获取详细的决策信息
	var confidence = 0.8  # 基础置信度
	var decision_scores = {}
	
	if ai_brain:
		confidence = ai_brain.decision_confidence
		decision_scores = ai_brain.get_last_decision_scores()
	
	# 检查是否应该产生错误
	var final_direction = direction
	if _should_make_error():
		final_direction = _generate_error_direction(direction)
		consecutive_errors += 1
		confidence *= 0.5  # 错误决策降低置信度
		last_error_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		print("AIPlayer: Made error - chose ", final_direction, " instead of ", direction)
	else:
		successful_moves += 1
		consecutive_errors = 0
	
	# 执行决策
	if ai_snake.has_method("set_direction"):
		ai_snake.set_direction(final_direction)
	
	# 发送原有决策信号
	ai_decision_made.emit(final_direction, reasoning)
	
	# 发送新增的详细决策信号
	decision_made.emit(final_direction, reasoning, confidence, decision_scores)
	
	# 更新和发送性能数据
	_update_and_emit_performance_metrics()
	
	# 分析和发送行为数据
	_analyze_and_emit_behavior_data(final_direction, reasoning)
	
	# 发送风险评估数据
	_emit_risk_assessment_data()
	
	# 发送路径计算数据
	_emit_path_calculation_data()
	
	# 更新统计信息
	var stats = get_ai_stats()
	ai_stats_updated.emit(stats)
	
	# 检查连续错误
	if consecutive_errors >= MAX_CONSECUTIVE_ERRORS:
		print("AIPlayer Warning: Too many consecutive errors, reducing error rate temporarily")
		error_rate *= 0.5  # 临时降低错误率

## 思考开始处理
func _on_thinking_started() -> void:
	is_thinking = true

## 思考结束处理
func _on_thinking_finished() -> void:
	# thinking状态会在决策完成后重置
	pass

## 错误计时器超时处理
func _on_error_timer_timeout() -> void:
	# 定期检查并可能调整错误率
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	# 如果长时间没有错误，恢复正常错误率
	if current_time - last_error_time > 10.0:  # 10秒没有错误
		var config = DIFFICULTY_CONFIGS[difficulty]
		error_rate = config.error_rate

## 决策循环处理
func _on_decision_loop() -> void:
	if is_active and not is_thinking:
		make_ai_decision()

## 获取当前难度
func get_difficulty() -> Difficulty:
	return difficulty

## 检查AI是否活跃
func is_ai_active() -> bool:
	return is_active

## 设置暂停状态
func set_paused(paused: bool) -> void:
	if paused:
		# 暂停AI决策
		is_thinking = false
		if decision_timer:
			decision_timer.stop()
		if error_timer:
			error_timer.stop()
		print("AIPlayer: AI paused")
	else:
		# 恢复AI决策
		if error_timer:
			error_timer.start()
		print("AIPlayer: AI resumed")

## 强制立即决策（调试用）
func force_decision() -> void:
	if is_active and not is_thinking:
		make_ai_decision()

## 获取AI性能评估
func get_performance_evaluation() -> Dictionary:
	var stats = get_ai_stats()
	var performance = "unknown"
	
	if stats.move_success_rate > 0.8:
		performance = "excellent"
	elif stats.move_success_rate > 0.6:
		performance = "good"
	elif stats.move_success_rate > 0.4:
		performance = "average"
	else:
		performance = "poor"
	
	return {
		"overall_performance": performance,
		"survival_rating": "long" if survival_time > 60 else "short" if survival_time < 20 else "medium",
		"food_efficiency": foods_eaten / max(1.0, survival_time / 10.0),  # 每10秒吃到的食物数
		"error_frequency": consecutive_errors / max(1.0, survival_time),
		"recommended_difficulty": _recommend_difficulty()
	}

## 推荐难度调整
func _recommend_difficulty() -> Difficulty:
	var stats = get_ai_stats()
	
	# 基于表现推荐难度
	if stats.move_success_rate > 0.9 and consecutive_errors == 0:
		# 表现太好，建议增加难度
		return min(Difficulty.EXPERT, difficulty + 1)
	elif stats.move_success_rate < 0.3 or consecutive_errors > 5:
		# 表现较差，建议降低难度
		return max(Difficulty.EASY, difficulty - 1)
	else:
		# 保持当前难度
		return difficulty

## 更新并发送性能指标
func _update_and_emit_performance_metrics() -> void:
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	var current_survival_time = current_time - start_time if start_time > 0 else 0.0
	
	var metrics = {
		"survival_time": current_survival_time,
		"decisions_made": total_moves,
		"food_eaten": foods_eaten,
		"near_misses": _count_near_misses(),
		"avg_decision_time": reaction_delay,
		"avg_confidence": float(successful_moves) / max(1, total_moves),
		"error_rate": float(consecutive_errors) / max(1, total_moves),
		"food_efficiency": float(foods_eaten) / max(1, current_survival_time / 10.0)
	}
	
	performance_updated.emit(metrics)

## 分析并发送行为数据
func _analyze_and_emit_behavior_data(direction: Vector2, reasoning: String) -> void:
	# 更新方向偏好统计
	var direction_name = _get_direction_name(direction)
	if not behavior_data.direction_preferences.has(direction_name):
		behavior_data.direction_preferences[direction_name] = 0
	behavior_data.direction_preferences[direction_name] += 1
	
	# 更新决策历史
	behavior_data.last_decisions.append(direction)
	if behavior_data.last_decisions.size() > 20:
		behavior_data.last_decisions.pop_front()
	
	# 分析主导策略
	var dominant_strategy = _analyze_dominant_strategy(reasoning)
	
	var behavior_analysis = {
		"direction_preferences": behavior_data.direction_preferences,
		"recent_decisions": behavior_data.last_decisions.slice(-5),  # 最近5个决策
		"dominant_strategy": dominant_strategy,
		"total_moves": total_moves,
		"decision_pattern": _analyze_decision_pattern()
	}
	
	behavior_analyzed.emit(behavior_analysis)

## 发送风险评估数据
func _emit_risk_assessment_data() -> void:
	if not ai_brain or not ai_brain.risk_analyzer:
		return
	
	var risk_data = {
		"current_risk_level": _calculate_current_risk(),
		"immediate_threats": _identify_immediate_threats(),
		"future_risk": _predict_future_risk(),
		"risk_factors": _get_risk_factors(),
		"safety_zones": _identify_safety_zones()
	}
	
	risk_assessed.emit(risk_data)

## 发送路径计算数据
func _emit_path_calculation_data() -> void:
	if not ai_brain or not ai_brain.pathfinder:
		return
	
	var game_state = _get_current_game_state()
	var food_pos = game_state.get("food_position", Vector2(-1, -1))
	var snake_head = game_state.get("snake_head", Vector2(0, 0))
	
	# 尝试寻找到食物的路径
	var path = ai_brain.pathfinder.find_path(snake_head, food_pos, game_state)
	
	var path_data = {
		"has_path": path.size() > 0,
		"path_length": path.size(),
		"target_position": food_pos,
		"next_direction": path[0] if path.size() > 0 else Vector2.ZERO,
		"algorithm": "A*",
		"path_efficiency": _calculate_path_efficiency(path),
		"alternative_paths": _find_alternative_paths(snake_head, food_pos, game_state)
	}
	
	path_calculated.emit(path_data)

## 辅助方法：获取方向名称
func _get_direction_name(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "UP"
	elif direction == Vector2.DOWN:
		return "DOWN"
	elif direction == Vector2.LEFT:
		return "LEFT"
	elif direction == Vector2.RIGHT:
		return "RIGHT"
	else:
		return "UNKNOWN"

## 辅助方法：分析主导策略
func _analyze_dominant_strategy(reasoning: String) -> String:
	if "食物" in reasoning:
		return "觅食导向"
	elif "安全" in reasoning or "避险" in reasoning:
		return "安全导向"
	elif "空间" in reasoning:
		return "空间优化"
	elif "未来" in reasoning:
		return "前瞻规划"
	else:
		return "混合策略"

## 辅助方法：分析决策模式
func _analyze_decision_pattern() -> String:
	if behavior_data.last_decisions.size() < 3:
		return "数据不足"
	
	var recent = behavior_data.last_decisions.slice(-3)
	
	# 检查是否在重复模式
	if recent[0] == recent[2]:
		return "往复模式"
	
	# 检查是否在螺旋模式
	var turns = 0
	for i in range(1, recent.size()):
		if recent[i] != recent[i-1]:
			turns += 1
	
	if turns >= 2:
		return "转向频繁"
	elif turns == 0:
		return "直线前进"
	else:
		return "正常导航"

## 辅助方法：计算当前风险
func _calculate_current_risk() -> float:
	if not ai_snake:
		return 0.0
	
	var head_pos = ai_snake.get_head_position()
	var grid_size = Constants.get_grid_size()
	
	# 计算边界风险
	var border_risk = 0.0
	var min_border_distance = min(
		head_pos.x,
		head_pos.y,
		grid_size.x - head_pos.x - 1,
		grid_size.y - head_pos.y - 1
	)
	border_risk = max(0.0, 1.0 - (min_border_distance / 3.0))
	
	# 计算身体碰撞风险
	var body_risk = 0.0
	var body_positions = ai_snake.get_body_positions()
	for body_pos in body_positions:
		var distance = head_pos.distance_to(body_pos)
		if distance <= 2.0:
			body_risk += 0.3 / max(1.0, distance)
	
	return min(1.0, border_risk + body_risk)

## 辅助方法：识别即时威胁
func _identify_immediate_threats() -> Array:
	var threats = []
	
	if not ai_snake:
		return threats
	
	var head_pos = ai_snake.get_head_position()
	var grid_size = Constants.get_grid_size()
	
	# 检查边界威胁
	if head_pos.x <= 1:
		threats.append("左边界")
	if head_pos.x >= grid_size.x - 2:
		threats.append("右边界")
	if head_pos.y <= 1:
		threats.append("上边界")
	if head_pos.y >= grid_size.y - 2:
		threats.append("下边界")
	
	# 检查身体威胁
	var body_positions = ai_snake.get_body_positions()
	for body_pos in body_positions:
		if head_pos.distance_to(body_pos) <= 1.5:
			threats.append("蛇身碰撞")
			break
	
	return threats

## 辅助方法：预测未来风险
func _predict_future_risk() -> float:
	if not ai_brain:
		return 0.0
	
	# 模拟未来几步的风险
	var future_risk = 0.0
	var current_pos = ai_snake.get_head_position() if ai_snake else Vector2.ZERO
	var current_dir = ai_snake.get_direction() if ai_snake else Vector2.RIGHT
	
	for step in range(1, look_ahead_steps + 1):
		current_pos += current_dir
		var step_risk = _calculate_position_risk(current_pos)
		future_risk += step_risk / step  # 距离越远权重越小
	
	return min(1.0, future_risk / look_ahead_steps)

## 辅助方法：获取风险因素
func _get_risk_factors() -> Dictionary:
	return {
		"hunger_level": hunger_level,
		"consecutive_errors": consecutive_errors,
		"time_since_food": _get_time_since_food(),
		"space_constraint": _calculate_space_constraint()
	}

## 辅助方法：识别安全区域
func _identify_safety_zones() -> Array:
	var safe_zones = []
	
	if not ai_snake:
		return safe_zones
	
	var head_pos = ai_snake.get_head_position()
	var grid_size = Constants.get_grid_size()
	
	# 寻找周围的安全位置
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var check_pos = head_pos + Vector2(dx, dy)
			if _is_position_safe(check_pos):
				safe_zones.append(check_pos)
	
	return safe_zones

## 辅助方法：计算位置风险
func _calculate_position_risk(pos: Vector2) -> float:
	var grid_size = Constants.get_grid_size()
	
	# 边界风险
	if pos.x < 0 or pos.x >= grid_size.x or pos.y < 0 or pos.y >= grid_size.y:
		return 1.0
	
	# 身体碰撞风险
	if ai_snake:
		var body_positions = ai_snake.get_body_positions()
		for body_pos in body_positions:
			if pos == body_pos:
				return 1.0
	
	return 0.0

## 辅助方法：检查位置是否安全
func _is_position_safe(pos: Vector2) -> bool:
	return _calculate_position_risk(pos) < 0.3

## 辅助方法：计算距离上次吃食物的时间
func _get_time_since_food() -> float:
	if last_food_time == 0.0:
		return 0.0
	
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	return current_time - last_food_time

## 辅助方法：计算空间约束
func _calculate_space_constraint() -> float:
	if not ai_brain or not ai_brain.space_analyzer:
		return 0.0
	
	var game_state = _get_current_game_state()
	# 简化空间约束计算
	var grid_size = Constants.get_grid_size()
	var snake_length = ai_snake.get_body_positions().size() if ai_snake else 3
	var total_space = grid_size.x * grid_size.y
	var available_space = total_space - snake_length
	
	return 1.0 - (float(available_space) / float(total_space))

## 辅助方法：计算路径效率
func _calculate_path_efficiency(path: Array) -> float:
	if path.size() == 0:
		return 0.0
	
	# 计算实际路径长度与理论最短距离的比值
	var start_pos = ai_snake.get_head_position() if ai_snake else Vector2.ZERO
	var end_pos = path[-1] if path.size() > 0 else Vector2.ZERO
	var manhattan_distance = abs(end_pos.x - start_pos.x) + abs(end_pos.y - start_pos.y)
	
	if manhattan_distance == 0:
		return 1.0
	
	return float(manhattan_distance) / float(path.size())

## 辅助方法：寻找替代路径
func _find_alternative_paths(start: Vector2, target: Vector2, game_state: Dictionary) -> Array:
	# 简化版：返回可能的替代方向
	var alternatives = []
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		var next_pos = start + direction
		if _is_position_safe(next_pos):
			alternatives.append({
				"direction": direction,
				"safety_score": 1.0 - _calculate_position_risk(next_pos)
			})
	
	return alternatives

## 辅助方法：统计险象环生次数
func _count_near_misses() -> int:
	# 简化实现：基于连续错误数估算
	return consecutive_errors * 2