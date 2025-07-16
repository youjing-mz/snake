## 游戏管理器
## 负责游戏状态管理和核心逻辑控制
## 作者：课程示例
## 创建时间：2025-01-16

extends Node

# 游戏状态信号
signal game_started
signal game_over(final_score: int)
signal score_changed(new_score: int)
signal level_changed(new_level: int)
signal game_paused
signal game_resumed

# 游戏状态管理
var game_state: GameState

# 游戏对象引用
var snake: Snake
var food: Food
var grid: Grid

# 游戏计时器
var game_timer: Timer
var move_timer: Timer

func _ready() -> void:
	# 初始化游戏状态
	game_state = GameState.new()
	
	# 初始化音频管理器
	AudioManager.initialize()
	
	# 初始化计时器
	_setup_timers()
	
	# 连接信号
	_connect_signals()
	
	print("GameManager initialized")

## 设置计时器
func _setup_timers() -> void:
	# 游戏主循环计时器
	game_timer = Timer.new()
	game_timer.wait_time = 1.0 / 60.0  # 60 FPS
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	# 蛇移动计时器
	move_timer = Timer.new()
	move_timer.wait_time = 1.0 / Constants.BASE_MOVE_SPEED
	move_timer.timeout.connect(_on_move_timer_timeout)
	add_child(move_timer)

## 连接信号
func _connect_signals() -> void:
	# 这里会在场景加载后连接具体的游戏对象信号
	pass

## 开始游戏
func start_game() -> void:
	if game_state.current_state == GameState.State.PLAYING:
		return
	
	print("Starting game...")
	
	# 开始新游戏（包含重置和状态切换）
	game_state.start_new_game()
	
	# 更新移动速度
	_update_move_speed()
	
	# 启动计时器
	game_timer.start()
	move_timer.start()
	
	# 播放开始音效
	AudioManager.play_sound(AudioManager.SoundType.GAME_START)
	
	# 发送游戏开始信号
	game_started.emit()

## 暂停游戏
func pause_game() -> void:
	if game_state.current_state != GameState.State.PLAYING:
		return
	
	print("Pausing game...")
	
	# 暂停游戏
	game_state.pause_game()
	
	# 停止计时器
	game_timer.stop()
	move_timer.stop()
	
	# 发送暂停信号
	game_paused.emit()

## 恢复游戏
func resume_game() -> void:
	if game_state.current_state != GameState.State.PAUSED:
		return
	
	print("Resuming game...")
	
	# 恢复游戏
	game_state.resume_game()
	
	# 重启计时器
	game_timer.start()
	move_timer.start()
	
	# 发送恢复信号
	game_resumed.emit()

## 结束游戏
func end_game() -> void:
	if game_state.current_state == GameState.State.GAME_OVER:
		return
	
	print("Ending game... Final score: ", game_state.score)
	
	# 结束游戏
	game_state.end_game()
	
	# 停止所有计时器
	game_timer.stop()
	move_timer.stop()
	
	# 播放游戏结束音效
	AudioManager.play_sound(AudioManager.SoundType.GAME_OVER)
	
	# 发送游戏结束信号
	game_over.emit(game_state.score)

## 更新分数
func update_score(points: int) -> void:
	# 更新分数（add_score会自动处理等级升级）
	game_state.add_score(points)
	
	# 更新移动速度
	_update_move_speed()
	
	# 发送分数变化信号
	score_changed.emit(game_state.score)
	
	print("Score updated: ", game_state.score)

## 更新移动速度
func _update_move_speed() -> void:
	game_state.game_speed = game_state.calculate_speed()
	move_timer.wait_time = 1.0 / game_state.game_speed
	if snake:
		snake.set_move_speed(game_state.game_speed)
	print("Speed updated to: ", game_state.game_speed)

## 处理输入
func _input(event: InputEvent) -> void:
	match game_state.current_state:
		GameState.State.PLAYING:
			_handle_game_input(event)
		GameState.State.PAUSED:
			_handle_pause_input(event)

## 处理游戏中的输入
func _handle_game_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_game()
		return
	
	# 方向输入会传递给蛇对象处理
	if snake:
		if event.is_action_pressed("move_up"):
			snake.change_direction(Vector2.UP)
		elif event.is_action_pressed("move_down"):
			snake.change_direction(Vector2.DOWN)
		elif event.is_action_pressed("move_left"):
			snake.change_direction(Vector2.LEFT)
		elif event.is_action_pressed("move_right"):
			snake.change_direction(Vector2.RIGHT)

## 处理暂停状态的输入
func _handle_pause_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("confirm"):
		resume_game()
	elif event.is_action_pressed("cancel"):
		end_game()

## 游戏主循环计时器回调
func _on_game_timer_timeout() -> void:
	if game_state.current_state != GameState.State.PLAYING:
		return
	
	# 更新游戏逻辑
	_update_game_logic()

## 蛇移动计时器回调
func _on_move_timer_timeout() -> void:
	if game_state.current_state != GameState.State.PLAYING:
		return
	
	# 移动蛇
	if snake:
		snake.move()
		# 移动后检查碰撞
		_check_collisions()

## 更新游戏逻辑
func _update_game_logic() -> void:
	# 更新游戏时间
	game_state.add_play_time(get_process_delta_time())
	
	# 更新游戏对象显示
	if snake:
		snake.update_display()
	if food:
		food.update_display()

## 检查碰撞
func _check_collisions() -> void:
	if not snake or not grid:
		return
	
	# 使用CollisionDetector进行综合碰撞检测
	var collision_result = CollisionDetector.detect_collision(
		snake.get_head_position(),
		snake.get_body_positions(),
		food.get_current_position(),
		food.is_active(),
		grid.grid_width,
		grid.grid_height
	)
	
	match collision_result:
		CollisionDetector.CollisionType.WALL:
			AudioManager.play_sound(AudioManager.SoundType.COLLISION)
			end_game()
			return
		CollisionDetector.CollisionType.SELF:
			AudioManager.play_sound(AudioManager.SoundType.COLLISION)
			end_game()
			return
		CollisionDetector.CollisionType.FOOD:
			_handle_food_eaten()
			return
		CollisionDetector.CollisionType.NONE:
			# 无碰撞，继续游戏
			pass

## 处理食物被吃
func _handle_food_eaten() -> void:
	# 获取食物价值
	var food_value = food.get_current_value()
	
	# 消费食物
	food.consume_food()
	
	# 蛇增长
	snake.grow()
	
	# 更新分数
	update_score(food_value)
	
	# 播放吃食物音效
	AudioManager.play_sound(AudioManager.SoundType.EAT_FOOD)
	
	# 生成新食物
	if food:
		food.spawn_food(snake.get_body_positions())

## 获取当前游戏状态
func get_current_state() -> GameState.State:
	return game_state.current_state

## 获取当前分数
func get_score() -> int:
	return game_state.score

## 获取当前等级
func get_level() -> int:
	return game_state.level

## 获取当前速度
func get_speed() -> float:
	return game_state.game_speed

## 获取游戏统计信息
func get_game_stats() -> Dictionary:
	return game_state.get_game_stats()
