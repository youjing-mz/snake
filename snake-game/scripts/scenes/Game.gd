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

# AI系统引用
var ai_player: AIPlayer
var ai_snake: Snake
var ai_debug_visualizer: AIDebugVisualizer

# 管理器引用
var game_manager: GameManager
var scene_manager: SceneManager
var save_manager: SaveManager

# 游戏状态
var is_initialized: bool = false
var game_area_rect: Rect2
var is_ai_battle_mode: bool = false
var ai_config: Dictionary = {}

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
	
	# 检查游戏模式
	_check_game_mode()
	
	# 标记为已初始化
	is_initialized = true
	
	print("Game scene initialized - Mode: ", "AI Battle" if is_ai_battle_mode else "Single Player")
	
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
	
	# 暂停AI蛇移动
	var ai_move_timer = find_child("AIMoveTimer")
	if ai_move_timer:
		ai_move_timer.stop()
	
	# 暂停AI决策
	if ai_player:
		ai_player.set_paused(true)

## 游戏恢复信号处理
func _on_game_resumed() -> void:
	print("Game resumed")
	
	# 恢复游戏对象动画
	if snake:
		snake.set_paused(false)
	if food:
		food.set_paused(false)
	
	# 恢复AI蛇移动
	var ai_move_timer = find_child("AIMoveTimer")
	if ai_move_timer:
		ai_move_timer.start()
	
	# 恢复AI决策
	if ai_player:
		ai_player.set_paused(false)

## 游戏结束信号处理
func _on_game_over(final_score: int) -> void:
	print("Game over with score: ", final_score)
	
	# 停止AI蛇移动
	var ai_move_timer = find_child("AIMoveTimer")
	if ai_move_timer:
		ai_move_timer.stop()
	
	# 停止AI决策
	if ai_player:
		ai_player.stop_ai()
	
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
	
	# 重新初始化AI系统（如果是AI模式）
	if is_ai_battle_mode:
		_reinitialize_ai_system()

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
	
	# 添加AI统计信息
	if is_ai_battle_mode and ai_player:
		stats["ai_stats"] = ai_player.get_ai_stats()
	
	return stats

## 检查游戏模式
func _check_game_mode() -> void:
	if save_manager:
		var game_mode = save_manager.get_setting("game_mode", "single_player")
		is_ai_battle_mode = (game_mode == "ai_battle")
		
		if is_ai_battle_mode:
			# 获取AI配置
			ai_config = {
				"difficulty": save_manager.get_setting("ai_difficulty", 1),
				"debug_enabled": save_manager.get_setting("ai_debug_enabled", false)
			}
			
			# 创建AI系统
			_create_ai_system()

## 创建AI系统
func _create_ai_system() -> void:
	if not is_ai_battle_mode:
		return
	
	print("Creating AI system with config: ", ai_config)
	
	# 创建AI蛇
	_create_ai_snake()
	
	# 创建AI玩家
	_create_ai_player()
	
	# 创建AI调试可视化器（如果启用）
	if ai_config.get("debug_enabled", false):
		_create_ai_debug_visualizer()

## 创建AI蛇
func _create_ai_snake() -> void:
	ai_snake = Snake.new()
	ai_snake.name = "AISnake"
	ai_snake.add_to_group("ai_snake")
	
	# 设置AI蛇的起始位置（与玩家蛇不同）
	var grid_size = Constants.get_current_grid_size()
	var ai_start_pos = Vector2(grid_size.x - 5, int(grid_size.y / 2))  # 右侧中央
	
	# 设置AI蛇的外观（不同颜色）
	ai_snake.snake_color = GameColors.ACCENT_RED  # 红色AI蛇
	
	# 直接添加到游戏场景
	add_child(ai_snake)
	
	# 初始化AI蛇（在添加到场景后）
	ai_snake.initialize_snake(ai_start_pos, Vector2.LEFT)  # 向左移动
	
	# 设置AI蛇的位置到游戏区域
	ai_snake.position = game_area_rect.position
	
	# 确保AI蛇可见且在最上层
	ai_snake.visible = true
	ai_snake.z_index = 10  # 确保在其他元素之上
	
	# 强制更新视觉显示
	ai_snake.update_display()
	
	print("AI snake created at position: ", ai_start_pos)
	print("AI snake added to scene, visible: ", ai_snake.visible)
	print("AI snake world position: ", ai_snake.position)
	print("AI snake z_index: ", ai_snake.z_index)
	print("AI snake color: ", ai_snake.snake_color)

## 创建AI玩家
func _create_ai_player() -> void:
	ai_player = AIPlayer.new()
	ai_player.name = "AIPlayer"
	
	# 设置AI难度
	var difficulty = ai_config.get("difficulty", 1)
	ai_player.set_difficulty(difficulty)
	
	# 连接AI信号
	ai_player.ai_decision_made.connect(_on_ai_decision_made)
	ai_player.ai_died.connect(_on_ai_died)
	ai_player.ai_stats_updated.connect(_on_ai_stats_updated)
	
	# 启动AI
	ai_player.start_ai(ai_snake)
	
	# 添加到场景
	add_child(ai_player)
	
	# 创建AI蛇的移动计时器
	_create_ai_move_timer()
	
	print("AI player created with difficulty: ", AIPlayer.Difficulty.keys()[difficulty])

## 创建AI移动计时器
func _create_ai_move_timer() -> void:
	if not ai_snake:
		return
	
	# 创建AI蛇的移动计时器
	var ai_move_timer = Timer.new()
	ai_move_timer.name = "AIMoveTimer"
	ai_move_timer.wait_time = 1.0 / Constants.BASE_MOVE_SPEED  # 与玩家蛇相同的速度
	ai_move_timer.timeout.connect(_on_ai_move_timer_timeout)
	ai_move_timer.autostart = true
	add_child(ai_move_timer)
	
	print("AI move timer created with interval: ", ai_move_timer.wait_time)

