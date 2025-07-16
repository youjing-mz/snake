## 设置菜单脚本
## 负责游戏设置界面的显示和交互
## 作者：课程示例
## 创建时间：2025-01-16

class_name SettingsMenu
extends Control

# UI节点引用
@onready var back_button: Button
@onready var volume_slider: HSlider
@onready var volume_label: Label
@onready var fullscreen_checkbox: CheckBox
@onready var grid_visible_checkbox: CheckBox
@onready var difficulty_option: OptionButton
@onready var reset_button: Button
@onready var apply_button: Button

# 管理器引用
var scene_manager: SceneManager
var save_manager: SaveManager

# 设置数据
var current_settings: Dictionary = {}
var original_settings: Dictionary = {}

# 音频相关
var master_bus_index: int

func _ready() -> void:
	# 获取管理器引用
	_get_manager_references()
	
	# 设置UI
	_setup_ui()
	
	# 连接信号
	_connect_signals()
	
	# 加载设置
	_load_settings()
	
	# 初始化音频
	_initialize_audio()
	
	print("SettingsMenu initialized")

## 获取管理器引用
func _get_manager_references() -> void:
	scene_manager = get_tree().get_first_node_in_group("scene_manager")
	save_manager = get_tree().get_first_node_in_group("save_manager")
	
	if not scene_manager:
		print("Warning: SceneManager not found")
	if not save_manager:
		print("Warning: SaveManager not found")

## 设置UI
func _setup_ui() -> void:
	# 查找UI节点
	_find_ui_nodes()
	
	# 如果找不到节点，创建基本UI
	if not back_button:
		_create_fallback_ui()
	
	# 设置UI样式
	_setup_ui_styles()

## 查找UI节点
func _find_ui_nodes() -> void:
	back_button = find_child("BackButton") as Button
	volume_slider = find_child("VolumeSlider") as HSlider
	volume_label = find_child("VolumeLabel") as Label
	fullscreen_checkbox = find_child("FullscreenCheckBox") as CheckBox
	grid_visible_checkbox = find_child("GridVisibleCheckBox") as CheckBox
	difficulty_option = find_child("DifficultyOption") as OptionButton
	reset_button = find_child("ResetButton") as Button
	apply_button = find_child("ApplyButton") as Button

## 创建备用UI
func _create_fallback_ui() -> void:
	print("Creating fallback SettingsMenu structure")
	
	# 主容器
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.add_theme_constant_override("separation", GameSizes.MARGIN_LARGE)
	add_child(main_container)
	
	# 标题
	var title_label = Label.new()
	title_label.text = "游戏设置"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_LARGE)
	main_container.add_child(title_label)
	
	# 设置容器
	var settings_container = VBoxContainer.new()
	settings_container.add_theme_constant_override("separation", GameSizes.MARGIN_MEDIUM)
	main_container.add_child(settings_container)
	
	# 音量设置
	_create_volume_setting(settings_container)
	
	# 显示设置
	_create_display_settings(settings_container)
	
	# 游戏设置
	_create_game_settings(settings_container)
	
	# 按钮容器
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", GameSizes.MARGIN_MEDIUM)
	main_container.add_child(button_container)
	
	# 重置按钮
	reset_button = Button.new()
	reset_button.text = "重置默认"
	reset_button.custom_minimum_size = Vector2(100, 40)
	button_container.add_child(reset_button)
	
	# 应用按钮
	apply_button = Button.new()
	apply_button.text = "应用"
	apply_button.custom_minimum_size = Vector2(100, 40)
	button_container.add_child(apply_button)
	
	# 返回按钮
	back_button = Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(100, 40)
	button_container.add_child(back_button)

## 创建音量设置
func _create_volume_setting(parent: Control) -> void:
	# 音量标签
	var volume_title = Label.new()
	volume_title.text = "音量设置"
	parent.add_child(volume_title)
	
	# 音量容器
	var volume_container = HBoxContainer.new()
	volume_container.add_theme_constant_override("separation", GameSizes.MARGIN_MEDIUM)
	parent.add_child(volume_container)
	
	# 音量标签
	volume_label = Label.new()
	volume_label.text = "音量: 100%"
	volume_label.custom_minimum_size.x = 80
	volume_container.add_child(volume_label)
	
	# 音量滑块
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = 1.0
	volume_slider.custom_minimum_size = Vector2(200, 20)
	volume_container.add_child(volume_slider)

