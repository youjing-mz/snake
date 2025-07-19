extends RefCounted
class_name AITestSuite

## AI测试套件 - 系统性测试AI在各种场景下的表现

# 测试结果存储
var test_results: Dictionary = {}
var current_test_name: String = ""

# AI组件引用
var ai_brain: AIBrain
var pathfinder: PathFinder
var risk_analyzer: RiskAnalyzer
var space_analyzer: SpaceAnalyzer

# 测试统计
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

## 初始化测试套件
func _init():
	_setup_ai_components()

func _setup_ai_components():
	ai_brain = AIBrain.new()
	pathfinder = PathFinder.new()
	risk_analyzer = RiskAnalyzer.new()
	space_analyzer = SpaceAnalyzer.new()
	
	# 设置依赖关系
	ai_brain.pathfinder = pathfinder
	ai_brain.risk_analyzer = risk_analyzer
	ai_brain.space_analyzer = space_analyzer

## 运行所有测试
func run_all_tests() -> Dictionary:
	print("=== AI测试套件开始 ===")
	_reset_test_stats()
	
	# 基础功能测试
	_test_pathfinding()
	_test_risk_assessment()
	_test_space_analysis()
	_test_decision_making()
	
	# 场景测试
	_test_food_seeking_scenarios()
	_test_danger_avoidance_scenarios()
	_test_confined_space_scenarios()
	_test_edge_case_scenarios()
	
	# 性能测试
	_test_performance_benchmarks()
	
	# 集成测试
	_test_ai_integration()
	
	_print_test_summary()
	return test_results

## 基础功能测试

## 测试路径规划
func _test_pathfinding():
	_start_test("路径规划测试")
	
	# 测试1: 直线路径
	var result1 = _test_straight_path()
	_assert_test("直线路径", result1, "AI应能规划简单直线路径")
	
	# 测试2: 绕障路径
	var result2 = _test_obstacle_avoidance_path()
	_assert_test("绕障路径", result2, "AI应能规划绕过障碍物的路径")
	
	# 测试3: 复杂路径
	var result3 = _test_complex_path()
	_assert_test("复杂路径", result3, "AI应能规划复杂环境下的路径")
	
	# 测试4: 无路径情况
	var result4 = _test_no_path_scenario()
	_assert_test("无路径处理", result4, "AI应能正确处理无路径情况")

func _test_straight_path() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_head"] = Vector2(5, 5)
	game_state["food_position"] = Vector2(10, 5)
	
	var path = pathfinder.find_path(Vector2(5, 5), Vector2(10, 5), game_state)
	
	# 验证路径正确性
	if path.size() != 5:  # 应该是5步
		return false
	
	# 验证路径方向正确
	for i in range(path.size()):
		if path[i] != Vector2(6 + i, 5):
			return false
	
	return true

func _test_obstacle_avoidance_path() -> bool:
	var game_state = _create_game_state_with_obstacles()
	game_state["snake_head"] = Vector2(5, 5)
	game_state["food_position"] = Vector2(10, 5)
	game_state["snake_body"] = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]  # 蛇身在左侧
	
	# 在中间放置障碍
	for y in range(3, 8):
		game_state["snake_body"].append(Vector2(7, y))
	
	var path = pathfinder.find_path(Vector2(5, 5), Vector2(10, 5), game_state)
	
	# 应该能找到路径（绕过障碍）
	return path.size() > 0

func _test_complex_path() -> bool:
	var game_state = _create_complex_maze_state()
	var path = pathfinder.find_path(Vector2(1, 1), Vector2(18, 18), game_state)
	
	# 在复杂迷宫中应该能找到路径
	return path.size() > 0

func _test_no_path_scenario() -> bool:
	var game_state = _create_blocked_game_state()
	var path = pathfinder.find_path(Vector2(5, 5), Vector2(10, 10), game_state)
	
	# 完全封闭的情况下应该返回空路径
	return path.size() == 0

## 测试风险评估
func _test_risk_assessment():
	_start_test("风险评估测试")
	
	# 测试1: 边界风险
	var result1 = _test_border_risk()
	_assert_test("边界风险评估", result1, "AI应能正确评估边界风险")
	
	# 测试2: 身体碰撞风险
	var result2 = _test_body_collision_risk()
	_assert_test("身体碰撞风险", result2, "AI应能评估与自身碰撞的风险")
	
	# 测试3: 未来风险预测
	var result3 = _test_future_risk_prediction()
	_assert_test("未来风险预测", result3, "AI应能预测未来几步的风险")

