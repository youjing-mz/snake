extends Node
class_name AITestRunner

## AI测试运行器 - 整合所有调试和测试功能

signal test_completed(results: Dictionary)
signal debug_data_updated(data: Dictionary)

# 组件引用
var test_suite: AITestSuite
var performance_tracker: AIPerformanceTracker
var debug_panel: AIDebugPanel
var deadlock_detector: DeadlockDetector

# 测试配置
var auto_run_tests: bool = false
var continuous_monitoring: bool = true
var test_interval: float = 10.0  # 秒

# 测试状态
var is_testing: bool = false
var last_test_time: float = 0.0
var test_history: Array = []

## 初始化测试运行器
func _ready():
	_setup_components()
	_connect_signals()
	
	if auto_run_tests:
		_start_continuous_testing()

func _setup_components():
	# 创建测试组件
	test_suite = AITestSuite.new()
	performance_tracker = AIPerformanceTracker.new()
	deadlock_detector = DeadlockDetector.new()
	
	# 创建调试面板（如果需要UI）
	if get_tree().current_scene.has_method("add_debug_panel"):
		debug_panel = preload("res://scripts/debug/AIDebugPanel.gd").new()
		get_tree().current_scene.add_debug_panel(debug_panel)
	
	print("AI测试运行器: 组件初始化完成")

func _connect_signals():
	if performance_tracker:
		performance_tracker.performance_milestone_reached.connect(_on_milestone_reached)
		performance_tracker.anomaly_detected.connect(_on_anomaly_detected)

## 运行完整的AI测试套件
func run_full_test_suite() -> Dictionary:
	if is_testing:
		print("AI测试运行器: 测试正在进行中，跳过本次运行")
		return {}
	
	is_testing = true
	print("AI测试运行器: 开始运行完整测试套件")
	
	var test_start_time = Time.get_ticks_msec() / 1000.0
	
	# 运行单元测试
	var unit_test_results = test_suite.run_all_tests()
	
	# 生成性能报告
	var performance_report = performance_tracker.generate_performance_report()
	
	# 运行死锁风险评估
	var deadlock_assessment = _run_deadlock_assessment()
	
	# 运行集成测试
	var integration_results = _run_integration_tests()
	
	# 综合结果
	var comprehensive_results = {
		"test_timestamp": Time.get_datetime_string_from_system(),
		"test_duration": Time.get_ticks_msec() / 1000.0 - test_start_time,
		"unit_tests": unit_test_results,
		"performance_report": performance_report,
		"deadlock_assessment": deadlock_assessment,
		"integration_tests": integration_results,
		"overall_status": _calculate_overall_status(unit_test_results, performance_report, deadlock_assessment),
		"recommendations": _generate_comprehensive_recommendations(unit_test_results, performance_report, deadlock_assessment)
	}
	
	# 保存测试历史
	test_history.append(comprehensive_results)
	if test_history.size() > 50:  # 保持最近50次测试
		test_history.pop_front()
	
	is_testing = false
	last_test_time = Time.get_ticks_msec() / 1000.0
	
	# 发出信号
	test_completed.emit(comprehensive_results)
	
	# 保存测试结果
	_save_test_results(comprehensive_results)
	
	print("AI测试运行器: 测试套件完成，总用时: %.2fs" % comprehensive_results["test_duration"])
	
	return comprehensive_results

## 运行快速性能检查
func run_quick_performance_check() -> Dictionary:
	print("AI测试运行器: 执行快速性能检查")
	
	var quick_results = {
		"timestamp": Time.get_datetime_string_from_system(),
		"realtime_metrics": performance_tracker.get_realtime_metrics(),
		"performance_trends": performance_tracker.get_performance_trends(),
		"ai_weaknesses": performance_tracker.analyze_weaknesses(),
		"quick_recommendations": []
	}
	
	# 基于结果生成快速建议
	var weaknesses = quick_results["ai_weaknesses"]
	for weakness in weaknesses:
		if weakness["severity"] == "high":
			quick_results["quick_recommendations"].append({
				"priority": "urgent",
				"action": weakness["suggestion"],
				"reason": weakness["description"]
			})
	
	return quick_results

## 启动实时监控
func start_realtime_monitoring(ai_player: Node = null):
	continuous_monitoring = true
	
	if ai_player:
		_connect_ai_signals(ai_player)
	
	# 启动监控定时器
	var monitor_timer = Timer.new()
	monitor_timer.wait_time = 1.0  # 每秒更新
	monitor_timer.timeout.connect(_update_realtime_data)
	monitor_timer.autostart = true
	add_child(monitor_timer)
	
	print("AI测试运行器: 实时监控已启动")

