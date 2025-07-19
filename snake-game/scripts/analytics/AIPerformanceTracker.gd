extends RefCounted
class_name AIPerformanceTracker

## AI性能追踪器 - 记录和分析AI的表现数据

signal performance_milestone_reached(milestone_name: String, data: Dictionary)
signal anomaly_detected(anomaly_type: String, data: Dictionary)

# 性能数据存储
var performance_data: Dictionary = {}
var session_data: Dictionary = {}
var historical_data: Array = []

# 当前会话追踪
var current_session: Dictionary = {}
var session_start_time: float = 0.0
var last_food_time: float = 0.0
var decision_times: Array = []
var risk_levels: Array = []

# 里程碑设置
var milestones: Dictionary = {
	"survival_time": [30, 60, 120, 300, 600],  # 秒
	"food_count": [5, 10, 25, 50, 100],
	"decision_count": [100, 500, 1000, 5000],
	"efficiency_rating": [0.5, 0.7, 0.8, 0.9, 0.95]
}

# 异常检测阈值
var anomaly_thresholds: Dictionary = {
	"decision_time_spike": 100.0,  # ms
	"risk_level_spike": 0.9,
	"food_miss_streak": 10,
	"direction_preference_bias": 0.8
}

## 初始化追踪器
func _init():
	_reset_session_data()
	_load_historical_data()

## 开始新会话
func start_new_session(difficulty: String = "normal"):
	_save_current_session()
	_reset_session_data()
	current_session["difficulty"] = difficulty
	current_session["start_time"] = Time.get_ticks_msec() / 1000.0
	session_start_time = current_session["start_time"]
	print("AI性能追踪: 新会话开始 - 难度: %s" % difficulty)

## 记录决策
func record_decision(decision_data: Dictionary):
	var decision_time = decision_data.get("decision_time", 0.0)
	var direction = decision_data.get("direction", Vector2.ZERO)
	var confidence = decision_data.get("confidence", 0.0)
	var reasoning = decision_data.get("reasoning", "")
	
	# 更新决策统计
	current_session["decisions_made"] = current_session.get("decisions_made", 0) + 1
	current_session["total_decision_time"] = current_session.get("total_decision_time", 0.0) + decision_time
	
	# 记录决策时间
	decision_times.append(decision_time)
	if decision_times.size() > 1000:  # 保持最近1000个决策
		decision_times.pop_front()
	
	# 更新方向偏好统计
	var direction_stats = current_session.get("direction_stats", {"UP": 0, "DOWN": 0, "LEFT": 0, "RIGHT": 0})
	var dir_name = _direction_to_string(direction)
	if dir_name in direction_stats:
		direction_stats[dir_name] += 1
	current_session["direction_stats"] = direction_stats
	
	# 记录置信度
	var confidence_levels = current_session.get("confidence_levels", [])
	confidence_levels.append(confidence)
	if confidence_levels.size() > 100:
		confidence_levels.pop_front()
	current_session["confidence_levels"] = confidence_levels
	
	# 异常检测
	_detect_decision_anomalies(decision_time, direction, confidence)
	
	# 检查里程碑
	_check_decision_milestones()

## 记录食物获取
func record_food_acquisition(food_data: Dictionary):
	var current_time = Time.get_ticks_msec() / 1000.0
	var food_position = food_data.get("position", Vector2.ZERO)
	var snake_length = food_data.get("snake_length", 1)
	
	# 更新食物统计
	current_session["food_acquired"] = current_session.get("food_acquired", 0) + 1
	
	# 计算食物获取间隔
	if last_food_time > 0:
		var interval = current_time - last_food_time
		var intervals = current_session.get("food_intervals", [])
		intervals.append(interval)
		if intervals.size() > 50:
			intervals.pop_front()
		current_session["food_intervals"] = intervals
	
	last_food_time = current_time
	
	# 记录蛇长度增长
	var length_history = current_session.get("length_history", [])
	length_history.append({"time": current_time, "length": snake_length})
	current_session["length_history"] = length_history
	
	# 重置错失计数
	current_session["food_miss_streak"] = 0
	
	# 检查里程碑
	_check_food_milestones()
	
	print("AI性能追踪: 食物获取 #%d, 蛇长度: %d" % [current_session["food_acquired"], snake_length])

