## AI调试可视化工具
## 为贪吃蛇AI提供决策过程的可视化调试功能
## 作者：课程示例
## 创建时间：2025-01-16

class_name AIDebugVisualizer
extends Node2D

# 信号定义
signal debug_info_updated(info: Dictionary)

# 可视化设置
var show_debug: bool = false
var show_path: bool = true
var show_safety_zones_flag: bool = true
var show_decision_scores_flag: bool = false
var show_thinking_process: bool = true  # 默认显示思考过程

# AI引用
var ai_player: AIPlayer

# 可视化元素
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

# 调试信息
var current_decision_info: Dictionary = {}
var decision_history: Array[Dictionary] = []
const MAX_DECISION_HISTORY: int = 20

func _ready() -> void:
	# 设置渲染层级
	z_index = 100  # 确保在其他元素之上
	
	# 创建思考指示器
	_create_thinking_indicator()
	
	print("AIDebugVisualizer initialized")

## 设置AI玩家引用
func set_ai_player(player: AIPlayer) -> void:
	if ai_player:
		# 断开之前的信号连接
		if ai_player.is_connected("ai_decision_made", _on_ai_decision_made):
			ai_player.ai_decision_made.disconnect(_on_ai_decision_made)
		if ai_player.ai_brain and ai_player.ai_brain.is_connected("thinking_started", _on_thinking_started):
			ai_player.ai_brain.thinking_started.disconnect(_on_thinking_started)
		if ai_player.ai_brain and ai_player.ai_brain.is_connected("thinking_finished", _on_thinking_finished):
			ai_player.ai_brain.thinking_finished.disconnect(_on_thinking_finished)
	
	ai_player = player
	
	if ai_player:
		# 连接信号
		ai_player.ai_decision_made.connect(_on_ai_decision_made)
		if ai_player.ai_brain:
			ai_player.ai_brain.thinking_started.connect(_on_thinking_started)
			ai_player.ai_brain.thinking_finished.connect(_on_thinking_finished)
		
		print("AIDebugVisualizer: Connected to AI player")

## 切换调试可视化
func toggle_debug_visualization() -> void:
	show_debug = not show_debug
	
	if show_debug:
		_refresh_all_visualizations()
	else:
		_clear_all_visualizations()
	
	print("AIDebugVisualizer: Debug visualization ", "enabled" if show_debug else "disabled")

## 绘制决策路径
func draw_decision_path(direction: Vector2) -> void:
	if not show_debug or not show_path:
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

## 显示决策推理
func show_decision_reasoning(reasoning: String) -> void:
	if not show_debug:
		return
	
	# 更新当前决策信息
	current_decision_info["reasoning"] = reasoning
	current_decision_info["timestamp"] = Time.get_time_dict_from_system()
	
	# 发送调试信息更新信号
	debug_info_updated.emit(current_decision_info)

## 清除调试视觉效果
func clear_debug_visuals() -> void:
	_clear_all_visualizations()

## 显示安全区域
func show_safety_zones() -> void:
	if not show_debug or not show_safety_zones_flag:
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

## 显示决策评分
func show_decision_scores() -> void:
	if not show_debug or not show_decision_scores_flag:
		return
	
	_clear_score_labels()
	
	if not ai_player or not ai_player.ai_brain or not ai_player.ai_snake:
		return
	
	var snake_head = ai_player.ai_snake.get_head_position()
	var current_direction = ai_player.ai_snake.get_direction()
	var game_state = _get_current_game_state()
	
	# 获取可能的方向
	var possible_directions = ai_player.ai_brain.get_possible_directions(current_direction)
	
	# 为每个方向显示评分
	for direction in possible_directions:
		var evaluation = ai_player.ai_brain.evaluate_direction(direction, game_state)
		var target_pos = snake_head + direction
		var score = evaluation.get("total_score", 0.0)
		
		_create_score_label(target_pos, str(round(score * 100) / 100.0))

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
	add_child(thinking_indicator)

## 创建决策箭头
func _create_decision_arrow(from: Vector2, to: Vector2) -> void:
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
	add_child(arrow)

## 绘制路径线
func _draw_path_line(path: Array[Vector2], color: Color) -> void:
	if path.size() < 2:
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
	add_child(line)

## 创建安全区域
func _create_safety_zone(grid_pos: Vector2, color: Color, cell_size: int) -> void:
	var zone = ColorRect.new()
	zone.size = Vector2(cell_size, cell_size)
	zone.position = grid_pos * cell_size
	zone.color = color
	zone.z_index = 1
	
	safety_zones.append(zone)
	add_child(zone)

## 创建评分标签
func _create_score_label(grid_pos: Vector2, score_text: String) -> void:
	var label = Label.new()
	label.text = score_text
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	var cell_size = Constants.GRID_SIZE
	label.position = grid_pos * cell_size + Vector2(5, 5)
	label.z_index = 15
	
	score_labels.append(label)
	add_child(label)

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
	
	if show_decision_scores_flag:
		show_decision_scores()

## AI决策信号处理
func _on_ai_decision_made(direction: Vector2, reasoning: String) -> void:
	if not show_debug:
		return
	
	# 记录决策历史
	var decision_record = {
		"direction": direction,
		"reasoning": reasoning,
		"timestamp": Time.get_time_dict_from_system(),
		"snake_position": ai_player.ai_snake.get_head_position() if ai_player.ai_snake else Vector2.ZERO
	}
	
	decision_history.append(decision_record)
	if decision_history.size() > MAX_DECISION_HISTORY:
		decision_history.remove_at(0)
	
	# 更新当前决策信息
	current_decision_info = decision_record
	
	# 绘制决策路径
	draw_decision_path(direction)
	
	# 显示决策推理
	show_decision_reasoning(reasoning)
	
	# 刷新其他可视化
	call_deferred("_refresh_all_visualizations")

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

## 设置可视化选项
func set_visualization_options(options: Dictionary) -> void:
	show_path = options.get("show_path", true)
	show_safety_zones_flag = options.get("show_safety_zones", true)
	show_decision_scores_flag = options.get("show_decision_scores", false)
	show_thinking_process = options.get("show_thinking_process", false)
	
	if show_debug:
		_refresh_all_visualizations()

## 获取调试统计信息
func get_debug_stats() -> Dictionary:
	return {
		"debug_enabled": show_debug,
		"decision_history_count": decision_history.size(),
		"current_decision": current_decision_info,
		"visualization_options": {
			"show_path": show_path,
			"show_safety_zones": show_safety_zones_flag,
			"show_decision_scores": show_decision_scores_flag,
			"show_thinking_process": show_thinking_process
		}
	}

## 导出决策历史
func export_decision_history() -> String:
	var export_data = {
		"timestamp": Time.get_time_dict_from_system(),
		"ai_difficulty": ai_player.get_difficulty() if ai_player else "unknown",
		"decision_count": decision_history.size(),
		"decisions": decision_history
	}
	
	return JSON.stringify(export_data, "\t")

## 切换特定可视化选项
func toggle_path_visualization() -> void:
	show_path = not show_path
	if show_debug:
		_refresh_all_visualizations()

func toggle_safety_visualization() -> void:
	show_safety_zones_flag = not show_safety_zones_flag
	if show_debug:
		_refresh_all_visualizations()

func toggle_scores_visualization() -> void:
	show_decision_scores_flag = not show_decision_scores_flag
	if show_debug:
		_refresh_all_visualizations()

func toggle_thinking_visualization() -> void:
	show_thinking_process = not show_thinking_process
