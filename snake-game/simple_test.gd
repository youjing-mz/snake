extends SceneTree

## 简单测试脚本 - 测试统一AI调试面板

func _init():
	print("🔧 开始统一AI调试面板测试...")
	
	# 直接切换到游戏场景
	change_scene_to_file("res://scenes/Game.tscn")
	
	print("�� 游戏场景已启动，检查调试面板功能") 