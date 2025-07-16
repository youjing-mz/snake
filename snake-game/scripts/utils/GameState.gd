## 游戏状态类
## 负责游戏状态数据的管理和持久化
## 作者：课程示例
## 创建时间：2025-01-16

class_name GameState
extends Resource

# 游戏状态枚举
enum State { MENU, PLAYING, PAUSED, GAME_OVER }

# 导出属性（可保存）
@export var current_state: State = State.MENU
@export var score: int = 0
@export var level: int = 1
@export var high_score: int = 0
@export var game_speed: float = Constants.BASE_MOVE_SPEED
@export var foods_eaten: int = 0
@export var play_time: float = 0.0
@export var games_played: int = 0

# 信号
signal state_changed(old_state: State, new_state: State)
signal score_updated(new_score: int)
signal level_updated(new_level: int)
signal high_score_updated(new_high_score: int)

## 改变游戏状态
func change_state(new_state: State) -> void:
	var old_state = current_state
	if old_state != new_state:
		current_state = new_state
		state_changed.emit(old_state, new_state)
		print("Game state changed from ", State.keys()[old_state], " to ", State.keys()[new_state])

## 重置游戏数据
func reset_game_data() -> void:
	score = 0
	level = 1
	game_speed = Constants.BASE_MOVE_SPEED
	foods_eaten = 0
	play_time = 0.0
	
	score_updated.emit(score)
	level_updated.emit(level)
	
	print("Game data reset")

## 更新分数
func add_score(points: int) -> void:
	score += points
	foods_eaten += 1
	
	# 检查是否需要升级
	var new_level = calculate_level()
	if new_level != level:
		level = new_level
		game_speed = calculate_speed()
		level_updated.emit(level)
		print("Level up! New level: ", level)
	
	score_updated.emit(score)

## 更新最高分
func update_high_score() -> bool:
	if score > high_score:
		high_score = score
		high_score_updated.emit(high_score)
		print("New high score: ", high_score)
		return true
	return false

## 计算等级
func calculate_level() -> int:
	# 每吃10个食物升一级
	return max(1, (foods_eaten / 10) + 1)

## 计算游戏速度
func calculate_speed() -> float:
	# 每升一级速度增加10%
	var speed_multiplier = 1.0 + (level - 1) * 0.1
	return Constants.BASE_MOVE_SPEED / speed_multiplier

## 增加游戏时间
func add_play_time(delta: float) -> void:
	if current_state == State.PLAYING:
		play_time += delta

## 开始新游戏
func start_new_game() -> void:
	reset_game_data()
	games_played += 1
	change_state(State.PLAYING)

## 暂停游戏
func pause_game() -> void:
	if current_state == State.PLAYING:
		change_state(State.PAUSED)

## 恢复游戏
func resume_game() -> void:
	if current_state == State.PAUSED:
		change_state(State.PLAYING)

## 结束游戏
func end_game() -> void:
	update_high_score()
	change_state(State.GAME_OVER)

## 返回菜单
func return_to_menu() -> void:
	change_state(State.MENU)

## 获取游戏统计信息
func get_game_stats() -> Dictionary:
	return {
		"score": score,
		"high_score": high_score,
		"level": level,
		"foods_eaten": foods_eaten,
		"play_time": play_time,
		"games_played": games_played,
		"current_speed": game_speed
	}

## 检查是否为新记录
func is_new_record() -> bool:
	return score == high_score and score > 0

## 获取状态字符串
func get_state_string() -> String:
	return State.keys()[current_state]

## 检查游戏是否进行中
func is_game_active() -> bool:
	return current_state == State.PLAYING

## 检查游戏是否暂停
func is_game_paused() -> bool:
	return current_state == State.PAUSED

## 检查游戏是否结束
func is_game_over() -> bool:
	return current_state == State.GAME_OVER

## 检查是否在菜单
func is_in_menu() -> bool:
	return current_state == State.MENU