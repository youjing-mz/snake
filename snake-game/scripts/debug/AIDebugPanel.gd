extends Control
class_name AIDebugPanel

## 统一AI调试面板 - 集成调试信息显示和可视化功能

signal debug_setting_changed(setting_name: String, value: bool)

# UI节点引用（动态创建，不使用@onready）
var info_container: VBoxContainer
var decision_label: Label
var metrics_label: Label
var behavior_label: Label
var risk_label: Label
var path_label: Label

# 调试选项（动态创建）
var show_paths_toggle: CheckBox
var show_risks_toggle: CheckBox
var show_thinking_toggle: CheckBox
var auto_pause_toggle: CheckBox
var step_button: Button

# 可视化设置
var show_debug: bool = true  # 默认显示，由外部控制
var show_path: bool = true
var show_safety_zones_flag: bool = true
var show_decision_scores_flag: bool = false
var show_thinking_process: bool = true

# AI引用
var ai_player: AIPlayer

# 可视化元素
var visualization_layer: Node2D
var path_lines: Array[Line2D] = []
var safety_zones: Array[ColorRect] = []
var score_labels: Array[Label] = []
var decision_arrows: Array[Polygon2D] = []
var thinking_indicator: ColorRect

# 颜色配置
const COLORS: Dictionary = {
	"safe_zone": Color(0.0, 1.0, 0.0, 0.2),      # 绿色半透明
	"danger_zone": Color(1.0, 0.0, 0.0, 0.3),     # 红色半透明
	"path_line": Color(0.0, 0.5, 1.0, 0.8),       # 蓝色
	"decision_arrow": Color(1.0, 1.0, 0.0, 0.9),  # 黄色
	"thinking": Color(0.5, 0.0, 1.0, 0.6),        # 紫色
	"food_target": Color(1.0, 0.5, 0.0, 0.7)      # 橙色
}

# 性能指标
var metrics: Dictionary = {
	"decisions_made": 0,
	"successful_food_catches": 0,
	"near_misses": 0,
	"deaths": 0,
	"average_decision_time": 0.0,
	"game_start_time": 0.0,
	"total_decision_time": 0.0,
	"longest_survival_time": 0.0,
	"current_survival_time": 0.0
}

# 行为分析数据
var behavior_data: Dictionary = {
	"direction_preferences": {"UP": 0, "DOWN": 0, "LEFT": 0, "RIGHT": 0},
	"decision_reasons": {},
	"risk_levels": [],
	"food_distances": [],
	"last_decisions": []
}

# 当前AI状态和调试信息
var current_ai_state: Dictionary = {}
var current_decision_info: Dictionary = {}
var decision_history: Array[Dictionary] = []
var is_auto_paused: bool = false
const MAX_DECISION_HISTORY: int = 20

func _ready():
	_setup_ui()
	_setup_visualization_layer()
	_connect_signals()
	reset_metrics()

## 设置可视化层
func _setup_visualization_layer():
	# 创建可视化层，用于在游戏场景上绘制调试信息
	visualization_layer = Node2D.new()
	visualization_layer.z_index = 100  # 确保在其他元素之上
	
	# 创建思考指示器
	_create_thinking_indicator()

## 设置AI玩家引用
func set_ai_player(player: AIPlayer) -> void:
	if ai_player:
		# 断开之前的信号连接
		_disconnect_ai_signals()
	
	ai_player = player
	
	if ai_player:
		# 连接调试信号
		_connect_ai_signals()
		print("AIDebugPanel: Connected to AI player")

## 连接AI信号
func _connect_ai_signals():
	if not ai_player:
		return
		
	# 连接新的调试信号
	if ai_player.has_signal("decision_made"):
		ai_player.decision_made.connect(_on_ai_decision_debug)
	if ai_player.has_signal("performance_updated"):
		ai_player.performance_updated.connect(_on_ai_performance_debug)
	if ai_player.has_signal("behavior_analyzed"):
		ai_player.behavior_analyzed.connect(_on_ai_behavior_debug)
	if ai_player.has_signal("risk_assessed"):
		ai_player.risk_assessed.connect(_on_ai_risk_debug)
	if ai_player.has_signal("path_calculated"):
		ai_player.path_calculated.connect(_on_ai_path_debug)
	
	# 连接原有的AI决策信号用于可视化
	if ai_player.has_signal("ai_decision_made"):
		ai_player.ai_decision_made.connect(_on_ai_decision_made_visual)
	
	# 连接AI大脑的思考信号
	if ai_player.ai_brain:
		if ai_player.ai_brain.has_signal("thinking_started"):
			ai_player.ai_brain.thinking_started.connect(_on_thinking_started)
		if ai_player.ai_brain.has_signal("thinking_finished"):
			ai_player.ai_brain.thinking_finished.connect(_on_thinking_finished)

