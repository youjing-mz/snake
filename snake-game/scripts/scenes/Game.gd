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
	_setup_game_area()
	
	# 创建游戏对象
	_create_game_objects()
	
	# 连接信号
	_connect_signals()
	
	# 标记为已初始化
	is_initialized = true
	
	print("Game scene initialized")

## 获取管理器引用
func _get_manager_references() -> void:
	# 查找或创建管理器
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		game_manager = GameManager.new()
		game_manager.add_to_group("game_manager")
		add_child(game_manager)
	
	scene_manager = get_tree().get_first_node_in_group("scene_manager")
	if not scene_manager:
		scene_manager = SceneManager.new()
		scene_manager.add_to_group("scene_manager")
		add_child(scene_manager)
	
	save_manager = get_tree().get_first_node_in_group("save_manager")
	if not save_manager:
		save_manager = SaveManager.new()
		save_manager.add_to_group("save_manager")
		add_child(save_manager)

## 初始化游戏场景
func _initialize_game_scene() -> void:
	# 设置场景属性
	name = "GameScene"
	
	# 设置背景颜色
	RenderingServer.set_default_clear_color(GameColors.BACKGROUND_DARK)

## 设置游戏区域
func _setup_game_area() -> void:
	# 计算游戏区域
	var viewport_size = get_viewport().get_visible_rect().size
	var game_width = Constants.GRID_WIDTH * GameSizes.CELL_SIZE
	var game_height = Constants.GRID_HEIGHT * GameSizes.CELL_SIZE
	
	# 居中游戏区域
	var offset_x = (viewport_size.x - game_width) / 2
	var offset_y = (viewport_size.y - game_height) / 2 + GameSizes.UI_OFFSET_TOP
	
	game_area_rect = Rect2(offset_x, offset_y, game_width, game_height)
	
	print("Game area: ", game_area_rect)

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
	
	# 生成第一个食物
	food.spawn_food(snake.get_body_positions())
	
	print("Food created")

## 创建UI
func _create_ui() -> void:
	game_ui = GameUI.new()
	game_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_ui.add_to_group("game_ui")
	add_child(game_ui)
	
	print("GameUI created")

## 连接信号
func _connect_signals() -> void:
	# 连接游戏管理器信号
	if game_manager:
		game_manager.game_started.connect(_on_game_started)
		game_manager.game_paused.connect(_on_game_paused)
		game_manager.game_resumed.connect(_on_game_resumed)
		game_manager.game_over.connect(_on_game_over)
		game_manager.food_eaten.connect(_on_food_eaten)
	
	# 连接蛇的信号
	if snake:
		snake.snake_moved.connect(_on_snake_moved)
		snake.snake_died.connect(_on_snake_died)
	
	# 连接食物信号
	if food:
		food.food_eaten.connect(_on_food_eaten_animation)

## 游戏开始信号处理
func _on_game_started() -> void:
	print("Game started")
	
	# 重置游戏对象
	_reset_game_objects()
	
	# 设置游戏管理器的对象引用
	if game_manager:
		game_manager.set_game_objects(snake, food, grid)

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
		save_manager.record_game_completion(final_score)

## 食物被吃信号处理
func _on_food_eaten(food_position: Vector2i, food_value: int) -> void:
	print("Food eaten at: ", food_position, " value: ", food_value)
	
	# 生成新食物
	if food and snake:
		food.spawn_food(snake.get_body_positions())

## 蛇移动信号处理
func _on_snake_moved(new_head_position: Vector2i) -> void:
	# 检查食物碰撞
	if food and food.get_grid_position() == new_head_position:
		# 通知游戏管理器食物被吃
		if game_manager:
			game_manager.handle_food_eaten(food.get_grid_position(), food.get_food_value())

## 蛇死亡信号处理
func _on_snake_died() -> void:
	print("Snake died")
	
	# 通知游戏管理器游戏结束
	if game_manager:
		game_manager.end_game()

## 食物被吃动画信号处理
func _on_food_eaten_animation() -> void:
	# 播放食物被吃的视觉效果
	_play_food_eaten_effects()

## 重置游戏对象
func _reset_game_objects() -> void:
	# 重置蛇
	if snake:
		snake.reset()
	
	# 重置食物
	if food:
		food.reset_food()
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
	var food_world_pos = grid.grid_to_world(food.get_grid_position())
	
	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = GameColors.FOOD_NORMAL
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
	score_label.text = "+" + str(food.get_food_value())
	score_label.add_theme_font_size_override("font_size", GameSizes.FONT_SIZE_LARGE)
	score_label.add_theme_color_override("font_color", GameColors.ACCENT_GREEN)
	score_label.position = grid.grid_to_world(food.get_grid_position())
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
	
	# 方向输入
	var direction = Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		direction = Vector2i.UP
	elif event.is_action_pressed("move_down"):
		direction = Vector2i.DOWN
	elif event.is_action_pressed("move_left"):
		direction = Vector2i.LEFT
	elif event.is_action_pressed("move_right"):
		direction = Vector2i.RIGHT
	
	if direction != Vector2i.ZERO:
		game_manager.handle_direction_input(direction)
	
	# 暂停输入
	if event.is_action_pressed("pause"):
		game_manager.toggle_pause()
	
	# 调试输入
	if event.is_action_pressed("debug_restart"):
		game_manager.start_game()

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
		grid.set_visible(visible)

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

## 获取游戏统计信息
func get_game_stats() -> Dictionary:
	var stats = {}
	
	if game_manager:
		stats["score"] = game_manager.get_score()
		stats["level"] = game_manager.get_level()
		stats["speed"] = game_manager.get_speed()
	
	if snake:
		stats["snake_length"] = snake.get_length()
	
	return stats