func _test_border_risk() -> bool:
	var game_state = _create_simple_game_state()
	
	# 测试靠近边界的风险
	var risk_high = risk_analyzer.analyze_border_safety(Vector2(0, 0), game_state)
	var risk_center = risk_analyzer.analyze_border_safety(Vector2(10, 10), game_state)
	
	# 边界风险应该比中心风险高
	return risk_high < risk_center

func _test_body_collision_risk() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_body"] = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
	
	# 测试靠近蛇身的风险
	var risk_near_body = risk_analyzer.analyze_body_safety(Vector2(2, 5), game_state)
	var risk_away_from_body = risk_analyzer.analyze_body_safety(Vector2(10, 10), game_state)
	
	# 靠近蛇身的风险应该更高
	return risk_near_body < risk_away_from_body

func _test_future_risk_prediction() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_body"] = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
	
	# 测试向危险方向移动的未来风险
	var future_risk = risk_analyzer.predict_future_risk(Vector2(5, 5), Vector2.LEFT, game_state, 3)
	
	# 向蛇身方向移动应该有高风险
	return future_risk < 0.5  # 高风险 = 低评分

## 测试空间分析
func _test_space_analysis():
	_start_test("空间分析测试")
	
	# 测试1: 可达空间计算
	var result1 = _test_reachable_space_calculation()
	_assert_test("可达空间计算", result1, "AI应能正确计算可达空间")
	
	# 测试2: 连通性分析
	var result2 = _test_connectivity_analysis()
	_assert_test("连通性分析", result2, "AI应能分析空间连通性")

func _test_reachable_space_calculation() -> bool:
	var game_state = _create_simple_game_state()
	var reachable_space = space_analyzer.calculate_reachable_space(Vector2(10, 10), game_state)
	
	# 在空旷区域应该有足够的可达空间
	return reachable_space > 100

func _test_connectivity_analysis() -> bool:
	var game_state = _create_simple_game_state()
	var connectivity = space_analyzer.analyze_connectivity(Vector2(10, 10), game_state)
	
	# 应该有多个连通的区域
	return connectivity > 0.5

## 测试决策制定
func _test_decision_making():
	_start_test("决策制定测试")
	
	# 测试1: 食物优先级
	var result1 = _test_food_priority_decision()
	_assert_test("食物优先级决策", result1, "AI应优先选择朝向食物的方向")
	
	# 测试2: 安全优先级
	var result2 = _test_safety_priority_decision()
	_assert_test("安全优先级决策", result2, "AI应在危险时优先选择安全方向")
	
	# 测试3: 平衡决策
	var result3 = _test_balanced_decision()
	_assert_test("平衡决策", result3, "AI应能平衡各种因素做出决策")

func _test_food_priority_decision() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_head"] = Vector2(10, 10)
	game_state["food_position"] = Vector2(10, 8)  # 食物在上方
	game_state["snake_body"] = [Vector2(10, 10), Vector2(10, 11)]  # 蛇身在下方
	
	var decision = ai_brain.make_decision(game_state)
	
	# 应该选择向上移动（朝向食物）
	return decision == Vector2.UP

func _test_safety_priority_decision() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_head"] = Vector2(1, 1)  # 靠近边界
	game_state["food_position"] = Vector2(0, 1)  # 食物在边界上
	game_state["snake_body"] = [Vector2(1, 1), Vector2(2, 1)]  # 蛇身在右侧
	
	var decision = ai_brain.make_decision(game_state)
	
	# 应该选择安全方向而不是直接朝向食物
	return decision != Vector2.LEFT  # 不应该向左（撞墙）

func _test_balanced_decision() -> bool:
	var game_state = _create_balanced_scenario()
	var decision = ai_brain.make_decision(game_state)
	
	# 应该能做出一个合理的决策（不是Vector2.ZERO）
	return decision != Vector2.ZERO

## 场景测试