## 断开AI信号
func _disconnect_ai_signals():
	if not ai_player:
		return
		
	if ai_player.has_signal("decision_made") and ai_player.is_connected("decision_made", _on_ai_decision_debug):
		ai_player.decision_made.disconnect(_on_ai_decision_debug)
	if ai_player.has_signal("performance_updated") and ai_player.is_connected("performance_updated", _on_ai_performance_debug):
		ai_player.performance_updated.disconnect(_on_ai_performance_debug)
	if ai_player.has_signal("behavior_analyzed") and ai_player.is_connected("behavior_analyzed", _on_ai_behavior_debug):
		ai_player.behavior_analyzed.disconnect(_on_ai_behavior_debug)
	if ai_player.has_signal("risk_assessed") and ai_player.is_connected("risk_assessed", _on_ai_risk_debug):
		ai_player.risk_assessed.disconnect(_on_ai_risk_debug)
	if ai_player.has_signal("path_calculated") and ai_player.is_connected("path_calculated", _on_ai_path_debug):
		ai_player.path_calculated.disconnect(_on_ai_path_debug)
	if ai_player.has_signal("ai_decision_made") and ai_player.is_connected("ai_decision_made", _on_ai_decision_made_visual):
		ai_player.ai_decision_made.disconnect(_on_ai_decision_made_visual)
	
	if ai_player.ai_brain:
		if ai_player.ai_brain.has_signal("thinking_started") and ai_player.ai_brain.is_connected("thinking_started", _on_thinking_started):
			ai_player.ai_brain.thinking_started.disconnect(_on_thinking_started)
		if ai_player.ai_brain.has_signal("thinking_finished") and ai_player.ai_brain.is_connected("thinking_finished", _on_thinking_finished):
			ai_player.ai_brain.thinking_finished.disconnect(_on_thinking_finished)

## 添加可视化层到游戏场景
func add_visualization_to_scene(parent: Node):
	if visualization_layer and parent:
		parent.add_child(visualization_layer)

## 切换调试显示
func toggle_debug_display():
	show_debug = not show_debug
	set_debug_display(show_debug)

## 设置调试显示状态
func set_debug_display(enabled: bool):
	show_debug = enabled
	visible = show_debug
	
	if show_debug:
		_refresh_all_visualizations()
	else:
		_clear_all_visualizations()
	
	print("AIDebugPanel: Debug display ", "enabled" if show_debug else "disabled")

## 显示调试面板
func show_debug_panel():
	set_debug_display(true)

## 隐藏调试面板  
func hide_debug_panel():
	set_debug_display(false)

## 设置UI布局
func _setup_ui():
	# 设置面板大小和位置 - 左上角，避免超出边界
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	custom_minimum_size = Vector2(300, 400)
	# 设置具体位置，留出一些边距
	position = Vector2(10, 10)
	size = Vector2(300, 400)
	# 确保面板在最上层
	z_index = 100
	# 设置背景颜色让面板更明显
	modulate = Color(1, 1, 1, 0.95)
	
	# 创建主容器
	var main_container = VBoxContainer.new()
	add_child(main_container)
	
	# 标题
	var title_label = Label.new()
	title_label.text = "AI调试面板"
	title_label.add_theme_stylebox_override("normal", _create_panel_style())
	main_container.add_child(title_label)
	
	# 信息容器
	info_container = VBoxContainer.new()
	info_container.name = "InfoContainer"
	main_container.add_child(info_container)
	
	# 添加各种信息标签
	_create_info_labels()
	
	# 控制面板
	var controls_container = VBoxContainer.new()
	controls_container.name = "Controls"
	main_container.add_child(controls_container)
	
	_create_control_elements(controls_container)