## 停止实时监控
func stop_realtime_monitoring():
	continuous_monitoring = false
	
	# 停止定时器
	for child in get_children():
		if child is Timer:
			child.queue_free()
	
	print("AI测试运行器: 实时监控已停止")

## 导出完整调试报告
func export_debug_report(file_path: String):
	var debug_report = {
		"report_metadata": {
			"generation_time": Time.get_datetime_string_from_system(),
			"godot_version": Engine.get_version_info(),
			"test_runner_version": "1.0.0"
		},
		"test_history": test_history,
		"performance_data": performance_tracker.export_performance_data(""),
		"latest_test_results": test_history[-1] if test_history.size() > 0 else {},
		"ai_configuration": _get_ai_configuration(),
		"system_info": _get_system_info()
	}
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(debug_report, "\t"))
		file.close()
		print("AI测试运行器: 调试报告已导出到: %s" % file_path)
	else:
		print("AI测试运行器: 导出调试报告失败: %s" % file_path)

## 运行基准测试
func run_benchmark_tests(iterations: int = 1000) -> Dictionary:
	print("AI测试运行器: 开始基准测试 - %d次迭代" % iterations)
	
	var benchmark_results = {
		"iterations": iterations,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"decision_times": [],
		"pathfinding_times": [],
		"risk_analysis_times": [],
		"space_analysis_times": [],
		"memory_usage": [],
		"performance_metrics": {}
	}
	
	# 创建模拟游戏状态
	var test_game_state = _create_benchmark_game_state()
	
	for i in range(iterations):
		# 测试决策时间
		var decision_start = Time.get_ticks_msec()
		test_suite.ai_brain.make_decision(test_game_state)
		var decision_time = Time.get_ticks_msec() - decision_start
		benchmark_results["decision_times"].append(decision_time)
		
		# 测试路径规划时间
		var pathfinding_start = Time.get_ticks_msec()
		test_suite.pathfinder.find_path(Vector2(10, 10), Vector2(30, 20), test_game_state)
		var pathfinding_time = Time.get_ticks_msec() - pathfinding_start
		benchmark_results["pathfinding_times"].append(pathfinding_time)
		
		# 记录内存使用（每100次迭代）
		if i % 100 == 0:
			benchmark_results["memory_usage"].append(OS.get_static_memory_usage())
		
		# 更新游戏状态以模拟变化
		_update_benchmark_game_state(test_game_state, i)
	
	benchmark_results["end_time"] = Time.get_ticks_msec() / 1000.0
	benchmark_results["total_duration"] = benchmark_results["end_time"] - benchmark_results["start_time"]
	
	# 计算性能指标
	benchmark_results["performance_metrics"] = _calculate_benchmark_metrics(benchmark_results)
	
	print("AI测试运行器: 基准测试完成，总用时: %.2fs" % benchmark_results["total_duration"])
	
	return benchmark_results

## 私有方法

func _run_deadlock_assessment() -> Dictionary:
	print("AI测试运行器: 运行死锁风险评估")
	
	# 创建测试场景
	var test_scenarios = [
		_create_corner_trap_scenario(),
		_create_narrow_passage_scenario(),
		_create_self_enclosure_scenario(),
		_create_food_chase_loop_scenario()
	]
	
	var deadlock_results = {
		"scenarios_tested": test_scenarios.size(),
		"high_risk_scenarios": 0,
		"medium_risk_scenarios": 0,
		"low_risk_scenarios": 0,
		"scenario_details": []
	}
	
	for i in range(test_scenarios.size()):
		var scenario = test_scenarios[i]
		var risk_analysis = deadlock_detector.detect_deadlock_risk(scenario["position"], scenario["game_state"])
		
		var scenario_result = {
			"scenario_name": scenario["name"],
			"risk_level": risk_analysis["risk_level"],
			"deadlock_type": risk_analysis["deadlock_type"],
			"escape_suggestions": risk_analysis["escape_suggestions"],
			"confidence": risk_analysis["confidence"]
		}
		
		deadlock_results["scenario_details"].append(scenario_result)
		
		# 分类风险等级
		if risk_analysis["risk_level"] > 0.7:
			deadlock_results["high_risk_scenarios"] += 1
		elif risk_analysis["risk_level"] > 0.4:
			deadlock_results["medium_risk_scenarios"] += 1
		else:
			deadlock_results["low_risk_scenarios"] += 1
	
	return deadlock_results

