## 音效管理器
## 负责游戏音效的播放和管理
## 作者：课程示例
## 创建时间：2025-01-16

class_name AudioManager
extends Node

# 音效类型枚举
enum SoundType { FOOD_EAT, GAME_OVER, LEVEL_UP, BUTTON_CLICK, PAUSE, MOVE, WALL_HIT, EAT_FOOD, COLLISION, MENU_CLICK, MENU_HOVER, GAME_START }

# 音效文件路径（预留，实际项目中需要音频文件）
const SOUND_PATHS: Dictionary = {
	SoundType.FOOD_EAT: "res://assets/sounds/food_eat.ogg",
	SoundType.GAME_OVER: "res://assets/sounds/game_over.ogg",
	SoundType.LEVEL_UP: "res://assets/sounds/level_up.ogg",
	SoundType.BUTTON_CLICK: "res://assets/sounds/button_click.ogg",
	SoundType.PAUSE: "res://assets/sounds/pause.ogg",
	SoundType.MOVE: "res://assets/sounds/move.ogg",
	SoundType.WALL_HIT: "res://assets/sounds/wall_hit.ogg"
}

# 音频播放器池
var audio_players: Array[AudioStreamPlayer] = []
var available_players: Array[AudioStreamPlayer] = []
var used_players: Array[AudioStreamPlayer] = []

# 音效设置
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var is_muted: bool = false

# 音效缓存
var sound_cache: Dictionary = {}

# 单例引用
static var instance: AudioManager

## 初始化音频管理器（静态方法）
static func initialize() -> void:
	if instance == null:
		instance = AudioManager.new()
		Engine.get_main_loop().current_scene.add_child(instance)

func _ready() -> void:
	if instance == null:
		instance = self
		# 设置为自动加载节点，不会被场景切换销毁
		process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		# 如果已存在实例，销毁当前节点
		queue_free()
		return
	
	# 初始化音频播放器池
	_initialize_audio_pool()
	
	# 预加载音效（如果文件存在）
	_preload_sounds()
	
	print("AudioManager initialized")

## 初始化音频播放器池
func _initialize_audio_pool(pool_size: int = 10) -> void:
	for i in range(pool_size):
		var player = AudioStreamPlayer.new()
		player.finished.connect(_on_audio_finished.bind(player))
		add_child(player)
		audio_players.append(player)
		available_players.append(player)

## 预加载音效
func _preload_sounds() -> void:
	for sound_type in SoundType.values():
		var path = SOUND_PATHS.get(sound_type, "")
		if path != "" and ResourceLoader.exists(path):
			var audio_stream = load(path)
			if audio_stream:
				sound_cache[sound_type] = audio_stream
				print("Loaded sound: ", SoundType.keys()[sound_type])
			else:
				print("Failed to load sound: ", path)
		else:
			# 创建程序化音效作为替代
			sound_cache[sound_type] = _create_procedural_sound(sound_type)

## 创建程序化音效
func _create_procedural_sound(sound_type: SoundType) -> AudioStream:
	# 创建简单的程序化音效
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.1
	
	# 根据音效类型设置不同参数
	match sound_type:
		SoundType.FOOD_EAT:
			# 吃食物：短促的高音
			pass
		SoundType.GAME_OVER:
			# 游戏结束：低沉的音调
			pass
		SoundType.LEVEL_UP:
			# 升级：上升音调
			pass
		SoundType.BUTTON_CLICK:
			# 按钮点击：短促的点击声
			pass
		_:
			pass
	
	return generator

## 播放音效（静态方法）
static func play_sound(sound_type: SoundType, volume: float = 1.0, pitch: float = 1.0) -> void:
	if not instance:
		return
	instance._play_sound_internal(sound_type, volume, pitch)

## 内部播放音效方法
func _play_sound_internal(sound_type: SoundType, volume: float = 1.0, pitch: float = 1.0) -> void:
	if is_muted:
		return
	
	# 获取可用的音频播放器
	var player = _get_available_player()
	if not player:
		print("Warning: No available audio players")
		return
	
	# 获取音效
	var audio_stream = sound_cache.get(sound_type)
	if not audio_stream:
		print("Warning: Sound not found for type: ", SoundType.keys()[sound_type])
		return
	
	# 设置播放参数
	player.stream = audio_stream
	player.volume_db = linear_to_db(master_volume * sfx_volume * volume)
	player.pitch_scale = pitch
	
	# 播放音效
	player.play()
	
	# 移动到使用中列表
	available_players.erase(player)
	used_players.append(player)