## 创建信息标签
func _create_info_labels():
	decision_label = _create_styled_label("决策信息: 等待中...")
	decision_label.name = "DecisionInfo"
	info_container.add_child(decision_label)
	
	metrics_label = _create_styled_label("性能指标: 初始化中...")
	metrics_label.name = "MetricsInfo"
	info_container.add_child(metrics_label)
	
	behavior_label = _create_styled_label("行为分析: 收集数据中...")
	behavior_label.name = "BehaviorInfo"
	info_container.add_child(behavior_label)
	
	risk_label = _create_styled_label("风险评估: 等待数据...")
	risk_label.name = "RiskInfo"
	info_container.add_child(risk_label)
	
	path_label = _create_styled_label("路径信息: 无活动路径")
	path_label.name = "PathInfo"
	info_container.add_child(path_label)

## 创建控制元素
func _create_control_elements(container: VBoxContainer):
	var title = Label.new()
	title.text = "调试控制"
	container.add_child(title)
	
	show_paths_toggle = CheckBox.new()
	show_paths_toggle.text = "显示路径"
	show_paths_toggle.name = "ShowPaths"
	show_paths_toggle.button_pressed = show_path
	container.add_child(show_paths_toggle)
	
	show_risks_toggle = CheckBox.new()
	show_risks_toggle.text = "显示风险区域"
	show_risks_toggle.name = "ShowRisks"
	show_risks_toggle.button_pressed = show_safety_zones_flag
	container.add_child(show_risks_toggle)
	
	show_thinking_toggle = CheckBox.new()
	show_thinking_toggle.text = "显示思考过程"
	show_thinking_toggle.name = "ShowThinking"
	show_thinking_toggle.button_pressed = show_thinking_process
	container.add_child(show_thinking_toggle)
	
	auto_pause_toggle = CheckBox.new()
	auto_pause_toggle.text = "高风险时自动暂停"
	auto_pause_toggle.name = "AutoPause"
	container.add_child(auto_pause_toggle)
	
	step_button = Button.new()
	step_button.text = "单步执行"
	step_button.name = "StepButton"
	step_button.disabled = true
	container.add_child(step_button)

## 连接信号
func _connect_signals():
	if show_paths_toggle:
		show_paths_toggle.toggled.connect(_on_show_paths_toggled)
	if show_risks_toggle:
		show_risks_toggle.toggled.connect(_on_show_risks_toggled)
	if show_thinking_toggle:
		show_thinking_toggle.toggled.connect(_on_show_thinking_toggled)
	if auto_pause_toggle:
		auto_pause_toggle.toggled.connect(_on_auto_pause_toggled)
	if step_button:
		step_button.pressed.connect(_on_step_pressed)

## ===== 调试信息更新方法 =====

## AI决策调试信息处理
func _on_ai_decision_debug(direction: Vector2, reasoning: String, confidence: float, scores: Dictionary):
	var decision_data = {
		"direction": direction,
		"reasoning": reasoning,
		"confidence": confidence,
		"scores": scores
	}
	update_decision_info(decision_data)
	
	# 同时进行可视化
	if show_debug:
		draw_decision_path(direction)

## AI性能调试信息处理
func _on_ai_performance_debug(performance_metrics: Dictionary):
	# 更新内部指标
	for key in performance_metrics:
		if key in metrics:
			metrics[key] = performance_metrics[key]
	update_metrics()

## AI行为分析调试信息处理
func _on_ai_behavior_debug(behavior_analysis: Dictionary):
	# 更新行为数据
	for key in behavior_analysis:
		if key in behavior_data:
			behavior_data[key] = behavior_analysis[key]
	update_behavior_analysis()

## AI风险评估调试信息处理
func _on_ai_risk_debug(risk_data: Dictionary):
	update_risk_assessment(risk_data)

## AI路径计算调试信息处理
func _on_ai_path_debug(path_data: Dictionary):
	update_path_info(path_data)

## 更新AI决策信息
func update_decision_info(decision_data: Dictionary):
	metrics["decisions_made"] += 1
	
	var direction = decision_data.get("direction", Vector2.ZERO)
	var reasoning = decision_data.get("reasoning", "未知")
	var confidence = decision_data.get("confidence", 0.0)
	var scores = decision_data.get("scores", {})
	
	# 更新决策信息显示
	var decision_text = "最新决策:\n"
	decision_text += "• 方向: %s\n" % _direction_to_string(direction)
	decision_text += "• 理由: %s\n" % reasoning
	decision_text += "• 置信度: %.2f\n" % confidence
	decision_text += "• 总分: %.2f\n" % scores.get("total_score", 0.0)
	decision_text += "• 食物分: %.2f\n" % scores.get("food_score", 0.0)
	decision_text += "• 安全分: %.2f\n" % scores.get("safety_score", 0.0)
	decision_text += "• 空间分: %.2f\n" % scores.get("space_score", 0.0)
	
	if decision_label:
		decision_label.text = decision_text
	
	# 更新行为数据
	_update_behavior_data(direction, reasoning, scores)
	
	# 检查是否需要自动暂停
	if is_auto_paused and confidence < 0.3:
		_trigger_auto_pause("低置信度决策")

