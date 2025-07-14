extends CherryBomb
class_name ygzd
@export var 阳光产量 = 15
@export var sun_scene: PackedScene
@onready var sun: Node2D = $阳光
@export var day_suns:DaySuns
var 僵尸数量 := 0

func _ready():
	super._ready()
	day_suns = get_tree().root.get_node("MainGame/DaySuns")

#region 植物死亡相关
func _plant_free():
	var 阳光植物数组 = 遍历检测("阳光植物")
	#print("发现植物: ", 阳光植物数组)
	为植物生成阳光(阳光植物数组,400)
	#原有的炸僵尸生成阳光的逻辑已经改为放置版由阳光植物生成
	#var new_sun = sun_scene.instantiate()
	#if new_sun is Sun:
		#day_suns.add_child(new_sun)
		#new_sun.sun_value = 阳光产量
		#new_sun._sun_scale(阳光产量)
		#new_sun.global_position = sun.global_position
	super._plant_free()
# 铲掉植物
func be_shovel_kill():
	plant_free_signal.emit(self)
	self.queue_free()
#endregion

func _bomb_all_area_zombie():
	var areas = area_2d_2.get_overlapping_areas()
	
	# 新增：重置僵尸数量统计
	僵尸数量 = 0
	#print("爆炸检测")
	for area in areas:
		僵尸数量 += 1
		#print("爆炸检测到对象: ", area.get_parent().name, " 类型: ", area.get_parent().get_class())
		area.get_parent().be_bomb_death()
	
# 根据僵尸数量动态调整阳光产量
	if 僵尸数量 > 0:
		if 僵尸数量 >= 10:
			阳光产量 = 50  # 僵尸数量大于等于10时阳光产量最高
		elif 僵尸数量 <= 3:
			阳光产量 = 15  # 僵尸数量较少时阳光产量最低
		else:
			阳光产量 = 5 * 僵尸数量  # 中间区间线性增长（4-9只僵尸）
	#print("爆炸：",僵尸数量)
	_bomb_particle()

# 遍历所有植物格子检测带指定标签的植物
# 参数: target_tag - 要检测的标签名称
# 返回: 符合条件的植物数量
func 遍历检测(target_tag: String) -> Array:
	var result_paths = []  # 存储符合条件的植物节点路径
	var plant_cells_node = find_parent("PlantCells")
	
	# 检查PlantCells节点是否存在
	if plant_cells_node == null:
		print("警告: 未找到PlantCells节点")
		return []
		
	# 第一层循环：遍历所有排容器(HBoxContainer)
	for row_node in plant_cells_node.get_children():
		# 过滤非HBoxContainer类型的节点
		if row_node.get_class() != "HBoxContainer":
			continue
			
		# 第二层循环：遍历当前排下的所有列容器(PlantCell)
		for cell_node in row_node.get_children():
			# 过滤非植物格子节点（可选，根据实际情况调整）
			if "PlantCell" not in cell_node.name:
				continue
				
			# 第三层循环：遍历当前格子内的所有植物
			for plant in cell_node.get_children():
				# 检查植物是否包含目标标签
				if plant.get("标签") != null and target_tag in plant.标签:
					result_paths.append(plant.get_path())  # 保存节点路径
					#print("发现带[", target_tag, "]标签的植物: ", plant.name)
	
	return result_paths  # 返回符合条件的节点路径数组


# 根据节点路径数组为每个阳光植物生成阳光
func 为植物生成阳光(paths: Array,最大值) -> void:
	var 已生成阳光数量=0
	for path in paths:
		if 已生成阳光数量 > 最大值:
			continue
		else:
			if 阳光产量 > 最大值 - 已生成阳光数量:
				阳光产量 = 最大值 - 已生成阳光数量
		
		var sun_plant = get_node_or_null(path) as Node2D
		
		# 检查节点是否存在且类型正确
		if not sun_plant or not sun_plant.is_class("Node2D"):
			print("警告: 节点不存在或类型错误 - ", path)
			continue
			
		# 生成阳光逻辑
		var new_sun = sun_scene.instantiate()
		if new_sun is Sun:
			已生成阳光数量 += 阳光产量
			day_suns.add_child(new_sun)
			new_sun.sun_value = 阳光产量
			new_sun._sun_scale(阳光产量)
			new_sun.global_position = sun_plant.global_position
			new_sun._on_button_pressed()
			#print("成功为植物生成阳光: ", sun_plant.name)