## AI移动计时器回调
func _on_ai_move_timer_timeout() -> void:
	if not ai_snake or not ai_snake.is_snake_alive():
		return
	
	# 移动AI蛇
	ai_snake.move()
	
	# 检查AI蛇的碰撞
	_check_ai_collisions()
	
	# 调试信息：打印AI蛇位置
	if ai_snake and ai_snake.get_body_positions().size() > 0:
		var head_pos = ai_snake.get_head_position()
		print("AI snake moved to: ", head_pos, " direction: ", ai_snake.get_direction())

## 检查AI蛇碰撞
func _check_ai_collisions() -> void:
	if not ai_snake or not grid:
		return
	
	# 使用CollisionDetector进行综合碰撞检测
	var collision_result = CollisionDetector.detect_collision(
		ai_snake.get_head_position(),
		ai_snake.get_body_positions(),
		food.get_current_position() if food else Vector2(-1, -1),
		food.is_active() if food else false,
		grid.grid_width,
		grid.grid_height
	)
	
	match collision_result:
		CollisionDetector.CollisionType.WALL:
			print("AI snake hit wall")
			ai_snake.kill()
			if ai_player:
				ai_player.stop_ai()
			return
		CollisionDetector.CollisionType.SELF:
			print("AI snake hit itself")
			ai_snake.kill()
			if ai_player:
				ai_player.stop_ai()
			return
		CollisionDetector.CollisionType.FOOD:
			_handle_ai_food_eaten()
			return
		CollisionDetector.CollisionType.NONE:
			# 无碰撞，继续游戏
			pass

## 处理AI蛇吃食物
func _handle_ai_food_eaten() -> void:
	if not ai_snake or not food:
		return
	
	# 获取食物价值
	var food_value = food.get_current_value()
	
	# 消费食物
	food.consume_food()
	
	# AI蛇增长
	ai_snake.grow()
	
	# 更新AI分数
	if ai_player:
		ai_player.update_score(food_value)
	
	# 生成新食物
	if food:
		food.spawn_food(snake.get_body_positions() + ai_snake.get_body_positions())

## 创建AI调试可视化器
func _create_ai_debug_visualizer() -> void:
	ai_debug_visualizer = AIDebugVisualizer.new()
	ai_debug_visualizer.name = "AIDebugVisualizer"
	
	# 设置AI玩家引用
	ai_debug_visualizer.set_ai_player(ai_player)
	
	# 设置位置到游戏区域
	ai_debug_visualizer.position = game_area_rect.position
	
	# 启用调试可视化
	ai_debug_visualizer.toggle_debug_visualization()
	
	# 设置可视化选项
	ai_debug_visualizer.set_visualization_options({
		"show_path": true,
		"show_safety_zones": true,
		"show_decision_scores": true,
		"show_thinking_process": true
	})
	
	# 添加到场景
	add_child(ai_debug_visualizer)
	
	print("AI debug visualizer created and enabled")
	print("AI debug visualizer position: ", ai_debug_visualizer.position)
	print("AI debug visualizer visible: ", ai_debug_visualizer.visible)

## AI决策信号处理
func _on_ai_decision_made(direction: Vector2, reasoning: String) -> void:
	print("AI decided to move: ", direction, " - ", reasoning)

## AI死亡信号处理
func _on_ai_died(survival_time: float, score: int) -> void:
	print("AI died after ", survival_time, " seconds with score ", score)
	
	# 可以在这里处理AI死亡后的逻辑，比如宣布玩家获胜
	if game_ui and game_ui.has_method("show_ai_defeat_message"):
		game_ui.show_ai_defeat_message(survival_time, score)

## AI统计更新信号处理
func _on_ai_stats_updated(stats: Dictionary) -> void:
	# 可以在这里更新UI显示AI统计信息
	pass

## 处理输入（添加AI调试控制）
func _unhandled_input(event: InputEvent) -> void:
	if not is_ai_battle_mode:
		return
	
	# 调试快捷键
	if event.is_action_pressed("ui_accept") and Input.is_action_pressed("ui_cancel"):
		# Ctrl+Enter: 切换AI调试可视化
		if ai_debug_visualizer:
			ai_debug_visualizer.toggle_debug_visualization()
	
	if event.is_action_pressed("ui_right") and Input.is_action_pressed("ui_cancel"):
		# Ctrl+Right: 强制AI立即决策
		if ai_player:
			ai_player.force_decision()

## 清理AI系统
func _cleanup_ai_system() -> void:
	# 停止AI移动计时器
	var ai_move_timer = find_child("AIMoveTimer")
	if ai_move_timer:
		ai_move_timer.queue_free()
	
	if ai_player:
		ai_player.stop_ai()
		ai_player.queue_free()
		ai_player = null
	
	if ai_snake:
		ai_snake.queue_free()
		ai_snake = null
	
	if ai_debug_visualizer:
		ai_debug_visualizer.queue_free()
		ai_debug_visualizer = null
	
	print("AI system cleaned up")

## 重新初始化AI系统
func _reinitialize_ai_system() -> void:
	print("Reinitializing AI system...")
	
	# 清理旧的AI系统
	_cleanup_ai_system()
	
	# 重新创建AI系统
	_create_ai_system()
	
	print("AI system reinitialized")

## 场景退出时清理
func _exit_tree() -> void:
	_cleanup_ai_system()