## 记录险情
func record_near_miss(risk_data: Dictionary):
	var risk_level = risk_data.get("risk_level", 0.0)
	var risk_type = risk_data.get("risk_type", "unknown")
	var position = risk_data.get("position", Vector2.ZERO)
	
	# 更新险情统计
	current_session["near_misses"] = current_session.get("near_misses", 0) + 1
	
	# 记录风险水平
	risk_levels.append(risk_level)
	if risk_levels.size() > 200:
		risk_levels.pop_front()
	
	# 分类统计险情类型
	var risk_types = current_session.get("risk_types", {})
	risk_types[risk_type] = risk_types.get(risk_type, 0) + 1
	current_session["risk_types"] = risk_types
	
	# 异常检测
	if risk_level > anomaly_thresholds["risk_level_spike"]:
		anomaly_detected.emit("high_risk_situation", {
			"risk_level": risk_level,
			"risk_type": risk_type,
			"position": position
		})

## 记录游戏结束
func record_game_end(end_data: Dictionary):
	var end_time = Time.get_ticks_msec() / 1000.0
	var survival_time = end_time - session_start_time
	var cause_of_death = end_data.get("cause", "unknown")
	var final_score = end_data.get("score", 0)
	var final_length = end_data.get("length", 1)
	
	# 更新会话数据
	current_session["end_time"] = end_time
	current_session["survival_time"] = survival_time
	current_session["cause_of_death"] = cause_of_death
	current_session["final_score"] = final_score
	current_session["final_length"] = final_length
	current_session["games_played"] = current_session.get("games_played", 0) + 1
	
	# 计算效率指标
	_calculate_efficiency_metrics()
	
	# 检查生存时间里程碑
	_check_survival_milestones(survival_time)
	
	print("AI性能追踪: 游戏结束 - 生存: %.1fs, 得分: %d, 死因: %s" % [survival_time, final_score, cause_of_death])

## 记录错失食物
func record_food_miss(miss_data: Dictionary):
	var miss_reason = miss_data.get("reason", "unknown")
	var distance_to_food = miss_data.get("distance", 0.0)
	
	# 更新错失统计
	current_session["food_misses"] = current_session.get("food_misses", 0) + 1
	current_session["food_miss_streak"] = current_session.get("food_miss_streak", 0) + 1
	
	# 分类统计错失原因
	var miss_reasons = current_session.get("miss_reasons", {})
	miss_reasons[miss_reason] = miss_reasons.get(miss_reason, 0) + 1
	current_session["miss_reasons"] = miss_reasons
	
	# 检查连续错失异常
	if current_session["food_miss_streak"] >= anomaly_thresholds["food_miss_streak"]:
		anomaly_detected.emit("food_miss_streak", {
			"streak_length": current_session["food_miss_streak"],
			"last_miss_reason": miss_reason
		})

## 获取实时性能指标
func get_realtime_metrics() -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0
	var survival_time = current_time - session_start_time
	
	var metrics = {
		"survival_time": survival_time,
		"decisions_made": current_session.get("decisions_made", 0),
		"food_acquired": current_session.get("food_acquired", 0),
		"near_misses": current_session.get("near_misses", 0),
		"food_misses": current_session.get("food_misses", 0),
		"efficiency_rating": _calculate_current_efficiency(),
		"average_decision_time": _calculate_average_decision_time(),
		"average_risk_level": _calculate_average_risk_level(),
		"food_acquisition_rate": _calculate_food_acquisition_rate(survival_time),
		"direction_bias": _calculate_direction_bias()
	}
	
	return metrics