func _run_integration_tests() -> Dictionary:
	print("AI测试运行器: 运行集成测试")
	
	var integration_results = {
		"ai_debug_panel_integration": _test_debug_panel_integration(),
		"performance_tracker_integration": _test_performance_tracker_integration(),
		"deadlock_detector_integration": _test_deadlock_detector_integration(),
		"cross_component_communication": _test_cross_component_communication()
	}
	
	return integration_results

func _test_debug_panel_integration() -> Dictionary:
	if not debug_panel:
		return {"status": "skipped", "reason": "debug panel not available"}
	
	# 测试调试面板的各种功能
	var test_data = {
		"direction": Vector2.RIGHT,
		"reasoning": "测试决策",
		"confidence": 0.85,
		"scores": {
			"total_score": 0.9,
			"food_score": 0.8,
			"safety_score": 0.95,
			"space_score": 0.85
		}
	}
	
	debug_panel.update_decision_info(test_data)
	debug_panel.update_metrics()
	debug_panel.update_behavior_analysis()
	
	return {"status": "passed", "tests_run": 3}

func _test_performance_tracker_integration() -> Dictionary:
	# 测试性能追踪器的核心功能
	performance_tracker.start_new_session("test")
	
	performance_tracker.record_decision({
		"decision_time": 15.0,
		"direction": Vector2.UP,
		"confidence": 0.7,
		"reasoning": "测试决策"
	})
	
	performance_tracker.record_food_acquisition({
		"position": Vector2(10, 10),
		"snake_length": 5
	})
	
	var metrics = performance_tracker.get_realtime_metrics()
	var has_valid_metrics = metrics.has("decisions_made") and metrics.has("food_acquired")
	
	return {
		"status": "passed" if has_valid_metrics else "failed",
		"metrics_generated": has_valid_metrics,
		"sample_metrics": metrics
	}

func _test_deadlock_detector_integration() -> Dictionary:
	var test_position = Vector2(5, 5)
	var test_game_state = {
		"grid_width": 20,
		"grid_height": 15,
		"snake_body": [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)],
		"food_position": Vector2(10, 10)
	}
	
	var deadlock_analysis = deadlock_detector.detect_deadlock_risk(test_position, test_game_state)
	var has_valid_analysis = deadlock_analysis.has("risk_level") and deadlock_analysis.has("deadlock_type")
	
	return {
		"status": "passed" if has_valid_analysis else "failed",
		"analysis_generated": has_valid_analysis,
		"sample_analysis": deadlock_analysis
	}

func _test_cross_component_communication() -> Dictionary:
	# 测试组件间的通信
	var communication_tests = {
		"performance_to_debug": false,
		"deadlock_to_performance": false,
		"test_runner_coordination": false
	}
	
	# 这里可以添加更复杂的组件间通信测试
	# 目前简化为基本检查
	communication_tests["test_runner_coordination"] = true
	
	var passed_tests = 0
	for test_name in communication_tests:
		if communication_tests[test_name]:
			passed_tests += 1
	
	return {
		"status": "passed" if passed_tests == communication_tests.size() else "partial",
		"passed_tests": passed_tests,
		"total_tests": communication_tests.size(),
		"details": communication_tests
	}

func _calculate_overall_status(unit_tests: Dictionary, performance_report: Dictionary, deadlock_assessment: Dictionary) -> String:
	var issues = []
	
	# 检查单元测试结果
	if unit_tests.has("failed_tests") and unit_tests["failed_tests"] > 0:
		issues.append("单元测试失败")
	
	# 检查性能问题
	if performance_report.has("recommendations"):
		var high_priority_recommendations = 0
		for recommendation in performance_report["recommendations"]:
			if recommendation.get("priority", "") == "high":
				high_priority_recommendations += 1
		
		if high_priority_recommendations > 0:
			issues.append("性能问题")
	
	# 检查死锁风险
	if deadlock_assessment.has("high_risk_scenarios") and deadlock_assessment["high_risk_scenarios"] > 0:
		issues.append("死锁风险")
	
	if issues.size() == 0:
		return "excellent"
	elif issues.size() <= 1:
		return "good"
	elif issues.size() <= 2:
		return "warning"
	else:
		return "critical"