## 创建显示设置
func _create_display_settings(parent: Control) -> void:
	# 显示标签
	var display_title = Label.new()
	display_title.text = "显示设置"
	parent.add_child(display_title)
	
	# 全屏复选框
	fullscreen_checkbox = CheckBox.new()
	fullscreen_checkbox.text = "全屏模式"
	parent.add_child(fullscreen_checkbox)
	
	# 网格可见复选框
	grid_visible_checkbox = CheckBox.new()
	grid_visible_checkbox.text = "显示网格"
	grid_visible_checkbox.button_pressed = true
	parent.add_child(grid_visible_checkbox)

## 创建游戏设置
func _create_game_settings(parent: Control) -> void:
	# 游戏标签
	var game_title = Label.new()
	game_title.text = "游戏设置"
	parent.add_child(game_title)
	
	# 难度容器
	var difficulty_container = HBoxContainer.new()
	difficulty_container.add_theme_constant_override("separation", GameSizes.MARGIN_MEDIUM)
	parent.add_child(difficulty_container)
	
	# 难度标签
	var difficulty_label = Label.new()
	difficulty_label.text = "难度:"
	difficulty_label.custom_minimum_size.x = 80
	difficulty_container.add_child(difficulty_label)
	
	# 难度选项
	difficulty_option = OptionButton.new()
	difficulty_option.add_item("简单")
	difficulty_option.add_item("普通")
	difficulty_option.add_item("困难")
	difficulty_option.selected = 1  # 默认普通难度
	difficulty_option.custom_minimum_size = Vector2(120, 30)
	difficulty_container.add_child(difficulty_option)

## 设置UI样式
func _setup_ui_styles() -> void:
	# 设置标签样式
	var labels = [volume_label]
	for label in labels:
		if label:
			label.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_MEDIUM)
			label.add_theme_color_override("font_color", GameColors.WHITE)
	
	# 设置按钮样式
	var buttons = [back_button, reset_button, apply_button]
	for button in buttons:
		if button:
			button.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_MEDIUM)
			button.add_theme_color_override("font_color", GameColors.WHITE)
	
	# 设置复选框样式
	var checkboxes = [fullscreen_checkbox, grid_visible_checkbox]
	for checkbox in checkboxes:
		if checkbox:
			checkbox.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_MEDIUM)
			checkbox.add_theme_color_override("font_color", GameColors.WHITE)

## 连接信号
func _connect_signals() -> void:
	# 连接按钮信号
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	if apply_button:
		apply_button.pressed.connect(_on_apply_button_pressed)
	
	# 连接控件信号
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	
	if grid_visible_checkbox:
		grid_visible_checkbox.toggled.connect(_on_grid_visible_toggled)
	
	if difficulty_option:
		difficulty_option.item_selected.connect(_on_difficulty_selected)

## 初始化音频
func _initialize_audio() -> void:
	master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index == -1:
		print("Warning: Master audio bus not found")

## 加载设置
func _load_settings() -> void:
	if save_manager:
		current_settings = save_manager.get_settings()
		original_settings = current_settings.duplicate()
	else:
		# 默认设置
		current_settings = _get_default_settings()
		original_settings = current_settings.duplicate()
	
	# 应用设置到UI
	_apply_settings_to_ui()

## 获取默认设置
func _get_default_settings() -> Dictionary:
	return {
		"volume": 1.0,
		"fullscreen": false,
		"grid_visible": true,
		"difficulty": 1  # 0=简单, 1=普通, 2=困难
	}

## 应用设置到UI
func _apply_settings_to_ui() -> void:
	# 音量设置
	if volume_slider:
		volume_slider.value = current_settings.get("volume", 1.0)
		_update_volume_label(volume_slider.value)
	
	# 全屏设置
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = current_settings.get("fullscreen", false)
	
	# 网格可见设置
	if grid_visible_checkbox:
		grid_visible_checkbox.button_pressed = current_settings.get("grid_visible", true)
	
	# 难度设置
	if difficulty_option:
		difficulty_option.selected = current_settings.get("difficulty", 1)

## 更新音量标签
func _update_volume_label(value: float) -> void:
	if volume_label:
		var percentage = int(value * 100)
		volume_label.text = "音量: " + str(percentage) + "%"