## 更新性能指标
func update_metrics():
	var current_time = Time.get_ticks_msec() / 1000.0
	metrics["current_survival_time"] = current_time - metrics["game_start_time"]
	
	var metrics_text = "性能指标:\n"
	metrics_text += "• 决策次数: %d\n" % metrics["decisions_made"]
	metrics_text += "• 成功吃食: %d\n" % metrics["successful_food_catches"]
	metrics_text += "• 差点撞死: %d\n" % metrics["near_misses"]
	metrics_text += "• 死亡次数: %d\n" % metrics["deaths"]
	metrics_text += "• 存活时间: %.1fs\n" % metrics["current_survival_time"]
	metrics_text += "• 最长存活: %.1fs\n" % metrics["longest_survival_time"]
	
	if metrics["decisions_made"] > 0:
		var avg_time = metrics["total_decision_time"] / metrics["decisions_made"]
		metrics_text += "• 平均决策时间: %.1fms\n" % (avg_time * 1000)
	
	# 计算效率指标
	if metrics["current_survival_time"] > 0:
		var food_rate = metrics["successful_food_catches"] / metrics["current_survival_time"]
		metrics_text += "• 食物获取率: %.2f/s" % food_rate
	
	if metrics_label:
		metrics_label.text = metrics_text

## 更新行为分析
func update_behavior_analysis():
	var behavior_text = "行为分析:\n"
	
	# 方向偏好
	var total_decisions = 0
	for count in behavior_data["direction_preferences"].values():
		total_decisions += count
	
	if total_decisions > 0:
		behavior_text += "• 方向偏好:\n"
		for direction in behavior_data["direction_preferences"]:
			var count = behavior_data["direction_preferences"][direction]
			var percentage = (count * 100.0) / total_decisions
			behavior_text += "  %s: %.1f%%\n" % [direction, percentage]
	
	# 最常见的决策理由
	behavior_text += "• 主要决策理由:\n"
	var sorted_reasons = _get_top_reasons(3)
	for reason_data in sorted_reasons:
		behavior_text += "  %s: %d次\n" % [reason_data["reason"], reason_data["count"]]
	
	# 风险水平分析
	if behavior_data["risk_levels"].size() > 0:
		var avg_risk = _calculate_average(behavior_data["risk_levels"])
		behavior_text += "• 平均风险水平: %.2f\n" % avg_risk
	
	if behavior_label:
		behavior_label.text = behavior_text

## 更新风险评估显示
func update_risk_assessment(risk_data: Dictionary):
	var risk_text = "风险评估:\n"
	
	var current_risk = risk_data.get("current_risk", 0.0)
	var border_risk = risk_data.get("border_risk", 0.0)
	var body_risk = risk_data.get("body_risk", 0.0)
	var future_risk = risk_data.get("future_risk", 0.0)
	
	risk_text += "• 当前风险: %.2f\n" % current_risk
	risk_text += "• 边界风险: %.2f\n" % border_risk
	risk_text += "• 身体碰撞风险: %.2f\n" % body_risk
	risk_text += "• 未来风险: %.2f\n" % future_risk
	
	# 风险等级
	var risk_level = "安全"
	if current_risk > 0.8:
		risk_level = "极高"
	elif current_risk > 0.6:
		risk_level = "高"
	elif current_risk > 0.4:
		risk_level = "中等"
	elif current_risk > 0.2:
		risk_level = "较低"
	
	risk_text += "• 风险等级: %s" % risk_level
	
	if risk_label:
		risk_label.text = risk_text
	
	# 记录风险数据用于分析并触发可视化
	behavior_data["risk_levels"].append(current_risk)
	if behavior_data["risk_levels"].size() > 100:  # 保持最近100个数据点
		behavior_data["risk_levels"].pop_front()
	
	# 更新安全区域可视化
	if show_debug and show_safety_zones_flag:
		call_deferred("show_safety_zones")