## 获取可用的音频播放器
func _get_available_player() -> AudioStreamPlayer:
	if available_players.size() > 0:
		return available_players[0]
	
	# 如果没有可用播放器，创建新的
	if audio_players.size() < 20:  # 限制最大数量
		var player = AudioStreamPlayer.new()
		player.finished.connect(_on_audio_finished.bind(player))
		add_child(player)
		audio_players.append(player)
		return player
	
	return null

## 音频播放完成回调
func _on_audio_finished(player: AudioStreamPlayer) -> void:
	if player in used_players:
		used_players.erase(player)
		available_players.append(player)

## 设置主音量（静态方法）
static func set_master_volume(volume: float) -> void:
	if instance:
		instance._set_master_volume_internal(volume)

func _set_master_volume_internal(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

## 设置音效音量（静态方法）
static func set_sfx_volume(volume: float) -> void:
	if instance:
		instance._set_sfx_volume_internal(volume)

func _set_sfx_volume_internal(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

## 更新所有播放器音量
func _update_all_volumes() -> void:
	for player in used_players:
		if player.playing:
			# 保持原有的相对音量比例
			var current_linear = db_to_linear(player.volume_db)
			var base_volume = current_linear / (master_volume * sfx_volume)
			player.volume_db = linear_to_db(master_volume * sfx_volume * base_volume)

## 静音/取消静音（静态方法）
static func set_muted(muted: bool) -> void:
	if instance:
		instance._set_muted_internal(muted)

func _set_muted_internal(muted: bool) -> void:
	is_muted = muted
	if muted:
		# 停止所有正在播放的音效
		stop_all_sounds()

## 停止所有音效（静态方法）
static func stop_all_sounds() -> void:
	if instance:
		instance._stop_all_sounds_internal()

func _stop_all_sounds_internal() -> void:
	for player in used_players:
		if player.playing:
			player.stop()
	
	# 将所有播放器移回可用列表
	available_players.append_array(used_players)
	used_players.clear()

## 停止特定类型的音效
func stop_sound_type(sound_type: SoundType) -> void:
	var audio_stream = sound_cache.get(sound_type)
	if not audio_stream:
		return
	
	for player in used_players.duplicate():
		if player.stream == audio_stream and player.playing:
			player.stop()

## 检查音效是否正在播放
func is_sound_playing(sound_type: SoundType) -> bool:
	var audio_stream = sound_cache.get(sound_type)
	if not audio_stream:
		return false
	
	for player in used_players:
		if player.stream == audio_stream and player.playing:
			return true
	
	return false

## 播放随机音调的音效
func play_sound_random_pitch(sound_type: SoundType, volume: float = 1.0, 
							  min_pitch: float = 0.8, max_pitch: float = 1.2) -> void:
	var random_pitch = randf_range(min_pitch, max_pitch)
	play_sound(sound_type, volume, random_pitch)

## 播放音效序列
func play_sound_sequence(sound_types: Array[SoundType], interval: float = 0.1) -> void:
	for i in range(sound_types.size()):
		var delay = i * interval
		get_tree().create_timer(delay).timeout.connect(
			func(): play_sound(sound_types[i])
		)

## 获取音频统计信息
func get_audio_stats() -> Dictionary:
	return {
		"total_players": audio_players.size(),
		"available_players": available_players.size(),
		"used_players": used_players.size(),
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"is_muted": is_muted,
		"cached_sounds": sound_cache.size()
	}

## 获取单例实例
static func get_instance() -> AudioManager:
	return instance

## 便捷的静态方法
static func play(sound_type: SoundType, volume: float = 1.0) -> void:
	if instance:
		instance.play_sound(sound_type, volume)

static func stop_all() -> void:
	if instance:
		instance.stop_all_sounds()

static func mute(muted: bool) -> void:
	if instance:
		instance.set_muted(muted)

## 清理资源
func _exit_tree() -> void:
	stop_all_sounds()
	sound_cache.clear()