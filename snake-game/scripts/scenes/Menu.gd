## 菜单场景脚本
## 负责主菜单场景的管理和显示
## 作者：课程示例
## 创建时间：2025-01-16

class_name Menu
extends Node2D

# UI引用
@onready var main_menu: Control
@onready var settings_menu: Control

# 管理器引用
var scene_manager: SceneManager
var save_manager: SaveManager

# 菜单状态
enum MenuState {
	MAIN,
	SETTINGS
}

var current_state: MenuState = MenuState.MAIN
var is_initialized: bool = false

# 背景装饰
var background_grid: Grid
var demo_snake: Snake
var background_particles: Array[Node2D] = []

func _ready() -> void:
	# 设置节点组
	add_to_group("menu_scene")
	
	# 获取管理器引用
	_get_manager_references()
	
	# 初始化菜单场景
	_initialize_menu_scene()
	
	# 创建背景装饰
	_create_background_decoration()
	
	# 创建菜单UI
	_create_menu_ui()
	
	# 连接信号
	_connect_signals()
	
	# 设置初始状态
	_set_menu_state(MenuState.MAIN)
	
	# 应用保存的设置
	_apply_saved_settings()
	
	# 标记为已初始化
	is_initialized = true
	
	print("Menu scene initialized")

## 获取管理器引用
func _get_manager_references() -> void:
	# 直接使用autoload单例
	scene_manager = SceneManager
	save_manager = SaveManager

## 初始化菜单场景
func _initialize_menu_scene() -> void:
	# 设置场景属性
	name = "MenuScene"
	
	# 设置背景颜色
	RenderingServer.set_default_clear_color(GameColors.BACKGROUND_DARK)

## 创建背景装饰
func _create_background_decoration() -> void:
	# 创建背景网格
	_create_background_grid()
	
	# 创建演示蛇
	_create_demo_snake()
	
	# 创建背景粒子
	_create_background_particles()

## 创建背景网格
func _create_background_grid() -> void:
	background_grid = Grid.new()
	background_grid.z_index = -2
	background_grid.modulate.a = 0.3  # 半透明
	add_child(background_grid)
	
	# 计算网格位置
	var viewport_size = get_viewport().get_visible_rect().size
	var grid_size = Constants.get_current_grid_size()
	var grid_width = grid_size.x
	var grid_height = grid_size.y

	var total_width = grid_width * Constants.GRID_SIZE
	var total_height = grid_height * Constants.GRID_SIZE
	
	background_grid.position = Vector2(
		(viewport_size.x - total_width) / 2,
		(viewport_size.y - total_height) / 2
	)
	
	# Grid会在_ready中自动初始化

## 创建演示蛇
func _create_demo_snake() -> void:
	demo_snake = Snake.new()
	demo_snake.z_index = -1
	demo_snake.modulate.a = 0.5  # 半透明
	demo_snake.position = background_grid.position
	add_child(demo_snake)
	
	# 演示蛇会在_ready中自动初始化
	
	# 设置演示蛇的初始身体
	for i in range(8):
		demo_snake.grow()
	
	# 开始演示蛇的自动移动
	_start_demo_snake_movement()

## 开始演示蛇移动
func _start_demo_snake_movement() -> void:
	if not demo_snake:
		return
	
	# 创建移动计时器
	var move_timer = Timer.new()
	move_timer.wait_time = 0.8
	move_timer.timeout.connect(_move_demo_snake)
	add_child(move_timer)
	move_timer.start()

## 移动演示蛇
func _move_demo_snake() -> void:
	if not demo_snake or not background_grid:
		return
	
	# 简单的AI移动逻辑
	var current_direction = demo_snake.get_direction()
	var head_pos = demo_snake.get_head_position()
	var next_pos = head_pos + current_direction
	
	# 检查边界碰撞，改变方向
	if not background_grid.is_valid_grid_position(next_pos) or demo_snake.is_position_occupied(next_pos):
		# 随机选择新方向（使用Vector2而不是Vector2i）
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		directions.erase(current_direction)
		directions.erase(-current_direction)  # 避免反向
		
		for direction in directions:
			var test_pos = head_pos + direction
			if background_grid.is_valid_grid_position(test_pos) and not demo_snake.is_position_occupied(test_pos):
				demo_snake.set_direction(direction)
				break
	
	# 移动蛇
	demo_snake.move()

## 创建背景粒子
func _create_background_particles() -> void:
	var particle_count = 20
	var viewport_size = get_viewport().get_visible_rect().size
	
	for i in range(particle_count):
		var particle = _create_background_particle()
		particle.position = Vector2(
			randf() * viewport_size.x,
			randf() * viewport_size.y
		)
		background_particles.append(particle)
		add_child(particle)
		
		# 开始粒子动画
		_animate_background_particle(particle)

