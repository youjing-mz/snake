## 主游戏场景脚本
## 负责游戏场景的整体管理和协调
## 作者：课程示例
## 创建时间：2025-01-16

class_name Game
extends Node2D

# 游戏对象引用
@onready var grid: Grid
@onready var snake: Snake
@onready var food: Food
@onready var game_ui: GameUI

# 管理器引用
var game_manager: GameManager
var scene_manager: SceneManager
var save_manager: SaveManager

# 游戏状态
var is_initialized: bool = false
var game_area_rect: Rect2

func _ready() -> void:
	# 设置节点组
	add_to_group("game_scene")
	
	# 获取管理器引用
	_get_manager_references()
	
	# 初始化游戏场景
	_initialize_game_scene()
	
	# 设置游戏区域
	_calculate_game_area()
	
	# 创建游戏对象
	_create_game_objects()
	
	# 连接信号
	_connect_signals()
	
	# 标记为已初始化
	is_initialized = true
	
	print("Game scene initialized")
	
	# 应用保存的设置
	_apply_saved_settings()
	
	# 设置游戏管理器的对象引用
	if game_manager:
		game_manager.snake = snake
		game_manager.food = food
		game_manager.grid = grid
		
		# 自动启动游戏
		game_manager.start_game()

## 获取管理器引用
func _get_manager_references() -> void:
	# 直接引用autoload单例
	game_manager = GameManager
	scene_manager = SceneManager
	save_manager = SaveManager

## 初始化游戏场景
func _initialize_game_scene() -> void:
	# 设置场景属性
	name = "GameScene"
	
	# 设置背景颜色
	RenderingServer.set_default_clear_color(GameColors.BACKGROUND_DARK)

## 计算游戏区域
func _calculate_game_area() -> void:
	# 计算游戏区域
	var viewport_size = get_viewport().get_visible_rect().size
	var grid_size = Constants.get_current_grid_size()
	var game_width = grid_size.x * GameSizes.GRID_SIZE
	var game_height = grid_size.y * GameSizes.GRID_SIZE
	
	# 居中游戏区域
	var offset_x = (viewport_size.x - game_width) / 2
	var offset_y = (viewport_size.y - game_height) / 2

	game_area_rect = Rect2(offset_x, offset_y, game_width, game_height)
	
	print("Game area: ", game_area_rect)
	print("Viewport size: ", viewport_size)
	print("Dynamic grid size: ", grid_size.x, "x", grid_size.y)

## 创建游戏对象
func _create_game_objects() -> void:
	# 创建网格
	_create_grid()
	
	# 创建蛇
	_create_snake()
	
	# 创建食物
	_create_food()
	
	# 创建UI
	_create_ui()

## 创建网格
func _create_grid() -> void:
	grid = Grid.new()
	grid.position = game_area_rect.position
	grid.add_to_group("grid")
	add_child(grid)
	
	# Grid会在_ready中自动初始化
	
	print("Grid created at position: ", grid.position)

## 创建蛇
func _create_snake() -> void:
	snake = Snake.new()
	snake.position = game_area_rect.position
	snake.add_to_group("snake")
	add_child(snake)
	
	# Snake会在_ready中自动初始化
	
	print("Snake created")

## 创建食物
func _create_food() -> void:
	food = Food.new()
	food.position = game_area_rect.position
	food.add_to_group("food")
	add_child(food)
	
	# Food会在_ready中自动初始化
	# 不在这里生成食物，等到游戏开始时再生成
	
	print("Food created")

## 获取UI引用
func _create_ui() -> void:
	# 查找场景中已有的GameUI节点
	game_ui = find_child("GameUI") as GameUI
	if not game_ui:
		print("Warning: GameUI node not found in scene")
		return
	
	print("GameUI reference obtained")

## 连接信号
func _connect_signals() -> void:
	# 连接游戏管理器信号
	if game_manager:
		game_manager.game_started.connect(_on_game_started)
		game_manager.game_paused.connect(_on_game_paused)
		game_manager.game_resumed.connect(_on_game_resumed)
		game_manager.game_over.connect(_on_game_over)
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.level_changed.connect(_on_level_changed)
	
	# 连接食物信号
	if food:
		food.food_consumed.connect(_on_food_consumed)

## 游戏开始信号处理
func _on_game_started() -> void:
	print("Game started")
	
	# 重置游戏对象
	_reset_game_objects()

## 分数变化信号处理
func _on_score_changed(new_score: int) -> void:
	if game_ui:
		game_ui.update_score(new_score)

## 等级变化信号处理
func _on_level_changed(new_level: int) -> void:
	if game_ui:
		game_ui.update_level(new_level)

## 游戏暂停信号处理
func _on_game_paused() -> void:
	print("Game paused")
	
	# 暂停游戏对象动画
	if snake:
		snake.set_paused(true)
	if food:
		food.set_paused(true)

## 游戏恢复信号处理
func _on_game_resumed() -> void:
	print("Game resumed")
	
	# 恢复游戏对象动画
	if snake:
		snake.set_paused(false)
	if food:
		food.set_paused(false)

## 游戏结束信号处理
func _on_game_over(final_score: int) -> void:
	print("Game over with score: ", final_score)
	
	# 播放游戏结束效果
	_play_game_over_effects()
	
	# 保存游戏数据
	if save_manager:
		save_manager.update_high_score(final_score)
		var current_level = game_manager.get_level() if game_manager else 1
		save_manager.record_game_completion(final_score, current_level)