## 获取历史性能趋势
func get_performance_trends() -> Dictionary:
	if historical_data.size() < 2:
		return {}
	
	var trends = {
		"survival_time_trend": _calculate_trend("survival_time"),
		"efficiency_trend": _calculate_trend("efficiency_rating"),
		"food_rate_trend": _calculate_trend("food_acquisition_rate"),
		"decision_speed_trend": _calculate_trend("average_decision_time")
	}
	
	return trends

## 生成性能报告
func generate_performance_report() -> Dictionary:
	var report = {
		"session_summary": _get_session_summary(),
		"performance_metrics": get_realtime_metrics(),
		"historical_trends": get_performance_trends(),
		"achievement_progress": _get_achievement_progress(),
		"recommendations": _generate_recommendations()
	}
	
	return report

## 分析AI弱点
func analyze_weaknesses() -> Array:
	var weaknesses = []
	var metrics = get_realtime_metrics()
	
	# 决策速度问题
	if metrics.get("average_decision_time", 0) > 50.0:
		weaknesses.append({
			"type": "slow_decisions",
			"severity": "medium",
			"description": "决策速度较慢，可能影响反应时间",
			"suggestion": "优化决策算法或减少复杂度"
		})
	
	# 食物获取效率低
	if metrics.get("food_acquisition_rate", 0) < 0.1:
		weaknesses.append({
			"type": "low_food_efficiency",
			"severity": "high",
			"description": "食物获取效率偏低",
			"suggestion": "改进寻食算法和路径规划"
		})
	
	# 方向偏好过强
	var direction_bias = metrics.get("direction_bias", 0)
	if direction_bias > anomaly_thresholds["direction_preference_bias"]:
		weaknesses.append({
			"type": "direction_bias",
			"severity": "low",
			"description": "存在明显的方向偏好",
			"suggestion": "检查决策逻辑是否平衡"
		})
	
	# 高风险行为
	if metrics.get("average_risk_level", 0) > 0.7:
		weaknesses.append({
			"type": "high_risk_behavior",
			"severity": "high",
			"description": "平均风险水平过高",
			"suggestion": "增强安全性评估和风险规避"
		})
	
	# 连续错失食物
	if current_session.get("food_miss_streak", 0) > 5:
		weaknesses.append({
			"type": "food_miss_pattern",
			"severity": "medium",
			"description": "存在连续错失食物的模式",
			"suggestion": "检查寻食策略和障碍规避逻辑"
		})
	
	return weaknesses

## 私有方法

func _reset_session_data():
	current_session = {
		"start_time": 0.0,
		"decisions_made": 0,
		"food_acquired": 0,
		"near_misses": 0,
		"food_misses": 0,
		"food_miss_streak": 0,
		"games_played": 0,
		"direction_stats": {"UP": 0, "DOWN": 0, "LEFT": 0, "RIGHT": 0},
		"confidence_levels": [],
		"food_intervals": [],
		"length_history": [],
		"risk_types": {},
		"miss_reasons": {}
	}
	decision_times.clear()
	risk_levels.clear()
	last_food_time = 0.0

