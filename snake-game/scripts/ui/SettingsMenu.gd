## 设置菜单脚本
## 负责游戏设置界面的显示和交互
## 作者：课程示例
## 创建时间：2025-01-16

class_name SettingsMenu
extends Control

# 信号定义
signal back_to_menu_requested

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
	
	# 验证必要的UI节点是否存在
	if not back_button:
		print("Warning: BackButton not found in scene")
	if not volume_slider:
		print("Warning: VolumeSlider not found in scene")
	if not volume_label:
		print("Warning: VolumeLabel not found in scene")
	if not fullscreen_checkbox:
		print("Warning: FullscreenCheckBox not found in scene")
	if not grid_visible_checkbox:
		print("Warning: GridVisibleCheckBox not found in scene")
	if not difficulty_option:
		print("Warning: DifficultyOption not found in scene")
	if not reset_button:
		print("Warning: ResetButton not found in scene")
	if not apply_button:
		print("Warning: ApplyButton not found in scene")
	


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
		# 从SaveManager逐个获取设置项
		current_settings = {
			"volume": save_manager.get_setting("volume", 1.0),
			"fullscreen": save_manager.get_setting("fullscreen", false),
			"grid_visible": save_manager.get_setting("grid_visible", true),
			"difficulty": save_manager.get_setting("difficulty", 1)
		}
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
		var difficulty_value = current_settings.get("difficulty", 1)
		# 确保是整数类型
		if difficulty_value is String:
			# 将字符串转换为索引
			match difficulty_value:
				"easy": difficulty_value = 0
				"normal": difficulty_value = 1
				"hard": difficulty_value = 2
				_: difficulty_value = 1
		difficulty_option.selected = difficulty_value

## 更新音量标签
func _update_volume_label(value: float) -> void:
	if volume_label:
		var percentage = int(value * 100)
		volume_label.text = "音量: " + str(percentage) + "%"

## 音量变化处理
func _on_volume_changed(value: float) -> void:
	current_settings["volume"] = value
	_update_volume_label(value)
	
	# 不再实时应用音量，只在点击应用按钮时生效

## 全屏切换处理
func _on_fullscreen_toggled(pressed: bool) -> void:
	current_settings["fullscreen"] = pressed
	
	# 不再实时应用全屏设置，只在点击应用按钮时生效

## 网格可见切换处理
func _on_grid_visible_toggled(pressed: bool) -> void:
	current_settings["grid_visible"] = pressed
	
	# 不再实时应用网格设置，只在点击应用按钮时生效

## 难度选择处理
func _on_difficulty_selected(index: int) -> void:
	current_settings["difficulty"] = index

## 通知网格可见性变化
func _notify_grid_visibility_change(visible: bool) -> void:
	# 查找游戏场景中的网格对象
	var grid = get_tree().get_first_node_in_group("grid")
	if grid:
		# 直接设置visible属性
		grid.visible = visible
		# 同时更新Grid内部的show_grid状态
		grid.show_grid = visible
		grid.set_grid_lines_visible(visible)
		grid.set_border_visible(visible)
		print("Grid visibility changed to: ", visible)
	else:
		# 在菜单场景中查找背景网格
		var menu_scene = get_tree().get_first_node_in_group("menu_scene")
		if menu_scene and menu_scene.has_method("set_background_grid_visible"):
			menu_scene.set_background_grid_visible(visible)
			print("Background grid visibility changed to: ", visible)
		else:
			# 如果都找不到，设置会在应用时保存，游戏场景启动时会读取并应用
			print("Grid not found - settings will be applied when game starts")

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
	
	# 应用全屏设置
	var fullscreen = current_settings.get("fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# 恢复到固定的窗口大小
		_restore_window_size()
	
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
	# 先发送信号，让父级处理（比如Menu.gd）
	back_to_menu_requested.emit()
	
	# 如果信号没有被处理，则使用SceneManager
	# 延迟一帧检查是否还在当前场景
	await get_tree().process_frame
	if scene_manager and is_inside_tree():
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

## 恢复窗口大小
func _restore_window_size() -> void:
	# 从项目设置中获取窗口大小，或使用默认值
	var window_width = ProjectSettings.get_setting("display/window/size/viewport_width", 800)
	var window_height = ProjectSettings.get_setting("display/window/size/viewport_height", 600)
	DisplayServer.window_set_size(Vector2i(window_width, window_height))
	
	# 将窗口居中
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = Vector2i(
		(screen_size.x - window_width) / 2,
		(screen_size.y - window_height) / 2
	)
	DisplayServer.window_set_position(window_pos)
	print("Window size restored to: ", window_width, "x", window_height)

## 重置UI状态
func reset_ui() -> void:
	_load_settings()
	print("SettingsMenu UI reset")