## 测试寻食场景
func _test_food_seeking_scenarios():
	_start_test("寻食场景测试")
	
	# 测试1: 直接寻食
	var result1 = _test_direct_food_seeking()
	_assert_test("直接寻食", result1, "AI应能直接朝向食物")
	
	# 测试2: 绕路寻食
	var result2 = _test_detour_food_seeking()
	_assert_test("绕路寻食", result2, "AI应能绕过障碍寻找食物")
	
	# 测试3: 远距离寻食
	var result3 = _test_long_distance_food_seeking()
	_assert_test("远距离寻食", result3, "AI应能寻找远距离的食物")

func _test_direct_food_seeking() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_head"] = Vector2(10, 10)
	game_state["food_position"] = Vector2(12, 10)
	
	var decision = ai_brain.make_decision(game_state)
	return decision == Vector2.RIGHT

func _test_detour_food_seeking() -> bool:
	var game_state = _create_game_state_with_obstacles()
	game_state["snake_head"] = Vector2(5, 5)
	game_state["food_position"] = Vector2(8, 5)
	
	# 在中间放置障碍
	game_state["snake_body"] = [Vector2(5, 5), Vector2(4, 5), Vector2(6, 5), Vector2(7, 5)]
	
	var decision = ai_brain.make_decision(game_state)
	
	# 应该选择绕路方向
	return decision == Vector2.UP or decision == Vector2.DOWN

func _test_long_distance_food_seeking() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_head"] = Vector2(5, 5)
	game_state["food_position"] = Vector2(25, 25)
	
	var decision = ai_brain.make_decision(game_state)
	
	# 应该朝向食物的大致方向
	return decision == Vector2.RIGHT or decision == Vector2.DOWN

## 测试危险规避场景
func _test_danger_avoidance_scenarios():
	_start_test("危险规避场景测试")
	
	var result1 = _test_wall_avoidance()
	_assert_test("墙壁规避", result1, "AI应能避免撞墙")
	
	var result2 = _test_self_collision_avoidance()
	_assert_test("自撞规避", result2, "AI应能避免撞到自己")
	
	var result3 = _test_corner_escape()
	_assert_test("角落逃脱", result3, "AI应能从角落中逃脱")

func _test_wall_avoidance() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_head"] = Vector2(0, 5)  # 在左边界
	
	var decision = ai_brain.make_decision(game_state)
	return decision != Vector2.LEFT  # 不应该向左撞墙

func _test_self_collision_avoidance() -> bool:
	var game_state = _create_simple_game_state()
	game_state["snake_head"] = Vector2(5, 5)
	game_state["snake_body"] = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
	
	var decision = ai_brain.make_decision(game_state)
	return decision != Vector2.LEFT  # 不应该向左撞到自己

func _test_corner_escape() -> bool:
	var game_state = _create_corner_scenario()
	var decision = ai_brain.make_decision(game_state)
	
	# 应该能找到逃脱方向
	return decision != Vector2.ZERO

## 测试受限空间场景
func _test_confined_space_scenarios():
	_start_test("受限空间场景测试")
	
	var result1 = _test_narrow_passage()
	_assert_test("狭窄通道", result1, "AI应能通过狭窄通道")
	
	var result2 = _test_maze_navigation()
	_assert_test("迷宫导航", result2, "AI应能在迷宫中导航")

func _test_narrow_passage() -> bool:
	var game_state = _create_narrow_passage_scenario()
	var decision = ai_brain.make_decision(game_state)
	
	# 应该能做出合理决策
	return decision != Vector2.ZERO

func _test_maze_navigation() -> bool:
	var game_state = _create_maze_scenario()
	var decision = ai_brain.make_decision(game_state)
	
	# 应该能在迷宫中移动
	return decision != Vector2.ZERO

## 测试边缘情况
func _test_edge_case_scenarios():
	_start_test("边缘情况测试")
	
	var result1 = _test_no_food_scenario()
	_assert_test("无食物场景", result1, "AI应能处理无食物的情况")
	
	var result2 = _test_surrounded_scenario()
	_assert_test("被包围场景", result2, "AI应能处理被完全包围的情况")

func _test_no_food_scenario() -> bool:
	var game_state = _create_simple_game_state()
	game_state["food_position"] = Vector2(-1, -1)  # 无食物
	
	var decision = ai_brain.make_decision(game_state)
	return decision != Vector2.ZERO  # 应该仍能做出决策

