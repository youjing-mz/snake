## 对象池
## 用于优化对象创建和销毁的性能
## 作者：课程示例
## 创建时间：2025-01-16

class_name ObjectPool
extends Node

# 对象池数据结构
var pools: Dictionary = {}

# 池配置结构
class PoolConfig:
	var create_func: Callable
	var reset_func: Callable
	var max_size: int
	var initial_size: int
	
	func _init(create: Callable, reset: Callable, initial: int = 10, maximum: int = 50):
		create_func = create
		reset_func = reset
		initial_size = initial
		max_size = maximum

# 池数据结构
class Pool:
	var available_objects: Array = []
	var used_objects: Array = []
	var config: PoolConfig
	
	func _init(pool_config: PoolConfig):
		config = pool_config
		_initialize_pool()
	
	func _initialize_pool():
		# 预创建初始对象
		for i in range(config.initial_size):
			var obj = config.create_func.call()
			if obj:
				available_objects.append(obj)
	
	func get_object():
		var obj
		if available_objects.size() > 0:
			# 从可用池中获取
			obj = available_objects.pop_back()
		else:
			# 创建新对象
			obj = config.create_func.call()
		
		if obj:
			used_objects.append(obj)
		return obj
	
	func return_object(obj):
		if obj in used_objects:
			used_objects.erase(obj)
			
			# 重置对象状态
			if config.reset_func.is_valid():
				config.reset_func.call(obj)
			
			# 检查池大小限制
			if available_objects.size() < config.max_size:
				available_objects.append(obj)
			else:
				# 池已满，销毁对象
				if obj.has_method("queue_free"):
					obj.queue_free()
				elif obj.has_method("free"):
					obj.free()
	
	func get_stats() -> Dictionary:
		return {
			"available": available_objects.size(),
			"used": used_objects.size(),
			"total": available_objects.size() + used_objects.size(),
			"max_size": config.max_size
		}
	
	func clear():
		# 清理所有对象
		for obj in available_objects:
			if obj.has_method("queue_free"):
				obj.queue_free()
			elif obj.has_method("free"):
				obj.free()
		
		for obj in used_objects:
			if obj.has_method("queue_free"):
				obj.queue_free()
			elif obj.has_method("free"):
				obj.free()
		
		available_objects.clear()
		used_objects.clear()

func _ready() -> void:
	print("ObjectPool initialized")

## 创建对象池
func create_pool(pool_name: String, create_func: Callable, reset_func: Callable, 
				 initial_size: int = 10, max_size: int = 50) -> void:
	if pool_name in pools:
		print("Warning: Pool '", pool_name, "' already exists")
		return
	
	var config = PoolConfig.new(create_func, reset_func, initial_size, max_size)
	var pool = Pool.new(config)
	pools[pool_name] = pool
	
	print("Created pool '", pool_name, "' with initial size: ", initial_size)

## 从池中获取对象
func get_object(pool_name: String):
	if not pool_name in pools:
		print("Error: Pool '", pool_name, "' does not exist")
		return null
	
	var pool = pools[pool_name] as Pool
	return pool.get_object()

## 将对象返回池中
func return_object(pool_name: String, obj) -> void:
	if not pool_name in pools:
		print("Error: Pool '", pool_name, "' does not exist")
		return
	
	if not obj:
		print("Warning: Trying to return null object to pool '", pool_name, "'")
		return
	
	var pool = pools[pool_name] as Pool
	pool.return_object(obj)

## 获取池统计信息
func get_pool_stats(pool_name: String) -> Dictionary:
	if not pool_name in pools:
		return {}
	
	var pool = pools[pool_name] as Pool
	return pool.get_stats()

## 获取所有池的统计信息
func get_all_stats() -> Dictionary:
	var all_stats = {}
	for pool_name in pools.keys():
		all_stats[pool_name] = get_pool_stats(pool_name)
	return all_stats

## 清理指定池
func clear_pool(pool_name: String) -> void:
	if not pool_name in pools:
		print("Error: Pool '", pool_name, "' does not exist")
		return
	
	var pool = pools[pool_name] as Pool
	pool.clear()
	pools.erase(pool_name)
	
	print("Cleared pool '", pool_name, "'")

## 清理所有池
func clear_all_pools() -> void:
	for pool_name in pools.keys():
		clear_pool(pool_name)
	
	print("Cleared all object pools")

## 检查池是否存在
func has_pool(pool_name: String) -> bool:
	return pool_name in pools

## 获取池中可用对象数量
func get_available_count(pool_name: String) -> int:
	if not pool_name in pools:
		return 0
	
	var pool = pools[pool_name] as Pool
	return pool.available_objects.size()

## 获取池中使用中对象数量
func get_used_count(pool_name: String) -> int:
	if not pool_name in pools:
		return 0
	
	var pool = pools[pool_name] as Pool
	return pool.used_objects.size()

## 预热池（预创建更多对象）
func warm_up_pool(pool_name: String, count: int) -> void:
	if not pool_name in pools:
		print("Error: Pool '", pool_name, "' does not exist")
		return
	
	var pool = pools[pool_name] as Pool
	for i in range(count):
		if pool.available_objects.size() < pool.config.max_size:
			var obj = pool.config.create_func.call()
			if obj:
				pool.available_objects.append(obj)
			else:
				break
	
	print("Warmed up pool '", pool_name, "' with ", count, " objects")

## 打印池状态（调试用）
func print_pool_status() -> void:
	print("=== Object Pool Status ===")
	for pool_name in pools.keys():
		var stats = get_pool_stats(pool_name)
		print("Pool '", pool_name, "': Available=", stats.available, 
			  ", Used=", stats.used, ", Total=", stats.total, 
			  ", Max=", stats.max_size)
	print("=========================")

## 节点退出时清理
func _exit_tree() -> void:
	clear_all_pools()