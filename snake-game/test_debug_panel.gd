extends Node

## 统一AI调试面板测试脚本
## 自动启用AI调试模式以测试整合后的调试面板功能

func _ready():
	print("🔧 开始AI调试面板测试...")
	
	# 等待一帧确保所有系统初始化完成
	await get_tree().process_frame
	
	# 设置AI调试模式
	_setup_ai_debug_mode()
	
	# 等待短暂时间后启动游戏
	await get_tree().create_timer(1.0).timeout
	_start_ai_debug_game()

## 设置AI调试模式
func _setup_ai_debug_mode():
	print("📝 配置AI调试设置...")
	
	# 检查并获取SaveManager
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		if save_manager:
			save_manager.set_setting("ai_debug_enabled", true)
			save_manager.set_setting("ai_difficulty", 3)  # 专家难度
			save_manager.set_setting("game_mode", "ai_battle")
			print("✅ AI调试配置已设置")
		else:
			print("❌ 无法找到SaveManager节点")
	else:
		print("⚠️ SaveManager autoload未设置，使用默认配置")

## 启动AI调试游戏
func _start_ai_debug_game():
	print("🎮 启动AI调试游戏...")
	
	# 检查并获取SceneManager
	if has_node("/root/SceneManager"):
		var scene_manager = get_node("/root/SceneManager")
		if scene_manager and scene_manager.has_method("change_scene"):
			# 检查SceneType枚举
			if scene_manager.has_method("get_scene_type"):
				var scene_type = scene_manager.get_scene_type("GAME")
			else:
				# 直接使用场景路径
				get_tree().change_scene_to_file("res://scenes/Game.tscn")
			print("🚀 游戏场景启动中...")
		else:
			print("❌ SceneManager节点无效或方法不存在")
			# 直接切换到游戏场景
			get_tree().change_scene_to_file("res://scenes/Game.tscn")
	else:
		print("⚠️ SceneManager autoload未设置，直接切换场景")
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

## 监控AI调试信息
func _monitor_ai_debug():
	print("👁️ 开始监控AI调试信息...")
	
	# 查找游戏场景中的AI组件
	var game_scene = get_tree().current_scene
	if not game_scene:
		print("❌ 无法找到游戏场景")
		return
	
	# 查找AI玩家
	var ai_player = game_scene.find_child("AIPlayer")
	if ai_player:
		print("✅ 找到AI玩家，连接调试信号...")
		
		# 连接AI调试信号
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
	else:
		print("⚠️ 未找到AI玩家，稍后重试...")
		await get_tree().create_timer(2.0).timeout
		_monitor_ai_debug()

## AI决策调试信息处理
func _on_ai_decision_debug(direction: Vector2, reasoning: String, confidence: float, scores: Dictionary):
	print("🧠 AI决策: %s | 理由: %s | 置信度: %.1f%%" % [
		_direction_to_string(direction),
		reasoning,
		confidence * 100
	])
	
	if scores.size() > 0:
		print("   📊 评分详情:")
		for key in scores:
			print("      • %s: %.2f" % [key, scores[key]])

## AI性能调试信息处理
func _on_ai_performance_debug(metrics: Dictionary):
	print("📈 AI性能指标:")
	print("   • 生存时间: %.1fs" % metrics.get("survival_time", 0.0))
	print("   • 决策次数: %d" % metrics.get("decisions_made", 0))
	print("   • 食物获取: %d" % metrics.get("food_eaten", 0))
	print("   • 平均置信度: %.1f%%" % (metrics.get("avg_confidence", 0.0) * 100))

## AI行为分析调试信息处理
func _on_ai_behavior_debug(behavior_data: Dictionary):
	var strategy = behavior_data.get("dominant_strategy", "未知")
	var pattern = behavior_data.get("decision_pattern", "未知")
	print("🎯 AI行为分析: 策略=%s | 模式=%s" % [strategy, pattern])

## AI风险评估调试信息处理
func _on_ai_risk_debug(risk_data: Dictionary):
	var risk_level = risk_data.get("current_risk_level", 0.0)
	var threats = risk_data.get("immediate_threats", [])
	print("⚠️ AI风险评估: %.1f%% | 威胁: %s" % [
		risk_level * 100,
		str(threats) if threats.size() > 0 else "无"
	])

## AI路径计算调试信息处理
func _on_ai_path_debug(path_data: Dictionary):
	var has_path = path_data.get("has_path", false)
	var length = path_data.get("path_length", 0)
	print("🗺️ AI路径规划: %s | 长度: %d步" % [
		"已找到" if has_path else "未找到",
		length
	])

## 辅助函数：方向转字符串
func _direction_to_string(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "⬆️向上"
	elif direction == Vector2.DOWN:
		return "⬇️向下"
	elif direction == Vector2.LEFT:
		return "⬅️向左"
	elif direction == Vector2.RIGHT:
		return "➡️向右"
	else:
		return "❓未知"

## 在游戏场景加载后监控AI
func _on_scene_changed():
	await get_tree().create_timer(1.0).timeout
	_monitor_ai_debug()

## 连接场景变化信号
func _connect_scene_signals():
	if has_node("/root/SceneManager"):
		var scene_manager = get_node("/root/SceneManager")
		if scene_manager and scene_manager.has_signal("scene_changed"):
			scene_manager.scene_changed.connect(_on_scene_changed) 