func _test_surrounded_scenario() -> bool:
	var game_state = _create_surrounded_scenario()
	var decision = ai_brain.make_decision(game_state)
	
	# 即使被包围也应该尝试做出最优决策
	return true  # 这个测试主要是确保不会崩溃

## 性能基准测试
func _test_performance_benchmarks():
	_start_test("性能基准测试")
	
	var result1 = _test_decision_speed()
	_assert_test("决策速度", result1, "AI决策应在合理时间内完成")
	
	var result2 = _test_pathfinding_performance()
	_assert_test("路径规划性能", result2, "路径规划应高效完成")

func _test_decision_speed() -> bool:
	var game_state = _create_simple_game_state()
	
	var start_time = Time.get_ticks_msec()
	for i in range(100):  # 连续做100个决策
		ai_brain.make_decision(game_state)
	var end_time = Time.get_ticks_msec()
	
	var avg_time = (end_time - start_time) / 100.0
	print("  平均决策时间: %.2fms" % avg_time)
	
	# 平均决策时间应小于10ms
	return avg_time < 10.0

func _test_pathfinding_performance() -> bool:
	var game_state = _create_complex_maze_state()
	
	var start_time = Time.get_ticks_msec()
	for i in range(50):  # 50次路径规划
		pathfinder.find_path(Vector2(1, 1), Vector2(38, 28), game_state)
	var end_time = Time.get_ticks_msec()
	
	var avg_time = (end_time - start_time) / 50.0
	print("  平均路径规划时间: %.2fms" % avg_time)
	
	# 平均路径规划时间应小于20ms
	return avg_time < 20.0

## 集成测试
func _test_ai_integration():
	_start_test("AI集成测试")
	
	var result1 = _test_complete_game_simulation()
	_assert_test("完整游戏模拟", result1, "AI应能完成一局游戏")

func _test_complete_game_simulation() -> bool:
	# 模拟一局完整的游戏
	var game_state = _create_simple_game_state()
	game_state["snake_body"] = [Vector2(10, 10)]
	var steps = 0
	var max_steps = 1000
	
	while steps < max_steps:
		var decision = ai_brain.make_decision(game_state)
		if decision == Vector2.ZERO:
			break  # AI无法继续
		
		# 模拟移动
		var new_head = game_state["snake_head"] + decision
		
		# 检查碰撞
		if _check_collision(new_head, game_state):
			break
		
		# 更新游戏状态
		game_state["snake_head"] = new_head
		game_state["snake_body"].push_front(new_head)
		
		# 检查是否吃到食物
		if new_head == game_state["food_position"]:
			_generate_new_food(game_state)
		else:
			game_state["snake_body"].pop_back()
		
		steps += 1
	
	print("  游戏模拟步数: %d" % steps)
	return steps > 50  # 至少能生存50步

## 辅助方法 - 创建测试场景

func _create_simple_game_state() -> Dictionary:
	return {
		"grid_width": 40,
		"grid_height": 30,
		"snake_head": Vector2(10, 10),
		"snake_body": [Vector2(10, 10)],
		"food_position": Vector2(20, 15)
	}

func _create_game_state_with_obstacles() -> Dictionary:
	var state = _create_simple_game_state()
	var obstacles = []
	
	# 创建一些障碍物
	for i in range(15, 20):
		obstacles.append(Vector2(i, 10))
		obstacles.append(Vector2(i, 15))
	
	state["snake_body"] = obstacles
	return state

func _create_complex_maze_state() -> Dictionary:
	var state = _create_simple_game_state()
	var walls = []
	
	# 创建复杂迷宫
	for x in range(0, 40):
		for y in range(0, 30):
			if (x % 4 == 0 and y % 2 == 1) or (y % 4 == 0 and x % 2 == 1):
				walls.append(Vector2(x, y))
	
	state["snake_body"] = walls
	return state

func _create_blocked_game_state() -> Dictionary:
	var state = _create_simple_game_state()
	var walls = []
	
	# 创建完全封闭的区域
	for x in range(0, 40):
		for y in range(0, 30):
			if x < 8 or x > 32 or y < 8 or y > 22:
				walls.append(Vector2(x, y))
	
	# 在中间放置分隔墙
	for y in range(8, 23):
		walls.append(Vector2(20, y))
	
	state["snake_body"] = walls
	return state