## 更新路径信息
func update_path_info(path_data: Dictionary):
	var path_text = "路径信息:\n"
	
	var current_path = path_data.get("current_path", [])
	var path_length = path_data.get("path_length", 0.0)
	var target = path_data.get("target", Vector2.ZERO)
	var alternative_paths = path_data.get("alternative_paths", 0)
	
	if current_path.size() > 0:
		path_text += "• 当前路径长度: %d步\n" % current_path.size()
		path_text += "• 路径距离: %.1f\n" % path_length
		path_text += "• 目标位置: (%d, %d)\n" % [target.x, target.y]
		path_text += "• 备选路径: %d条\n" % alternative_paths
		
		# 显示路径的前几步
		if current_path.size() > 0:
			path_text += "• 下几步: "
			var steps_to_show = min(3, current_path.size())
			for i in range(steps_to_show):
				var step = current_path[i]
				path_text += "(%d,%d) " % [step.x, step.y]
			if current_path.size() > steps_to_show:
				path_text += "..."
	else:
		path_text += "• 无活动路径\n"
		path_text += "• 使用安全策略"
	
	if path_label:
		path_label.text = path_text

## ===== 可视化方法 =====

## AI决策可视化信号处理
func _on_ai_decision_made_visual(direction: Vector2, reasoning: String) -> void:
	if not show_debug:
		return
	
	# 记录决策历史
	var decision_record = {
		"direction": direction,
		"reasoning": reasoning,
		"timestamp": Time.get_time_dict_from_system(),
		"snake_position": ai_player.ai_snake.get_head_position() if ai_player and ai_player.ai_snake else Vector2.ZERO
	}
	
	decision_history.append(decision_record)
	if decision_history.size() > MAX_DECISION_HISTORY:
		decision_history.remove_at(0)
	
	# 更新当前决策信息
	current_decision_info = decision_record
	
	# 绘制决策路径
	draw_decision_path(direction)
	
	# 刷新其他可视化
	call_deferred("_refresh_all_visualizations")

## 绘制决策路径
func draw_decision_path(direction: Vector2) -> void:
	if not show_debug or not show_path or not visualization_layer:
		return
	
	_clear_path_lines()
	
	if not ai_player or not ai_player.ai_snake:
		return
	
	var snake_head = ai_player.ai_snake.get_head_position()
	var target_pos = snake_head + direction
	
	# 创建决策箭头
	_create_decision_arrow(snake_head, target_pos)
	
	# 如果AI大脑可用，尝试显示到食物的路径
	if ai_player.ai_brain and ai_player.ai_brain.pathfinder:
		var game_state = _get_current_game_state()
		var food_pos = game_state.get("food_position", Vector2(-1, -1))
		
		if food_pos.x >= 0 and food_pos.y >= 0:
			var path = ai_player.ai_brain.pathfinder.find_path(target_pos, food_pos, game_state)
			if path.size() > 0:
				var full_path: Array[Vector2] = [target_pos]
				full_path.append_array(path)
				_draw_path_line(full_path, COLORS.path_line)

## 显示安全区域
func show_safety_zones() -> void:
	if not show_debug or not show_safety_zones_flag or not visualization_layer:
		return
	
	_clear_safety_zones()
	
	if not ai_player or not ai_player.ai_brain or not ai_player.ai_snake:
		return
	
	var game_state = _get_current_game_state()
	var risk_analyzer = ai_player.ai_brain.risk_analyzer
	
	if not risk_analyzer:
		return
	
	var grid_size = Constants.get_grid_size()
	var cell_size = Constants.GRID_SIZE
	
	# 分析周围区域的安全性
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2(x, y)
			var safety_score = risk_analyzer.calculate_safety_score(pos, game_state)
			
			# 只显示明显安全或危险的区域
			if safety_score > 0.8:
				_create_safety_zone(pos, COLORS.safe_zone, cell_size)
			elif safety_score < 0.3:
				_create_safety_zone(pos, COLORS.danger_zone, cell_size)

## 获取当前游戏状态
func _get_current_game_state() -> Dictionary:
	if not ai_player:
		return {}
	
	return ai_player._get_current_game_state()

## 创建思考指示器
func _create_thinking_indicator() -> void:
	thinking_indicator = ColorRect.new()
	thinking_indicator.size = Vector2(40, 40)
	thinking_indicator.color = COLORS.thinking
	thinking_indicator.visible = false
	if visualization_layer:
		visualization_layer.add_child(thinking_indicator)