## 音量变化处理
func _on_volume_changed(value: float) -> void:
	current_settings["volume"] = value
	_update_volume_label(value)
	
	# 实时应用音量
	if master_bus_index != -1:
		var db_value = linear_to_db(value)
		AudioServer.set_bus_volume_db(master_bus_index, db_value)

## 全屏切换处理
func _on_fullscreen_toggled(pressed: bool) -> void:
	current_settings["fullscreen"] = pressed
	
	# 实时应用全屏设置
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

## 网格可见切换处理
func _on_grid_visible_toggled(pressed: bool) -> void:
	current_settings["grid_visible"] = pressed
	
	# 通知游戏场景更新网格显示
	_notify_grid_visibility_change(pressed)

## 难度选择处理
func _on_difficulty_selected(index: int) -> void:
	current_settings["difficulty"] = index

## 通知网格可见性变化
func _notify_grid_visibility_change(visible: bool) -> void:
	# 查找游戏场景中的网格对象
	var grid = get_tree().get_first_node_in_group("grid")
	if grid and grid.has_method("set_visible"):
		grid.set_visible(visible)

## 返回按钮点击
func _on_back_button_pressed() -> void:
	print("Returning to menu")
	
	# 检查是否有未保存的更改
	if _has_unsaved_changes():
		_show_unsaved_changes_dialog()
	else:
		_return_to_menu()

## 重置按钮点击
func _on_reset_button_pressed() -> void:
	print("Resetting settings to default")
	
	# 重置为默认设置
	current_settings = _get_default_settings()
	
	# 应用到UI
	_apply_settings_to_ui()
	
	# 立即应用设置
	_apply_current_settings()

## 应用按钮点击
func _on_apply_button_pressed() -> void:
	print("Applying settings")
	
	# 应用设置
	_apply_current_settings()
	
	# 保存设置
	_save_settings()
	
	# 更新原始设置
	original_settings = current_settings.duplicate()

## 应用当前设置
func _apply_current_settings() -> void:
	# 应用音量
	if master_bus_index != -1:
		var db_value = linear_to_db(current_settings.get("volume", 1.0))
		AudioServer.set_bus_volume_db(master_bus_index, db_value)
	
	# 应用全屏
	var fullscreen = current_settings.get("fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# 应用网格可见性
	var grid_visible = current_settings.get("grid_visible", true)
	_notify_grid_visibility_change(grid_visible)

## 保存设置
func _save_settings() -> void:
	if save_manager:
		for key in current_settings:
			save_manager.set_setting(key, current_settings[key])
		print("Settings saved")

## 检查是否有未保存的更改
func _has_unsaved_changes() -> bool:
	for key in current_settings:
		if current_settings[key] != original_settings.get(key):
			return true
	return false

## 显示未保存更改对话框
func _show_unsaved_changes_dialog() -> void:
	# 创建确认对话框
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "您有未保存的更改，是否要保存？"
	dialog.title = "未保存的更改"
	add_child(dialog)
	
	# 添加保存按钮
	dialog.add_button("保存", true, "save")
	dialog.add_button("不保存", false, "discard")
	
	# 连接信号
	dialog.custom_action.connect(_on_unsaved_dialog_action)
	dialog.confirmed.connect(_on_unsaved_dialog_confirmed)
	
	# 显示对话框
	dialog.popup_centered()

## 未保存更改对话框动作
func _on_unsaved_dialog_action(action: String) -> void:
	if action == "save":
		_apply_current_settings()
		_save_settings()
	
	_return_to_menu()

## 未保存更改对话框确认
func _on_unsaved_dialog_confirmed() -> void:
	_return_to_menu()

## 返回菜单
func _return_to_menu() -> void:
	if scene_manager:
		scene_manager.change_scene(SceneManager.SceneType.MENU)

## 处理输入
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		_on_back_button_pressed()

## 获取当前设置
func get_current_settings() -> Dictionary:
	return current_settings.duplicate()

## 设置特定设置值
func set_setting(key: String, value) -> void:
	current_settings[key] = value
	_apply_settings_to_ui()

## 获取特定设置值
func get_setting(key: String, default_value = null):
	return current_settings.get(key, default_value)

## 重置UI状态
func reset_ui() -> void:
	_load_settings()
	print("SettingsMenu UI reset")