## 食物被消费信号处理
func _on_food_consumed(position: Vector2i, value: int) -> void:
	print("Food consumed at: ", position, " value: ", value)
	# 播放食物被吃的视觉效果
	_play_food_eaten_effects()

## 重置游戏对象
func _reset_game_objects() -> void:
	# 重置蛇
	if snake:
		snake.reset()
	
	# 重置食物
	if food:
		food.reset()
		if snake:
			food.spawn_food(snake.get_body_positions())
	
	# 重置网格
	if grid:
		grid.clear_highlights()
	
	# 重置UI
	if game_ui:
		game_ui.reset_ui()

## 播放游戏结束效果
func _play_game_over_effects() -> void:
	# 蛇死亡动画
	if snake:
		snake.play_death_animation()
	
	# 屏幕震动效果
	_play_screen_shake()
	
	# 颜色闪烁效果
	_play_color_flash()

## 播放食物被吃效果
func _play_food_eaten_effects() -> void:
	# 播放粒子效果
	_play_food_particles()
	
	# 播放分数弹出动画
	_play_score_popup()

## 播放屏幕震动
func _play_screen_shake() -> void:
	var tween = create_tween()
	var original_position = position
	
	# 震动效果
	for i in range(10):
		var shake_offset = Vector2(
			randf_range(-5, 5),
			randf_range(-5, 5)
		)
		tween.tween_property(self, "position", original_position + shake_offset, 0.05)
	
	# 恢复原位置
	tween.tween_property(self, "position", original_position, 0.1)

## 播放颜色闪烁
func _play_color_flash() -> void:
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

## 播放食物粒子效果
func _play_food_particles() -> void:
	if not food:
		return
	
	# 创建简单的粒子效果
	var particle_count = 8
	var food_world_pos = grid.grid_to_world(food.get_current_position())
	
	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = GameColors.FOOD_COLOR
		particle.position = food_world_pos
		add_child(particle)
		
		# 粒子动画
		var tween = create_tween()
		var direction = Vector2.from_angle(randf() * TAU)
		var distance = randf_range(20, 40)
		
		tween.parallel().tween_property(particle, "position", food_world_pos + direction * distance, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

## 播放分数弹出动画
func _play_score_popup() -> void:
	if not food or not game_manager:
		return
	
	# 创建分数标签
	var score_label = Label.new()
	score_label.text = "+" + str(food.get_current_value())
	score_label.position = grid.grid_to_world(food.get_current_position())
	add_child(score_label)
	
	# 弹出动画
	var tween = create_tween()
	tween.parallel().tween_property(score_label, "position:y", score_label.position.y - 30, 1.0)
	tween.parallel().tween_property(score_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(score_label.queue_free)

## 处理输入
func _input(event: InputEvent) -> void:
	if not is_initialized or not game_manager:
		return
	
	# 将输入传递给GameManager处理
	game_manager._input(event)

## 获取游戏区域
func get_game_area() -> Rect2:
	return game_area_rect

## 获取游戏对象
func get_snake() -> Snake:
	return snake

func get_food() -> Food:
	return food

func get_grid() -> Grid:
	return grid

func get_game_ui() -> GameUI:
	return game_ui

## 设置游戏对象可见性
func set_game_objects_visible(visible: bool) -> void:
	if snake:
		snake.visible = visible
	if food:
		food.visible = visible
	if grid:
		grid.visible = visible
		# 同时更新Grid内部的show_grid状态
		grid.show_grid = visible
		grid.set_grid_lines_visible(visible)
		grid.set_border_visible(visible)

## 暂停/恢复游戏对象
func set_game_objects_paused(paused: bool) -> void:
	if snake:
		snake.set_paused(paused)
	if food:
		food.set_paused(paused)

## 清理游戏场景
func cleanup_scene() -> void:
	print("Cleaning up game scene")
	
	# 停止所有动画
	var tweens = get_tree().get_nodes_in_group("tween")
	for tween in tweens:
		if tween:
			tween.kill()
	
	# 重置游戏对象
	_reset_game_objects()

## 应用保存的设置
func _apply_saved_settings() -> void:
	if not save_manager:
		return
	
	# 应用网格显示设置
	var grid_visible = save_manager.get_setting("grid_visible", true)
	if grid:
		grid.visible = grid_visible
		grid.show_grid = grid_visible
		grid.set_grid_lines_visible(grid_visible)
		grid.set_border_visible(grid_visible)
		print("Applied grid visibility setting: ", grid_visible)
	
	# 应用音量设置
	var volume = save_manager.get_setting("volume", 1.0)
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		var db_value = linear_to_db(volume)
		AudioServer.set_bus_volume_db(master_bus_index, db_value)
		print("Applied volume setting: ", volume)
	
	# 应用全屏设置
	var fullscreen = save_manager.get_setting("fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# 恢复到固定的窗口大小
		_restore_window_size()
	print("Applied fullscreen setting: ", fullscreen)

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

## 获取游戏统计信息
func get_game_stats() -> Dictionary:
	var stats = {}
	
	if game_manager:
		stats = game_manager.get_game_stats()
	
	if snake:
		stats["snake_length"] = snake.get_length()
	
	return stats