## 创建背景粒子
func _create_background_particle() -> Node2D:
	var particle = Node2D.new()
	particle.z_index = -3
	
	# 创建粒子视觉
	var rect = ColorRect.new()
	rect.size = Vector2(2, 2)
	rect.color = GameColors.ACCENT_BLUE
	rect.color.a = 0.3
	particle.add_child(rect)
	
	return particle

## 动画背景粒子
func _animate_background_particle(particle: Node2D) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var duration = randf_range(10.0, 20.0)
	
	# 创建循环移动动画
	var tween = create_tween()
	tween.set_loops()
	
	# 随机移动路径
	var target_x = randf() * viewport_size.x
	var target_y = randf() * viewport_size.y
	
	tween.tween_property(particle, "position", Vector2(target_x, target_y), duration)
	tween.tween_callback(_animate_background_particle.bind(particle))

## 创建菜单UI
func _create_menu_ui() -> void:
	# 查找现有的UI节点
	_find_existing_ui_nodes()
	
	# 验证必要的UI节点是否存在
	if not main_menu:
		print("Warning: MainMenuUI not found in scene")
	if not settings_menu:
		print("Warning: SettingsMenuUI not found in scene")

## 查找现有的UI节点
func _find_existing_ui_nodes() -> void:
	# 查找场景中已存在的UI节点
	main_menu = find_child("MainMenuUI") as Control
	settings_menu = find_child("SettingsMenuUI") as Control
	
	if main_menu:
		main_menu.z_index = 1
		print("Found existing MainMenuUI")
	
	if settings_menu:
		settings_menu.z_index = 2
		settings_menu.visible = false
		print("Found existing SettingsMenuUI")



## 连接信号
func _connect_signals() -> void:
	# 连接场景管理器信号
	if scene_manager:
		scene_manager.scene_changed.connect(_on_scene_changed)
	
	# 连接主菜单按钮信号
	_connect_main_menu_signals()
	
	# 连接设置菜单按钮信号
	_connect_settings_menu_signals()

## 连接主菜单信号
func _connect_main_menu_signals() -> void:
	if not main_menu:
		return
	
	# 查找主菜单中的按钮
	var start_button = main_menu.find_child("StartButton") as Button
	var settings_button = main_menu.find_child("SettingsButton") as Button
	var quit_button = main_menu.find_child("QuitButton") as Button
	
	# 连接按钮信号
	if start_button:
		start_button.pressed.connect(_on_start_game)
	if settings_button:
		settings_button.pressed.connect(_on_settings_requested)
	if quit_button:
		quit_button.pressed.connect(_on_quit_game)
	
	# 连接自定义信号（如果是MainMenu类实例）
	if main_menu.has_signal("settings_requested"):
		main_menu.settings_requested.connect(_on_settings_requested)

## 连接设置菜单信号
func _connect_settings_menu_signals() -> void:
	if not settings_menu:
		return
	
	# Apply和Reset按钮让SettingsMenu类自己处理
	# 这些按钮的信号已经在SettingsMenu.gd中连接了
	
	# 连接SettingsMenu的自定义信号
	if settings_menu.has_signal("back_to_menu_requested"):
		settings_menu.back_to_menu_requested.connect(_on_back_to_main)

## 设置菜单状态
func _set_menu_state(new_state: MenuState) -> void:
	current_state = new_state
	
	match current_state:
		MenuState.MAIN:
			_show_main_menu()
		MenuState.SETTINGS:
			_show_settings_menu()

## 显示主菜单
func _show_main_menu() -> void:
	if main_menu:
		main_menu.visible = true
		_animate_menu_transition(main_menu, true)
	
	if settings_menu:
		_animate_menu_transition(settings_menu, false)

## 显示设置菜单
func _show_settings_menu() -> void:
	if settings_menu:
		settings_menu.visible = true
		_animate_menu_transition(settings_menu, true)
	
	if main_menu:
		_animate_menu_transition(main_menu, false)

## 菜单过渡动画
func _animate_menu_transition(menu: Control, show: bool) -> void:
	if not menu:
		return
	
	var tween = create_tween()
	
	if show:
		menu.modulate.a = 0.0
		menu.visible = true
		tween.tween_property(menu, "modulate:a", 1.0, 0.3)
	else:
		tween.tween_property(menu, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): menu.visible = false)

## 场景变化信号处理
func _on_scene_changed(scene_type: SceneManager.SceneType) -> void:
	print("Scene changing to: ", scene_type)
	
	# 清理菜单场景
	if scene_type != SceneManager.SceneType.MENU:
		_cleanup_menu_scene()

## 设置请求信号处理
func _on_settings_requested() -> void:
	print("Settings requested")
	_set_menu_state(MenuState.SETTINGS)