func _direction_to_string(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "UP"
	elif direction == Vector2.DOWN:
		return "DOWN"
	elif direction == Vector2.LEFT:
		return "LEFT"
	elif direction == Vector2.RIGHT:
		return "RIGHT"
	else:
		return "NONE"

func _detect_decision_anomalies(decision_time: float, direction: Vector2, confidence: float):
	# 决策时间异常
	if decision_time > anomaly_thresholds["decision_time_spike"]:
		anomaly_detected.emit("slow_decision", {
			"decision_time": decision_time,
			"direction": direction,
			"confidence": confidence
		})
	
	# 低置信度连续决策
	var recent_confidence = current_session.get("confidence_levels", [])
	if recent_confidence.size() >= 5:
		var recent_avg = 0.0
		for i in range(recent_confidence.size() - 5, recent_confidence.size()):
			recent_avg += recent_confidence[i]
		recent_avg /= 5.0
		
		if recent_avg < 0.3:
			anomaly_detected.emit("low_confidence_streak", {
				"average_confidence": recent_avg,
				"streak_length": 5
			})

func _check_decision_milestones():
	var decisions = current_session.get("decisions_made", 0)
	for milestone in milestones["decision_count"]:
		if decisions == milestone:
			performance_milestone_reached.emit("decision_milestone", {
				"milestone": milestone,
				"current_value": decisions
			})

func _check_food_milestones():
	var food_count = current_session.get("food_acquired", 0)
	for milestone in milestones["food_count"]:
		if food_count == milestone:
			performance_milestone_reached.emit("food_milestone", {
				"milestone": milestone,
				"current_value": food_count
			})

func _check_survival_milestones(survival_time: float):
	for milestone in milestones["survival_time"]:
		if survival_time >= milestone and survival_time < milestone + 1.0:  # 1秒容差
			performance_milestone_reached.emit("survival_milestone", {
				"milestone": milestone,
				"current_value": survival_time
			})

func _calculate_efficiency_metrics():
	var survival_time = current_session.get("survival_time", 0.0)
	var food_acquired = current_session.get("food_acquired", 0)
	var decisions_made = current_session.get("decisions_made", 1)
	var near_misses = current_session.get("near_misses", 0)
	
	# 食物获取效率
	var food_efficiency = food_acquired / max(1.0, survival_time / 60.0)  # 每分钟食物数
	
	# 决策效率
	var decision_efficiency = decisions_made / max(1.0, survival_time)  # 每秒决策数
	
	# 安全性评分
	var safety_score = max(0.0, 1.0 - (near_misses / max(1.0, decisions_made)))
	
	# 综合效率评分
	var efficiency_rating = (food_efficiency * 0.4 + safety_score * 0.4 + min(1.0, decision_efficiency / 2.0) * 0.2)
	
	current_session["food_efficiency"] = food_efficiency
	current_session["decision_efficiency"] = decision_efficiency
	current_session["safety_score"] = safety_score
	current_session["efficiency_rating"] = efficiency_rating
	
	# 检查效率里程碑
	for milestone in milestones["efficiency_rating"]:
		if efficiency_rating >= milestone:
			performance_milestone_reached.emit("efficiency_milestone", {
				"milestone": milestone,
				"current_value": efficiency_rating
			})

func _calculate_current_efficiency() -> float:
	if current_session.has("efficiency_rating"):
		return current_session["efficiency_rating"]
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var survival_time = current_time - session_start_time
	var food_acquired = current_session.get("food_acquired", 0)
	var decisions_made = current_session.get("decisions_made", 1)
	var near_misses = current_session.get("near_misses", 0)
	
	if survival_time <= 0:
		return 0.0
	
	var food_efficiency = food_acquired / max(1.0, survival_time / 60.0)
	var safety_score = max(0.0, 1.0 - (near_misses / max(1.0, decisions_made)))
	var decision_efficiency = decisions_made / survival_time
	
	return (food_efficiency * 0.4 + safety_score * 0.4 + min(1.0, decision_efficiency / 2.0) * 0.2)

func _calculate_average_decision_time() -> float:
	if decision_times.size() == 0:
		return 0.0
	
	var sum = 0.0
	for time in decision_times:
		sum += time
	
	return sum / decision_times.size()

func _calculate_average_risk_level() -> float:
	if risk_levels.size() == 0:
		return 0.0
	
	var sum = 0.0
	for level in risk_levels:
		sum += level
	
	return sum / risk_levels.size()

func _calculate_food_acquisition_rate(survival_time: float) -> float:
	if survival_time <= 0:
		return 0.0
	
	return current_session.get("food_acquired", 0) / survival_time

func _calculate_direction_bias() -> float:
	var direction_stats = current_session.get("direction_stats", {})
	var total_decisions = 0
	var max_count = 0
	
	for count in direction_stats.values():
		total_decisions += count
		max_count = max(max_count, count)
	
	if total_decisions == 0:
		return 0.0
	
	return float(max_count) / float(total_decisions)

func _calculate_trend(metric_name: String) -> float:
	if historical_data.size() < 3:
		return 0.0
	
	var recent_data = historical_data.slice(-5)  # 最近5个会话
	var values = []
	
	for session in recent_data:
		if session.has(metric_name):
			values.append(session[metric_name])
	
	if values.size() < 2:
		return 0.0
	
	# 简单线性趋势计算
	var sum_x = 0.0
	var sum_y = 0.0
	var sum_xy = 0.0
	var sum_x2 = 0.0
	var n = values.size()
	
	for i in range(n):
		var x = float(i)
		var y = values[i]
		sum_x += x
		sum_y += y
		sum_xy += x * y
		sum_x2 += x * x
	
	var slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
	return slope

func _get_session_summary() -> Dictionary:
	return {
		"session_duration": current_session.get("survival_time", 0.0),
		"games_played": current_session.get("games_played", 0),
		"total_decisions": current_session.get("decisions_made", 0),
		"total_food": current_session.get("food_acquired", 0),
		"total_near_misses": current_session.get("near_misses", 0),
		"final_length": current_session.get("final_length", 1),
		"cause_of_death": current_session.get("cause_of_death", "unknown")
	}

func _get_achievement_progress() -> Dictionary:
	var progress = {}
	var metrics = get_realtime_metrics()
	
	for category in milestones:
		var milestone_list = milestones[category]
		var current_value = 0.0
		
		match category:
			"survival_time":
				current_value = metrics.get("survival_time", 0.0)
			"food_count":
				current_value = metrics.get("food_acquired", 0)
			"decision_count":
				current_value = metrics.get("decisions_made", 0)
			"efficiency_rating":
				current_value = metrics.get("efficiency_rating", 0.0)
		
		var next_milestone = null
		for milestone in milestone_list:
			if current_value < milestone:
				next_milestone = milestone
				break
		
		progress[category] = {
			"current_value": current_value,
			"next_milestone": next_milestone,
			"progress_percentage": (current_value / next_milestone * 100.0) if next_milestone else 100.0
		}
	
	return progress

func _generate_recommendations() -> Array:
	var recommendations = []
	var weaknesses = analyze_weaknesses()
	var metrics = get_realtime_metrics()
	
	# 基于弱点生成建议
	for weakness in weaknesses:
		recommendations.append({
			"priority": weakness["severity"],
			"category": weakness["type"],
			"suggestion": weakness["suggestion"],
			"current_status": weakness["description"]
		})
	
	# 基于性能指标生成额外建议
	if metrics.get("food_acquisition_rate", 0) > 0.2:
		recommendations.append({
			"priority": "low",
			"category": "optimization",
			"suggestion": "考虑增加游戏难度以进一步挑战AI",
			"current_status": "食物获取效率良好"
		})
	
	if metrics.get("average_decision_time", 0) < 10.0:
		recommendations.append({
			"priority": "low",
			"category": "optimization",
			"suggestion": "决策速度优秀，可以增加决策复杂度",
			"current_status": "决策速度很快"
		})
	
	return recommendations

func _save_current_session():
	if current_session.has("start_time") and current_session["start_time"] > 0:
		historical_data.append(current_session.duplicate())
		if historical_data.size() > 100:  # 保持最近100个会话
			historical_data.pop_front()
		_save_historical_data()

func _load_historical_data():
	var file_path = "user://ai_performance_history.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			historical_data = json.data.get("sessions", [])
			print("AI性能追踪: 加载历史数据 - %d个会话" % historical_data.size())

func _save_historical_data():
	var file_path = "user://ai_performance_history.json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var data = {"sessions": historical_data}
		file.store_string(JSON.stringify(data))
		file.close()

## 导出性能数据
func export_performance_data(file_path: String):
	var export_data = {
		"current_session": current_session,
		"historical_data": historical_data,
		"performance_report": generate_performance_report(),
		"export_time": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data, "\t"))
		file.close()
		print("AI性能数据已导出到: %s" % file_path) 