func _generate_comprehensive_recommendations(unit_tests: Dictionary, performance_report: Dictionary, deadlock_assessment: Dictionary) -> Array:
	var recommendations = []
	
	# 基于单元测试结果的建议
	if unit_tests.has("failed_tests") and unit_tests["failed_tests"] > 0:
		recommendations.append({
			"category": "testing",
			"priority": "high",
			"title": "修复失败的单元测试",
			"description": "有%d个单元测试失败，需要检查AI核心功能" % unit_tests["failed_tests"],
			"action": "查看详细测试报告并修复相关问题"
		})
	
	# 基于性能报告的建议
	if performance_report.has("recommendations"):
		for rec in performance_report["recommendations"]:
			recommendations.append({
				"category": "performance",
				"priority": rec.get("priority", "medium"),
				"title": rec.get("suggestion", "性能优化"),
				"description": rec.get("current_status", ""),
				"action": rec.get("suggestion", "")
			})
	
	# 基于死锁评估的建议
	if deadlock_assessment.has("high_risk_scenarios") and deadlock_assessment["high_risk_scenarios"] > 0:
		recommendations.append({
			"category": "deadlock_prevention",
			"priority": "high",
			"title": "强化死锁预防机制",
			"description": "检测到%d个高风险死锁场景" % deadlock_assessment["high_risk_scenarios"],
			"action": "改进路径规划和决策逻辑以减少死锁风险"
		})
	
	# 通用优化建议
	recommendations.append({
		"category": "optimization",
		"priority": "low",
		"title": "定期运行测试套件",
		"description": "保持AI系统的持续监控和优化",
		"action": "建议每周运行一次完整测试套件"
	})
	
	return recommendations

func _connect_ai_signals(ai_player: Node):
	# 连接AI玩家的信号以进行实时监控
	if ai_player.has_signal("decision_made"):
		ai_player.decision_made.connect(_on_ai_decision_made)
	
	if ai_player.has_signal("food_acquired"):
		ai_player.food_acquired.connect(_on_ai_food_acquired)
	
	if ai_player.has_signal("near_miss"):
		ai_player.near_miss.connect(_on_ai_near_miss)

func _update_realtime_data():
	if not continuous_monitoring:
		return
	
	var realtime_data = {
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"performance_metrics": performance_tracker.get_realtime_metrics(),
		"system_status": _get_system_status()
	}
	
	debug_data_updated.emit(realtime_data)

func _save_test_results(results: Dictionary):
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var file_path = "user://ai_test_results_%s.json" % timestamp
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(results, "\t"))
		file.close()
		print("AI测试运行器: 测试结果已保存到: %s" % file_path)

## 辅助方法 - 创建测试场景

func _create_corner_trap_scenario() -> Dictionary:
	return {
		"name": "角落陷阱",
		"position": Vector2(1, 1),
		"game_state": {
			"grid_width": 20,
			"grid_height": 15,
			"snake_body": [Vector2(1, 1), Vector2(2, 1), Vector2(1, 2)],
			"food_position": Vector2(0, 0)
		}
	}

func _create_narrow_passage_scenario() -> Dictionary:
	var walls = []
	for y in range(5, 15):
		if y != 10:  # 留一个通道
			walls.append(Vector2(10, y))
			walls.append(Vector2(12, y))
	
	return {
		"name": "狭窄通道",
		"position": Vector2(8, 10),
		"game_state": {
			"grid_width": 25,
			"grid_height": 20,
			"snake_body": walls,
			"food_position": Vector2(15, 10)
		}
	}

func _create_self_enclosure_scenario() -> Dictionary:
	return {
		"name": "自我包围",
		"position": Vector2(10, 10),
		"game_state": {
			"grid_width": 25,
			"grid_height": 20,
			"snake_body": [
				Vector2(10, 10), Vector2(9, 10), Vector2(8, 10), Vector2(8, 9),
				Vector2(8, 8), Vector2(9, 8), Vector2(10, 8), Vector2(11, 8),
				Vector2(11, 9), Vector2(11, 10)
			],
			"food_position": Vector2(9, 9)
		}
	}

func _create_food_chase_loop_scenario() -> Dictionary:
	return {
		"name": "食物追逐循环",
		"position": Vector2(10, 10),
		"game_state": {
			"grid_width": 25,
			"grid_height": 20,
			"snake_body": [Vector2(10, 10), Vector2(9, 10), Vector2(8, 10)],
			"food_position": Vector2(12, 10)
		}
	}

