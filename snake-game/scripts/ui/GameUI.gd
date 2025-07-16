## 游戏UI脚本
## 负责游戏中的用户界面显示和交互
## 作者：课程示例
## 创建时间：2025-01-16

class_name GameUI
extends Control

# UI节点引用
@onready var score_label: Label
@onready var level_label: Label
@onready var speed_label: Label
@onready var pause_button: Button
@onready var pause_panel: Panel
@onready var game_over_panel: Panel
@onready var final_score_label: Label
@onready var restart_button: Button
@onready var menu_button: Button
@onready var continue_button: Button

# 游戏管理器引用
var game_manager: GameManager
var scene_manager: SceneManager

# UI状态
var is_paused: bool = false
var is_game_over: bool = false

func _ready() -> void:
	# 获取管理器引用
	_get_manager_references()
	
	# 设置UI
	_setup_ui()
	
	# 连接信号
	_connect_signals()
	
	# 初始化显示
	_initialize_display()
	
	print("GameUI initialized")

## 获取管理器引用
func _get_manager_references() -> void:
	# 直接引用autoload单例
	game_manager = GameManager
	scene_manager = SceneManager
	
	if not game_manager:
		print("Warning: GameManager not found")
	if not scene_manager:
		print("Warning: SceneManager not found")

## 设置UI
func _setup_ui() -> void:
	# 查找UI节点
	_find_ui_nodes()
	

	
	# 验证必要的UI节点是否存在
	if not score_label or not level_label or not speed_label or not pause_button:
		print("Warning: Some UI nodes are missing in the scene file")

## 查找UI节点
func _find_ui_nodes() -> void:
	score_label = find_child("ScoreLabel") as Label
	level_label = find_child("LevelLabel") as Label
	speed_label = find_child("SpeedLabel") as Label
	pause_button = find_child("PauseButton") as Button
	pause_panel = find_child("PausePanel") as Panel
	game_over_panel = find_child("GameOverPanel") as Panel
	final_score_label = find_child("FinalScoreLabel") as Label
	restart_button = find_child("RestartButton") as Button
	menu_button = find_child("MenuButton") as Button
	continue_button = find_child("ContinueButton") as Button







## 连接信号
func _connect_signals() -> void:
	# 连接按钮信号
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
	
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)
	
	# 连接游戏管理器信号
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.level_changed.connect(_on_level_changed)
		game_manager.game_paused.connect(_on_game_paused)
		game_manager.game_resumed.connect(_on_game_resumed)
		game_manager.game_over.connect(_on_game_over)

## 初始化显示
func _initialize_display() -> void:
	if game_manager:
		_update_score_display(game_manager.get_score())
		_update_level_display(game_manager.get_level())
		_update_speed_display(game_manager.get_speed())

## 更新分数显示
func _update_score_display(score: int) -> void:
	if score_label:
		score_label.text = "分数: " + str(score)

## 更新等级显示
func _update_level_display(level: int) -> void:
	if level_label:
		level_label.text = "等级: " + str(level)

## 更新速度显示
func _update_speed_display(speed: float) -> void:
	if speed_label:
		speed_label.text = "速度: " + str("%.1f" % speed)

## 显示暂停面板
func _show_pause_panel() -> void:
	print("Showing pause panel")
	if pause_panel:
		pause_panel.visible = true
		is_paused = true
		print("Pause panel is now visible")
	else:
		print("Warning: pause_panel not found")

## 隐藏暂停面板
func _hide_pause_panel() -> void:
	print("Hiding pause panel")
	if pause_panel:
		pause_panel.visible = false
		is_paused = false
		print("Pause panel is now hidden")
	else:
		print("Warning: pause_panel not found")

## 显示游戏结束面板
func _show_game_over_panel(final_score: int) -> void:
	if game_over_panel:
		game_over_panel.visible = true
		is_game_over = true
	
	# 更新最终分数
	if final_score_label:
		final_score_label.text = "最终分数: " + str(final_score)
	
	# 播放游戏结束动画
	_play_game_over_animation()

## 隐藏游戏结束面板
func _hide_game_over_panel() -> void:
	if game_over_panel:
		game_over_panel.visible = false
		is_game_over = false

## 播放游戏结束动画
func _play_game_over_animation() -> void:
	if game_over_panel:
		# 淡入动画
		game_over_panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.5)

## 暂停按钮点击
func _on_pause_button_pressed() -> void:
	if game_manager:
		if is_paused:
			game_manager.resume_game()
		else:
			game_manager.pause_game()

## 重新开始按钮点击
func _on_restart_button_pressed() -> void:
	print("Restarting game")
	
	# 隐藏游戏结束面板
	_hide_game_over_panel()
	
	# 重新开始游戏
	if game_manager:
		game_manager.start_game()

## 返回菜单按钮点击
func _on_menu_button_pressed() -> void:
	print("Returning to menu")
	
	# 切换到菜单场景
	if scene_manager:
		scene_manager.change_scene(SceneManager.SceneType.MENU)

## 继续按钮点击
func _on_continue_button_pressed() -> void:
	print("Continue button pressed")
	
	if game_manager:
		game_manager.resume_game()

## 分数变化信号处理
func _on_score_changed(new_score: int) -> void:
	_update_score_display(new_score)
	
	# 分数增加动画
	_play_score_animation()

## 等级变化信号处理
func _on_level_changed(new_level: int) -> void:
	_update_level_display(new_level)
	
	# 等级提升动画
	_play_level_up_animation()

## 游戏暂停信号处理
func _on_game_paused() -> void:
	print("GameUI received game_paused signal")
	_show_pause_panel()

## 游戏恢复信号处理
func _on_game_resumed() -> void:
	print("GameUI received game_resumed signal")
	_hide_pause_panel()

## 游戏结束信号处理
func _on_game_over(final_score: int) -> void:
	_show_game_over_panel(final_score)

## 播放分数动画
func _play_score_animation() -> void:
	if score_label:
		var tween = create_tween()
		tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

## 播放等级提升动画
func _play_level_up_animation() -> void:
	if level_label:
		# 闪烁效果
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(level_label, "modulate", GameColors.ACCENT_BLUE, 0.2)
		tween.tween_property(level_label, "modulate", GameColors.WHITE, 0.2)

## 处理输入
func _input(event: InputEvent) -> void:
	# 暂停状态下的输入处理
	if is_paused and event.is_action_pressed("pause"):
		if game_manager:
			game_manager.resume_game()
	
	# 游戏结束状态下的输入处理
	if is_game_over:
		if event.is_action_pressed("confirm"):
			_on_restart_button_pressed()
		elif event.is_action_pressed("cancel"):
			_on_menu_button_pressed()

## 更新分数（外部调用）
func update_score(score: int) -> void:
	_update_score_display(score)

## 更新等级（外部调用）
func update_level(level: int) -> void:
	_update_level_display(level)

## 更新速度显示（游戏管理器调用）
func update_speed_display() -> void:
	if game_manager:
		_update_speed_display(game_manager.get_speed())

## 重置UI状态
func reset_ui() -> void:
	_hide_pause_panel()
	_hide_game_over_panel()
	_initialize_display()
	print("GameUI reset")

## 获取UI状态
func get_ui_state() -> Dictionary:
	return {
		"is_paused": is_paused,
		"is_game_over": is_game_over
	}