## 返回主菜单信号处理
func _on_back_to_main() -> void:
	print("Back to main menu")
	_set_menu_state(MenuState.MAIN)

## 开始游戏信号处理
func _on_start_game() -> void:
	print("Starting game")
	if scene_manager:
		scene_manager.change_scene(SceneManager.SceneType.GAME)

## 退出游戏信号处理
func _on_quit_game() -> void:
	print("Quit game requested")
	_show_exit_confirmation()



## 处理输入
func _input(event: InputEvent) -> void:
	if not is_initialized:
		return
	
	# ESC键处理
	if event.is_action_pressed("cancel"):
		match current_state:
			MenuState.SETTINGS:
				_set_menu_state(MenuState.MAIN)
			MenuState.MAIN:
				# 可以添加退出游戏确认
				_show_exit_confirmation()

## 显示退出确认
func _show_exit_confirmation() -> void:
	# 创建退出确认对话框
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "确定要退出游戏吗？"
	dialog.title = "退出游戏"
	add_child(dialog)
	
	# 添加确认按钮
	dialog.add_button("退出", true, "quit")
	
	# 连接信号
	dialog.custom_action.connect(_on_exit_dialog_action)
	dialog.confirmed.connect(_on_exit_confirmed)
	
	# 显示对话框
	dialog.popup_centered()

## 退出对话框动作
func _on_exit_dialog_action(action: String) -> void:
	if action == "quit":
		_quit_game()

## 退出确认
func _on_exit_confirmed() -> void:
	# 默认确认也是退出
	pass

## 退出游戏
func _quit_game() -> void:
	print("Quitting game")
	
	# 保存数据
	if save_manager:
		save_manager.auto_save()
	
	# 退出应用
	get_tree().quit()

## 清理菜单场景
func _cleanup_menu_scene() -> void:
	print("Cleaning up menu scene")
	
	# 停止演示蛇移动
	if demo_snake:
		demo_snake.set_paused(true)
	
	# 停止背景粒子动画
	for particle in background_particles:
		if particle:
			var tweens = particle.get_children().filter(func(child): return child is Tween)
			for tween in tweens:
				tween.kill()
	
	# 停止所有动画
	var all_tweens = get_tree().get_nodes_in_group("tween")
	for tween in all_tweens:
		if tween:
			tween.kill()

## 重置菜单场景
func reset_menu_scene() -> void:
	print("Resetting menu scene")
	
	# 重置菜单状态
	_set_menu_state(MenuState.MAIN)
	
	# 重置演示蛇
	# 重置演示蛇
	if demo_snake and background_grid:
		demo_snake.reset()
		demo_snake.set_paused(false)
	
	# 重新开始演示蛇移动
	_start_demo_snake_movement()
	
	# 重置UI
	if main_menu and main_menu.has_method("reset_ui"):
		main_menu.reset_ui()
	
	if settings_menu and settings_menu.has_method("reset_ui"):
		settings_menu.reset_ui()

## 获取当前菜单状态
func get_current_state() -> MenuState:
	return current_state

## 获取菜单统计信息
func get_menu_stats() -> Dictionary:
	var stats = {}
	
	if save_manager:
		stats = save_manager.get_statistics()
	
	return stats

## 播放菜单音效
func play_menu_sound(sound_type: String) -> void:
	# 这里可以添加音效播放逻辑
	print("Playing menu sound: ", sound_type)

## 设置菜单主题
func set_menu_theme(theme_name: String) -> void:
	# 这里可以添加主题切换逻辑
	print("Setting menu theme: ", theme_name)

## 应用保存的设置
func _apply_saved_settings() -> void:
	if not save_manager:
		return
	
	# 应用网格显示设置
	var grid_visible = save_manager.get_setting("grid_visible", true)
	set_background_grid_visible(grid_visible)
	
	# 应用音量设置
	var volume = save_manager.get_setting("volume", 1.0)
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		var db_value = linear_to_db(volume)
		AudioServer.set_bus_volume_db(master_bus_index, db_value)
	
	# 应用全屏设置
	var fullscreen = save_manager.get_setting("fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# 恢复到固定的窗口大小
		_restore_window_size()
	
	print("Applied saved settings to menu scene")

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

## 设置背景网格可见性
func set_background_grid_visible(visible: bool) -> void:
	if background_grid:
		background_grid.visible = visible
		background_grid.show_grid = visible
		background_grid.set_grid_lines_visible(visible)
		background_grid.set_border_visible(visible)
		print("Background grid visibility set to: ", visible)

## 获取菜单对象引用
func get_main_menu() -> MainMenu:
	return main_menu

func get_settings_menu() -> SettingsMenu:
	return settings_menu

func get_background_grid() -> Grid:
	return background_grid

func get_demo_snake() -> Snake:
	return demo_snake