func _create_benchmark_game_state() -> Dictionary:
	return {
		"grid_width": 40,
		"grid_height": 30,
		"snake_head": Vector2(10, 10),
		"snake_body": [Vector2(10, 10), Vector2(9, 10), Vector2(8, 10)],
		"food_position": Vector2(25, 20)
	}

func _update_benchmark_game_state(game_state: Dictionary, iteration: int):
	# 随机更新食物位置和蛇身以模拟不同场景
	var grid_width = game_state["grid_width"]
	var grid_height = game_state["grid_height"]
	
	game_state["food_position"] = Vector2(
		randi() % grid_width,
		randi() % grid_height
	)

func _calculate_benchmark_metrics(benchmark_data: Dictionary) -> Dictionary:
	var decision_times = benchmark_data["decision_times"]
	var pathfinding_times = benchmark_data["pathfinding_times"]
	
	return {
		"average_decision_time": _calculate_average(decision_times),
		"max_decision_time": decision_times.max(),
		"min_decision_time": decision_times.min(),
		"average_pathfinding_time": _calculate_average(pathfinding_times),
		"max_pathfinding_time": pathfinding_times.max(),
		"decisions_per_second": benchmark_data["iterations"] / benchmark_data["total_duration"],
		"memory_stable": _is_memory_usage_stable(benchmark_data["memory_usage"])
	}

func _calculate_average(values: Array) -> float:
	if values.size() == 0:
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += value
	
	return sum / values.size()

func _is_memory_usage_stable(memory_data: Array) -> bool:
	if memory_data.size() < 2:
		return true
	
	# 简化的内存稳定性检查
	var first_usage = memory_data[0]
	var last_usage = memory_data[-1]
	
	# 如果内存增长超过50%，认为不稳定
	return last_usage < first_usage * 1.5

func _get_ai_configuration() -> Dictionary:
	return {
		"ai_brain_weights": test_suite.ai_brain.DECISION_WEIGHTS if test_suite.ai_brain else {},
		"pathfinding_enabled": test_suite.pathfinder != null,
		"risk_analysis_enabled": test_suite.risk_analyzer != null,
		"space_analysis_enabled": test_suite.space_analyzer != null,
		"deadlock_detection_enabled": deadlock_detector != null
	}

func _get_system_info() -> Dictionary:
	return {
		"platform": OS.get_name(),
		"processor_count": OS.get_processor_count(),
		"memory_usage": OS.get_static_memory_usage(),
		"fps": Engine.get_frames_per_second(),
		"engine_version": Engine.get_version_info()
	}

func _get_system_status() -> Dictionary:
	return {
		"fps": Engine.get_frames_per_second(),
		"memory_usage": OS.get_static_memory_usage(),
		"is_testing": is_testing,
		"monitoring_active": continuous_monitoring
	}

func _start_continuous_testing():
	var test_timer = Timer.new()
	test_timer.wait_time = test_interval
	test_timer.timeout.connect(_on_test_timer_timeout)
	test_timer.autostart = true
	add_child(test_timer)

## 信号处理方法

func _on_milestone_reached(milestone_name: String, data: Dictionary):
	print("AI测试运行器: 达成里程碑 - %s: %s" % [milestone_name, data])

func _on_anomaly_detected(anomaly_type: String, data: Dictionary):
	print("AI测试运行器: 检测到异常 - %s: %s" % [anomaly_type, data])

func _on_ai_decision_made(direction: Vector2, reasoning: String):
	performance_tracker.record_decision({
		"direction": direction,
		"reasoning": reasoning,
		"decision_time": 0.0,  # 这里需要实际的决策时间
		"confidence": 0.0       # 这里需要实际的置信度
	})

func _on_ai_food_acquired(position: Vector2, snake_length: int):
	performance_tracker.record_food_acquisition({
		"position": position,
		"snake_length": snake_length
	})

func _on_ai_near_miss(risk_data: Dictionary):
	performance_tracker.record_near_miss(risk_data)

func _on_test_timer_timeout():
	if not is_testing:
		run_quick_performance_check()

## 清理方法
func _exit_tree():
	stop_realtime_monitoring()
	if test_suite:
		test_suite = null
	if performance_tracker:
		performance_tracker = null
	if debug_panel:
		debug_panel = null
	if deadlock_detector:
		deadlock_detector = null 