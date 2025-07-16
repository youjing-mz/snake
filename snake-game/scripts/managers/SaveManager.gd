## 存档管理器
## 负责游戏数据的保存和加载
## 作者：课程示例
## 创建时间：2025-01-16

extends Node

# 存档数据类
class SaveData:
	var high_score: int = 0
	var games_played: int = 0
	var total_score: int = 0
	var best_level: int = 1
	var settings: Dictionary = {
		"sound_enabled": true,
		"music_enabled": true,
		"difficulty": "normal"
	}
	var achievements: Array[String] = []
	var last_played: String = ""
	
	## 转换为字典格式
	func to_dict() -> Dictionary:
		return {
			"high_score": high_score,
			"games_played": games_played,
			"total_score": total_score,
			"best_level": best_level,
			"settings": settings,
			"achievements": achievements,
			"last_played": last_played,
			"version": "1.0.0"
		}
	
	## 从字典加载数据
	func from_dict(data: Dictionary) -> void:
		high_score = data.get("high_score", 0)
		games_played = data.get("games_played", 0)
		total_score = data.get("total_score", 0)
		best_level = data.get("best_level", 1)
		settings = data.get("settings", {
			"sound_enabled": true,
			"music_enabled": true,
			"difficulty": "normal"
		})
		var temp_achievements = data.get("achievements", [])
		achievements.assign(temp_achievements.filter(func(x): return x is String))
		last_played = data.get("last_played", "")

# 当前存档数据
var current_save_data: SaveData

# 自动保存间隔（秒）
const AUTO_SAVE_INTERVAL: float = 30.0
var auto_save_timer: Timer

func _ready() -> void:
	# 初始化存档数据
	current_save_data = SaveData.new()
	
	# 设置自动保存计时器
	_setup_auto_save()
	
	# 加载存档数据
	load_game_data()
	
	print("SaveManager initialized")

## 设置自动保存
func _setup_auto_save() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.timeout.connect(_on_auto_save_timeout)
	auto_save_timer.autostart = true
	add_child(auto_save_timer)

## 保存游戏数据
func save_game_data(data: SaveData = null) -> bool:
	if data == null:
		data = current_save_data
	
	# 更新最后游戏时间
	data.last_played = Time.get_datetime_string_from_system()
	
	# 创建文件
	var file = FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		print("Error: Cannot create save file")
		return false
	
	# 转换为JSON并保存
	var json_string = JSON.stringify(data.to_dict())
	file.store_string(json_string)
	file.close()
	
	print("Game data saved successfully")
	return true

## 加载游戏数据
func load_game_data() -> SaveData:
	if not has_save_file():
		print("No save file found, using default data")
		return current_save_data
	
	# 打开文件
	var file = FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		print("Error: Cannot open save file")
		return current_save_data
	
	# 读取JSON数据
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error: Invalid save file format")
		return current_save_data
	
	# 加载数据
	current_save_data.from_dict(json.data)
	print("Game data loaded successfully")
	return current_save_data

## 检查是否存在存档文件
func has_save_file() -> bool:
	return FileAccess.file_exists(Constants.SAVE_FILE_PATH)

## 删除存档文件
func delete_save_file() -> bool:
	if not has_save_file():
		return true
	
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists(Constants.SAVE_FILE_PATH):
		var error = dir.remove(Constants.SAVE_FILE_PATH)
		if error == OK:
			print("Save file deleted")
			return true
		else:
			print("Error: Failed to delete save file")
			return false
	else:
		print("Save file not found")
		return true

## 更新最高分
func update_high_score(new_score: int) -> bool:
	if new_score > current_save_data.high_score:
		current_save_data.high_score = new_score
		print("New high score: ", new_score)
		return true
	return false

## 记录游戏完成
func record_game_completion(score: int, level: int) -> void:
	current_save_data.games_played += 1
	current_save_data.total_score += score
	
	if level > current_save_data.best_level:
		current_save_data.best_level = level
	
	# 检查成就
	_check_achievements(score, level)
	
	# 自动保存
	save_game_data()

## 检查成就
func _check_achievements(score: int, level: int) -> void:
	var new_achievements: Array[String] = []
	
	# 首次游戏
	if current_save_data.games_played == 1 and not "first_game" in current_save_data.achievements:
		new_achievements.append("first_game")
	
	# 高分成就
	if score >= 100 and not "score_100" in current_save_data.achievements:
		new_achievements.append("score_100")
	
	if score >= 500 and not "score_500" in current_save_data.achievements:
		new_achievements.append("score_500")
	
	# 等级成就
	if level >= 5 and not "level_5" in current_save_data.achievements:
		new_achievements.append("level_5")
	
	# 游戏次数成就
	if current_save_data.games_played >= 10 and not "games_10" in current_save_data.achievements:
		new_achievements.append("games_10")
	
	# 添加新成就
	for achievement in new_achievements:
		current_save_data.achievements.append(achievement)
		print("Achievement unlocked: ", achievement)

## 获取设置值
func get_setting(key: String, default_value = null):
	return current_save_data.settings.get(key, default_value)

## 设置设置值
func set_setting(key: String, value) -> void:
	current_save_data.settings[key] = value

## 获取统计数据
func get_statistics() -> Dictionary:
	return {
		"high_score": current_save_data.high_score,
		"games_played": current_save_data.games_played,
		"total_score": current_save_data.total_score,
		"best_level": current_save_data.best_level,
		"achievements_count": current_save_data.achievements.size(),
		"average_score": current_save_data.total_score / max(1, current_save_data.games_played)
	}

## 获取成就列表
func get_achievements() -> Array[String]:
	return current_save_data.achievements

## 自动保存计时器回调
func _on_auto_save_timeout() -> void:
	save_game_data()

## 获取当前存档数据
func get_save_data() -> SaveData:
	return current_save_data

## 重置所有数据
func reset_all_data() -> bool:
	current_save_data = SaveData.new()
	return save_game_data()