func _create_balanced_scenario() -> Dictionary:
	var state = _create_simple_game_state()
	state["snake_head"] = Vector2(10, 10)
	state["food_position"] = Vector2(15, 15)
	state["snake_body"] = [Vector2(10, 10), Vector2(9, 10), Vector2(8, 10)]
	return state

func _create_corner_scenario() -> Dictionary:
	var state = _create_simple_game_state()
	state["snake_head"] = Vector2(1, 1)
	state["snake_body"] = [Vector2(1, 1), Vector2(2, 1), Vector2(1, 2)]
	return state

func _create_narrow_passage_scenario() -> Dictionary:
	var state = _create_simple_game_state()
	var walls = []
	
	# 创建狭窄通道
	for y in range(5, 15):
		if y != 10:  # 留一个通道
			walls.append(Vector2(10, y))
			walls.append(Vector2(12, y))
	
	state["snake_body"] = walls
	state["snake_head"] = Vector2(8, 10)
	state["food_position"] = Vector2(15, 10)
	return state

func _create_maze_scenario() -> Dictionary:
	return _create_complex_maze_state()

func _create_surrounded_scenario() -> Dictionary:
	var state = _create_simple_game_state()
	var walls = []
	
	# 创建包围圈
	for x in range(8, 13):
		walls.append(Vector2(x, 8))
		walls.append(Vector2(x, 12))
	for y in range(9, 12):
		walls.append(Vector2(8, y))
		walls.append(Vector2(12, y))
	
	state["snake_body"] = walls
	state["snake_head"] = Vector2(10, 10)
	return state

## 测试辅助方法

func _reset_test_stats():
	total_tests = 0
	passed_tests = 0
	failed_tests = 0
	test_results.clear()

func _start_test(test_name: String):
	current_test_name = test_name
	print("\n--- %s ---" % test_name)

func _assert_test(sub_test_name: String, result: bool, description: String):
	total_tests += 1
	var full_name = current_test_name + " - " + sub_test_name
	
	if result:
		passed_tests += 1
		print("✓ %s: 通过" % sub_test_name)
		test_results[full_name] = {"status": "PASS", "description": description}
	else:
		failed_tests += 1
		print("✗ %s: 失败" % sub_test_name)
		test_results[full_name] = {"status": "FAIL", "description": description}

func _check_collision(position: Vector2, game_state: Dictionary) -> bool:
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	# 边界检查
	if position.x < 0 or position.x >= grid_width or position.y < 0 or position.y >= grid_height:
		return true
	
	# 蛇身检查
	var snake_body = game_state.get("snake_body", [])
	return position in snake_body

func _generate_new_food(game_state: Dictionary):
	# 随机生成新食物位置
	var grid_width = game_state.get("grid_width", 40)
	var grid_height = game_state.get("grid_height", 30)
	
	var attempts = 0
	while attempts < 100:
		var new_pos = Vector2(randi() % grid_width, randi() % grid_height)
		if not _check_collision(new_pos, game_state):
			game_state["food_position"] = new_pos
			break
		attempts += 1

func _print_test_summary():
	print("\n=== 测试总结 ===")
	print("总测试数: %d" % total_tests)
	print("通过: %d" % passed_tests)
	print("失败: %d" % failed_tests)
	print("成功率: %.1f%%" % ((passed_tests * 100.0) / total_tests))
	
	if failed_tests > 0:
		print("\n失败的测试:")
		for test_name in test_results:
			if test_results[test_name]["status"] == "FAIL":
				print("  - %s" % test_name)

## 生成测试报告
func generate_test_report() -> String:
	var report = "# AI测试报告\n\n"
	report += "**测试时间**: %s\n" % Time.get_datetime_string_from_system()
	report += "**总测试数**: %d\n" % total_tests
	report += "**通过数**: %d\n" % passed_tests
	report += "**失败数**: %d\n" % failed_tests
	report += "**成功率**: %.1f%%\n\n" % ((passed_tests * 100.0) / total_tests)
	
	report += "## 详细结果\n\n"
	for test_name in test_results:
		var result = test_results[test_name]
		var status_icon = "✓" if result["status"] == "PASS" else "✗"
		report += "- %s **%s**: %s\n" % [status_icon, test_name, result["description"]]
	
	return report

## 保存测试结果
func save_test_results(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(generate_test_report())
		file.close()
		print("测试结果已保存到: %s" % file_path) 