## 场景管理器
## 负责游戏场景的切换和管理
## 作者：课程示例
## 创建时间：2025-01-16

extends Node

# 场景切换信号
signal scene_changed(scene_name: String)

# 场景类型枚举
enum SceneType { MENU, GAME, SETTINGS, GAME_OVER }

# 场景路径映射
const SCENE_PATHS: Dictionary = {
	SceneType.MENU: "res://scenes/Menu.tscn",
	SceneType.GAME: "res://scenes/Game.tscn",
	SceneType.SETTINGS: "res://scenes/Settings.tscn",
	SceneType.GAME_OVER: "res://scenes/GameOver.tscn"
}

# 当前场景引用
var current_scene: Node
var current_scene_type: SceneType = SceneType.MENU

# 场景切换动画时间
const TRANSITION_TIME: float = 0.3

func _ready() -> void:
	# 获取当前场景
	current_scene = get_tree().current_scene
	print("SceneManager initialized")

## 切换到指定场景
func change_scene(scene_type: SceneType) -> void:
	if scene_type == current_scene_type:
		return
	
	var scene_path = SCENE_PATHS.get(scene_type)
	if scene_path == null:
		print("Error: Invalid scene type: ", scene_type)
		return
	
	print("Changing scene to: ", scene_path)
	
	# 执行场景切换
	_perform_scene_change(scene_path, scene_type)

## 执行场景切换的内部方法
func _perform_scene_change(scene_path: String, scene_type: SceneType) -> void:
	# 加载新场景
	var new_scene = load(scene_path)
	if new_scene == null:
		print("Error: Failed to load scene: ", scene_path)
		return
	
	# 释放当前场景
	if current_scene:
		current_scene.queue_free()
	
	# 实例化新场景
	current_scene = new_scene.instantiate()
	current_scene_type = scene_type
	
	# 添加到场景树
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	
	# 发送场景切换信号
	scene_changed.emit(get_scene_name(scene_type))

## 获取当前场景
func get_current_scene() -> Node:
	return current_scene

## 获取当前场景类型
func get_current_scene_type() -> SceneType:
	return current_scene_type

## 根据场景类型获取场景名称
func get_scene_name(scene_type: SceneType) -> String:
	match scene_type:
		SceneType.MENU:
			return "Menu"
		SceneType.GAME:
			return "Game"
		SceneType.SETTINGS:
			return "Settings"
		SceneType.GAME_OVER:
			return "GameOver"
		_:
			return "Unknown"

## 重新加载当前场景
func reload_current_scene() -> void:
	change_scene(current_scene_type)

## 退出游戏
func quit_game() -> void:
	print("Quitting game...")
	get_tree().quit()