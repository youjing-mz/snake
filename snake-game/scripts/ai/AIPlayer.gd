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
		"food_priority": 1.0,
		"decision_weights": {
			"safety": 0.7,
			"food_distance": 1.0,
			"space_available": 0.8,
			"future_safety": 1.2
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

# 性能统计
var start_time: float = 0.0
var survival_time: float = 0.0
var score: int = 0
var foods_eaten: int = 0
var total_moves: int = 0
var successful_moves: int = 0

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

## 获取当前游戏状态
func _get_current_game_state() -> Dictionary:
	if not ai_snake:
		return {}
	
	# 获取网格信息
	var grid_size = Constants.get_grid_size()
	
	# 构建游戏状态字典
	var game_state = {
		"snake_head": ai_snake.get_head_position(),
		"snake_body": ai_snake.get_body_positions(),
		"current_direction": ai_snake.get_direction(),
		"grid_width": grid_size.x,
		"grid_height": grid_size.y
	}
	
	# 获取食物位置（从游戏场景中）
	var food = get_tree().get_first_node_in_group("food")
	if food and food.has_method("get_current_position"):
		game_state["food_position"] = food.get_current_position()
	else:
		game_state["food_position"] = Vector2(-1, -1)
	
	return game_state

## 重置统计数据
func _reset_stats() -> void:
	survival_time = 0.0
	score = 0
	foods_eaten = 0
	total_moves = 0
	successful_moves = 0
	consecutive_errors = 0

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
	
	# 检查是否应该产生错误
	var final_direction = direction
	if _should_make_error():
		final_direction = _generate_error_direction(direction)
		consecutive_errors += 1
		last_error_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		print("AIPlayer: Made error - chose ", final_direction, " instead of ", direction)
	else:
		successful_moves += 1
		consecutive_errors = 0
	
	# 执行决策
	if ai_snake.has_method("set_direction"):
		ai_snake.set_direction(final_direction)
	
	# 发送决策信号
	ai_decision_made.emit(final_direction, reasoning)
	
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