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

# 游戏状态枚举
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

# 游戏状态变量
var current_state: GameState = GameState.MENU
var score: int = 0
var level: int = 1
var game_speed: float = Constants.BASE_MOVE_SPEED
var foods_eaten: int = 0

# 游戏对象引用
var snake: Snake
var food: Food
var grid: Grid

# 游戏计时器
var game_timer: Timer
var move_timer: Timer

func _ready() -> void:
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
	move_timer.wait_time = 1.0 / game_speed
	move_timer.timeout.connect(_on_move_timer_timeout)
	add_child(move_timer)

## 连接信号
func _connect_signals() -> void:
	# 这里会在场景加载后连接具体的游戏对象信号
	pass

## 开始游戏
func start_game() -> void:
	if current_state == GameState.PLAYING:
		return
	
	print("Starting game...")
	
	# 重置游戏状态
	_reset_game_state()
	
	# 设置游戏状态
	current_state = GameState.PLAYING
	
	# 启动计时器
	game_timer.start()
	move_timer.start()
	
	# 发送游戏开始信号
	game_started.emit()

## 暂停游戏
func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return
	
	print("Pausing game...")
	
	# 设置暂停状态
	current_state = GameState.PAUSED
	
	# 停止计时器
	game_timer.stop()
	move_timer.stop()
	
	# 发送暂停信号
	game_paused.emit()

## 恢复游戏
func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return
	
	print("Resuming game...")
	
	# 设置游戏状态
	current_state = GameState.PLAYING
	
	# 重启计时器
	game_timer.start()
	move_timer.start()
	
	# 发送恢复信号
	game_resumed.emit()

## 结束游戏
func end_game() -> void:
	if current_state == GameState.GAME_OVER:
		return
	
	print("Ending game... Final score: ", score)
	
	# 设置游戏结束状态
	current_state = GameState.GAME_OVER
	
	# 停止所有计时器
	game_timer.stop()
	move_timer.stop()
	
	# 发送游戏结束信号
	game_over.emit(score)

## 更新分数
func update_score(points: int) -> void:
	score += points
	foods_eaten += 1
	
	# 检查是否需要升级
	_check_level_up()
	
	# 发送分数变化信号
	score_changed.emit(score)
	
	print("Score updated: ", score)

## 检查升级
func _check_level_up() -> void:
	var new_level = (foods_eaten / Constants.SPEED_INCREASE_INTERVAL) + 1
	if new_level > level:
		level = new_level
		_increase_speed()
		level_changed.emit(level)
		print("Level up! New level: ", level)

## 增加游戏速度
func _increase_speed() -> void:
	game_speed = min(game_speed + Constants.SPEED_INCREASE_RATE, Constants.MAX_MOVE_SPEED)
	move_timer.wait_time = 1.0 / game_speed
	print("Speed increased to: ", game_speed)

## 重置游戏状态
func _reset_game_state() -> void:
	score = 0
	level = 1
	game_speed = Constants.BASE_MOVE_SPEED
	foods_eaten = 0
	
	# 重置计时器
	move_timer.wait_time = 1.0 / game_speed

## 处理输入
func _input(event: InputEvent) -> void:
	match current_state:
		GameState.PLAYING:
			_handle_game_input(event)
		GameState.PAUSED:
			_handle_pause_input(event)

## 处理游戏中的输入
func _handle_game_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_game()
		return
	
	# 方向输入会传递给蛇对象处理
	if snake:
		if event.is_action_pressed("move_up"):
			snake.set_direction(Vector2.UP)
		elif event.is_action_pressed("move_down"):
			snake.set_direction(Vector2.DOWN)
		elif event.is_action_pressed("move_left"):
			snake.set_direction(Vector2.LEFT)
		elif event.is_action_pressed("move_right"):
			snake.set_direction(Vector2.RIGHT)

## 处理暂停状态的输入
func _handle_pause_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("confirm"):
		resume_game()
	elif event.is_action_pressed("cancel"):
		end_game()

## 游戏主循环计时器回调
func _on_game_timer_timeout() -> void:
	if current_state != GameState.PLAYING:
		return
	
	# 更新游戏逻辑
	_update_game_logic()

## 蛇移动计时器回调
func _on_move_timer_timeout() -> void:
	if current_state != GameState.PLAYING:
		return
	
	# 移动蛇
	if snake:
		snake.move()

## 更新游戏逻辑
func _update_game_logic() -> void:
	# 检查碰撞
	_check_collisions()
	
	# 更新游戏对象
	if snake:
		snake.update_display()
	if food:
		food.update_display()

## 检查碰撞
func _check_collisions() -> void:
	if not snake:
		return
	
	# 检查墙壁碰撞
	if _check_wall_collision():
		end_game()
		return
	
	# 检查自身碰撞
	if _check_self_collision():
		end_game()
		return
	
	# 检查食物碰撞
	if _check_food_collision():
		_handle_food_eaten()

## 检查墙壁碰撞
func _check_wall_collision() -> bool:
	var head_pos = snake.get_head_position()
	return (head_pos.x < 0 or head_pos.x >= Constants.GRID_WIDTH or 
			head_pos.y < 0 or head_pos.y >= Constants.GRID_HEIGHT)

## 检查自身碰撞
func _check_self_collision() -> bool:
	return snake.check_self_collision()

## 检查食物碰撞
func _check_food_collision() -> bool:
	if not food:
		return false
	return snake.get_head_position() == food.get_food_position()

## 处理食物被吃
func _handle_food_eaten() -> void:
	# 蛇增长
	snake.grow()
	
	# 更新分数
	update_score(Constants.FOOD_SCORE)
	
	# 生成新食物
	if food:
		food.spawn_new_food(snake.get_body_positions())

## 获取当前游戏状态
func get_current_state() -> GameState:
	return current_state

## 获取当前分数
func get_score() -> int:
	return score

## 获取当前等级
func get_level() -> int:
	return level

## 获取当前速度
func get_speed() -> float:
	return game_speed