## 创建决策箭头
func _create_decision_arrow(from: Vector2, to: Vector2) -> void:
	if not visualization_layer:
		return
		
	var arrow = Polygon2D.new()
	var cell_size = Constants.GRID_SIZE
	
	# 计算箭头位置
	var start_pos = from * cell_size + Vector2(cell_size / 2, cell_size / 2)
	var end_pos = to * cell_size + Vector2(cell_size / 2, cell_size / 2)
	var direction = (end_pos - start_pos).normalized()
	
	# 创建箭头形状
	var arrow_points = PackedVector2Array()
	var arrow_size = cell_size * 0.3
	
	# 箭头头部
	arrow_points.append(end_pos)
	arrow_points.append(end_pos - direction * arrow_size + direction.rotated(PI/2) * arrow_size * 0.5)
	arrow_points.append(end_pos - direction * arrow_size * 0.5)
	arrow_points.append(end_pos - direction * arrow_size - direction.rotated(PI/2) * arrow_size * 0.5)
	
	arrow.polygon = arrow_points
	arrow.color = COLORS.decision_arrow
	arrow.z_index = 10
	
	decision_arrows.append(arrow)
	visualization_layer.add_child(arrow)

## 绘制路径线
func _draw_path_line(path: Array[Vector2], color: Color) -> void:
	if path.size() < 2 or not visualization_layer:
		return
	
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = color
	line.z_index = 5
	
	var cell_size = Constants.GRID_SIZE
	
	for pos in path:
		var world_pos = pos * cell_size + Vector2(cell_size / 2, cell_size / 2)
		line.add_point(world_pos)
	
	path_lines.append(line)
	visualization_layer.add_child(line)

## 创建安全区域
func _create_safety_zone(grid_pos: Vector2, color: Color, cell_size: int) -> void:
	if not visualization_layer:
		return
		
	var zone = ColorRect.new()
	zone.size = Vector2(cell_size, cell_size)
	zone.position = grid_pos * cell_size
	zone.color = color
	zone.z_index = 1
	
	safety_zones.append(zone)
	visualization_layer.add_child(zone)

## 思考开始信号处理
func _on_thinking_started() -> void:
	if not show_debug or not show_thinking_process:
		return
	
	if thinking_indicator and ai_player and ai_player.ai_snake:
		var snake_head = ai_player.ai_snake.get_head_position()
		var cell_size = Constants.GRID_SIZE
		thinking_indicator.position = snake_head * cell_size + Vector2(cell_size + 5, 0)
		thinking_indicator.visible = true

## 思考结束信号处理
func _on_thinking_finished() -> void:
	if thinking_indicator:
		thinking_indicator.visible = false

## ===== 清理方法 =====

## 清除路径线
func _clear_path_lines() -> void:
	for line in path_lines:
		if line and is_instance_valid(line):
			line.queue_free()
	path_lines.clear()

## 清除安全区域
func _clear_safety_zones() -> void:
	for zone in safety_zones:
		if zone and is_instance_valid(zone):
			zone.queue_free()
	safety_zones.clear()

## 清除评分标签
func _clear_score_labels() -> void:
	for label in score_labels:
		if label and is_instance_valid(label):
			label.queue_free()
	score_labels.clear()

## 清除决策箭头
func _clear_decision_arrows() -> void:
	for arrow in decision_arrows:
		if arrow and is_instance_valid(arrow):
			arrow.queue_free()
	decision_arrows.clear()

## 清除所有可视化元素
func _clear_all_visualizations() -> void:
	_clear_path_lines()
	_clear_safety_zones()
	_clear_score_labels()
	_clear_decision_arrows()
	
	if thinking_indicator:
		thinking_indicator.visible = false

## 刷新所有可视化
func _refresh_all_visualizations() -> void:
	if not show_debug:
		return
	
	_clear_all_visualizations()
	
	if show_safety_zones_flag:
		show_safety_zones()

## ===== 记录和重置方法 =====

## 记录食物获取
func record_food_catch():
	metrics["successful_food_catches"] += 1

## 记录险情
func record_near_miss():
	metrics["near_misses"] += 1

## 记录死亡
func record_death():
	metrics["deaths"] += 1
	metrics["longest_survival_time"] = max(metrics["longest_survival_time"], metrics["current_survival_time"])

