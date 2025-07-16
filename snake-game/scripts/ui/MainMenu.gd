## 主菜单脚本
## 负责主菜单界面的逻辑和交互
## 作者：课程示例
## 创建时间：2025-01-16

class_name MainMenu
extends Control

# UI节点引用
@onready var start_button: Button
@onready var settings_button: Button
@onready var quit_button: Button
@onready var high_score_label: Label
@onready var title_label: Label

# 管理器引用
var scene_manager
var save_manager

# 菜单状态
var is_menu_active: bool = true

func _ready() -> void:
	# 获取管理器引用
	_get_manager_references()
	
	# 设置UI
	_setup_ui()
	
	# 连接信号
	_connect_signals()
	
	# 更新显示
	_update_display()
	
	print("MainMenu initialized")

## 获取管理器引用
func _get_manager_references() -> void:
	# 使用autoload单例
	scene_manager = SceneManager
	save_manager = SaveManager
	
	if not scene_manager:
		print("Warning: SceneManager not found")
	if not save_manager:
		print("Warning: SaveManager not found")

## 设置UI
func _setup_ui() -> void:
	# 查找UI节点
	_find_ui_nodes()
	
	# 设置按钮样式
	_setup_button_styles()
	
	# 设置标题
	if title_label:
		title_label.text = "贪吃蛇游戏"
		title_label.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_TITLE)
		title_label.add_theme_color_override("font_color", GameColors.WHITE)

## 查找UI节点
func _find_ui_nodes() -> void:
	# 使用节点路径查找UI元素
	start_button = find_child("StartButton") as Button
	settings_button = find_child("SettingsButton") as Button
	quit_button = find_child("QuitButton") as Button
	high_score_label = find_child("HighScoreLabel") as Label
	title_label = find_child("Title") as Label
	
	# 如果找不到节点，创建基本的UI结构
	if not start_button:
		_create_fallback_ui()

## 创建备用UI结构
func _create_fallback_ui() -> void:
	print("Creating fallback UI structure")
	
	# 创建主容器
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(main_container)
	
	# 创建标题
	title_label = Label.new()
	title_label.text = "贪吃蛇游戏"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# 添加间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, GameSizes.MARGIN_LARGE)
	main_container.add_child(spacer1)
	
	# 创建按钮容器
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", GameSizes.MARGIN_MEDIUM)
	main_container.add_child(button_container)
	
	# 创建开始按钮
	start_button = Button.new()
	start_button.text = "开始游戏"
	start_button.custom_minimum_size = Vector2(GameSizes.BUTTON_WIDTH, GameSizes.BUTTON_HEIGHT)
	button_container.add_child(start_button)
	
	# 创建设置按钮
	settings_button = Button.new()
	settings_button.text = "设置"
	settings_button.custom_minimum_size = Vector2(GameSizes.BUTTON_WIDTH, GameSizes.BUTTON_HEIGHT)
	button_container.add_child(settings_button)
	
	# 创建退出按钮
	quit_button = Button.new()
	quit_button.text = "退出游戏"
	quit_button.custom_minimum_size = Vector2(GameSizes.BUTTON_WIDTH, GameSizes.BUTTON_HEIGHT)
	button_container.add_child(quit_button)
	
	# 添加间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, GameSizes.MARGIN_LARGE)
	main_container.add_child(spacer2)
	
	# 创建最高分显示
	high_score_label = Label.new()
	high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(high_score_label)

## 设置按钮样式
func _setup_button_styles() -> void:
	var buttons = [start_button, settings_button, quit_button]
	
	for button in buttons:
		if button:
			# 设置字体大小
			button.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_MEDIUM)
			
			# 设置颜色
			button.add_theme_color_override("font_color", GameColors.WHITE)
			button.add_theme_color_override("font_hover_color", GameColors.BUTTON_HOVER_COLOR)
			
			# 设置焦点模式
			button.focus_mode = Control.FOCUS_ALL

## 连接信号
func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
		start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
		settings_button.mouse_entered.connect(_on_button_hover.bind(settings_button))
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
		quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))

## 更新显示
func _update_display() -> void:
	# 更新最高分显示
	if high_score_label and save_manager:
		var save_data = save_manager.get_save_data()
		high_score_label.text = "最高分: " + str(save_data.high_score)
		high_score_label.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_MEDIUM)
		high_score_label.add_theme_color_override("font_color", GameColors.LIGHT_GRAY)

## 处理输入
func _input(event: InputEvent) -> void:
	if not is_menu_active:
		return
	
	if event.is_action_pressed("confirm"):
		# Enter键开始游戏
		_start_game()
	elif event.is_action_pressed("cancel"):
		# Escape键退出
		_quit_game()

## 开始按钮点击
func _on_start_button_pressed() -> void:
	_start_game()

## 设置按钮点击
func _on_settings_button_pressed() -> void:
	_open_settings()

## 退出按钮点击
func _on_quit_button_pressed() -> void:
	_quit_game()

## 按钮悬停效果
func _on_button_hover(button: Button) -> void:
	# 播放悬停音效（如果有的话）
	_play_hover_sound()
	
	# 悬停动画
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

## 开始游戏
func _start_game() -> void:
	print("Starting game from menu")
	
	# 播放点击音效
	_play_click_sound()
	
	# 禁用菜单
	is_menu_active = false
	
	# 切换到游戏场景
	if scene_manager:
		scene_manager.change_scene(SceneManager.SceneType.GAME)
	else:
		print("Error: Cannot start game - SceneManager not found")

## 打开设置
func _open_settings() -> void:
	print("Opening settings")
	
	# 播放点击音效
	_play_click_sound()
	
	# 切换到设置场景
	if scene_manager:
		scene_manager.change_scene(SceneManager.SceneType.SETTINGS)
	else:
		# 如果没有设置场景，显示简单的设置对话框
		_show_simple_settings()

## 退出游戏
func _quit_game() -> void:
	print("Quitting game")
	
	# 播放点击音效
	_play_click_sound()
	
	# 显示确认对话框
	_show_quit_confirmation()

## 显示简单设置
func _show_simple_settings() -> void:
	# 创建简单的设置对话框
	var dialog = AcceptDialog.new()
	dialog.title = "设置"
	dialog.dialog_text = "设置功能将在后续课时中实现"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

## 显示退出确认
func _show_quit_confirmation() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "确定要退出游戏吗？"
	add_child(dialog)
	dialog.popup_centered()
	
	# 连接信号
	dialog.confirmed.connect(_confirm_quit)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)

## 确认退出
func _confirm_quit() -> void:
	if scene_manager:
		scene_manager.quit_game()
	else:
		get_tree().quit()

## 播放悬停音效
func _play_hover_sound() -> void:
	# 音效功能将在后续课时中实现
	pass

## 播放点击音效
func _play_click_sound() -> void:
	# 音效功能将在后续课时中实现
	pass

## 菜单进入动画
func play_enter_animation() -> void:
	# 淡入动画
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# 按钮依次出现动画
	var buttons = [start_button, settings_button, quit_button]
	for i in range(buttons.size()):
		var button = buttons[i]
		if button:
			button.modulate.a = 0.0
			var button_tween = create_tween()
			button_tween.tween_delay(0.2 + i * 0.1)
			button_tween.tween_property(button, "modulate:a", 1.0, 0.3)

## 菜单退出动画
func play_exit_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)

## 重新激活菜单
func reactivate_menu() -> void:
	is_menu_active = true
	_update_display()
	play_enter_animation()

## 获取菜单统计信息
func get_menu_stats() -> Dictionary:
	if save_manager:
		return save_manager.get_statistics()
	return {}