## 重置指标
func reset_metrics():
	metrics["game_start_time"] = Time.get_ticks_msec() / 1000.0
	metrics["current_survival_time"] = 0.0
	behavior_data["direction_preferences"] = {"UP": 0, "DOWN": 0, "LEFT": 0, "RIGHT": 0}
	behavior_data["decision_reasons"].clear()
	behavior_data["risk_levels"].clear()
	behavior_data["food_distances"].clear()
	behavior_data["last_decisions"].clear()
	decision_history.clear()

## ===== 辅助方法 =====

func _create_styled_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_stylebox_override("normal", _create_label_style())
	return label

func _create_panel_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	return style

func _create_label_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _direction_to_string(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "上"
	elif direction == Vector2.DOWN:
		return "下"
	elif direction == Vector2.LEFT:
		return "左"
	elif direction == Vector2.RIGHT:
		return "右"
	else:
		return "无"

func _update_behavior_data(direction: Vector2, reasoning: String, scores: Dictionary):
	# 更新方向偏好
	var dir_str = _direction_to_string(direction)
	if dir_str in behavior_data["direction_preferences"]:
		behavior_data["direction_preferences"][dir_str] += 1
	
	# 更新决策理由
	if reasoning in behavior_data["decision_reasons"]:
		behavior_data["decision_reasons"][reasoning] += 1
	else:
		behavior_data["decision_reasons"][reasoning] = 1
	
	# 记录最近的决策
	behavior_data["last_decisions"].append({
		"direction": direction,
		"reasoning": reasoning,
		"scores": scores,
		"timestamp": Time.get_ticks_msec()
	})
	
	if behavior_data["last_decisions"].size() > 50:  # 保持最近50个决策
		behavior_data["last_decisions"].pop_front()

func _get_top_reasons(count: int) -> Array:
	var sorted_reasons = []
	for reason in behavior_data["decision_reasons"]:
		sorted_reasons.append({
			"reason": reason,
			"count": behavior_data["decision_reasons"][reason]
		})
	
	sorted_reasons.sort_custom(func(a, b): return a["count"] > b["count"])
	return sorted_reasons.slice(0, min(count, sorted_reasons.size()))

func _calculate_average(values: Array) -> float:
	if values.size() == 0:
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += value
	
	return sum / values.size()

func _trigger_auto_pause(reason: String):
	print("AI调试: 自动暂停 - ", reason)
	if step_button:
		step_button.disabled = false
	# 可以发送信号给游戏主循环暂停

## ===== 信号处理 =====

func _on_show_paths_toggled(pressed: bool):
	show_path = pressed
	debug_setting_changed.emit("show_paths", pressed)
	if show_debug:
		_refresh_all_visualizations()

func _on_show_risks_toggled(pressed: bool):
	show_safety_zones_flag = pressed
	debug_setting_changed.emit("show_risks", pressed)
	if show_debug:
		_refresh_all_visualizations()

func _on_show_thinking_toggled(pressed: bool):
	show_thinking_process = pressed
	debug_setting_changed.emit("show_thinking", pressed)

func _on_auto_pause_toggled(pressed: bool):
	is_auto_paused = pressed
	debug_setting_changed.emit("auto_pause", pressed)

func _on_step_pressed():
	debug_setting_changed.emit("step_execute", true)
	if step_button:
		step_button.disabled = true

## ===== 数据导出 =====

## 导出调试数据
func export_debug_data() -> Dictionary:
	return {
		"metrics": metrics,
		"behavior_data": behavior_data,
		"current_ai_state": current_ai_state,
		"decision_history": decision_history,
		"visualization_settings": {
			"show_path": show_path,
			"show_safety_zones": show_safety_zones_flag,
			"show_decision_scores": show_decision_scores_flag,
			"show_thinking_process": show_thinking_process
		}
	}

## 导入调试数据
func import_debug_data(data: Dictionary):
	if data.has("metrics"):
		metrics = data["metrics"]
	if data.has("behavior_data"):
		behavior_data = data["behavior_data"]
	if data.has("current_ai_state"):
		current_ai_state = data["current_ai_state"]
	if data.has("decision_history"):
		decision_history = data["decision_history"]
	
	# 更新显示
	update_metrics()
	update_behavior_analysis()

## 导出决策历史
func export_decision_history() -> String:
	var export_data = {
		"timestamp": Time.get_time_dict_from_system(),
		"ai_difficulty": ai_player.get_difficulty() if ai_player else "unknown",
		"decision_count": decision_history.size(),
		"decisions": decision_history
	}
	
	return JSON.stringify(export_data, "\t") 