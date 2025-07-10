extends Control
class_name 背包

func _ready():

	初始化背包格子()

func 初始化背包格子():
	var 背包物品 = 全局放置.读取物品数组()
	var 物品索引 = 0
	for 排号 in range(1, 4):
		for 物品栏号 in range(1, 6):
			var 物品栏路径 = "背包格子/排" + str(排号) + "/物品栏" + str(物品栏号)
			if 物品索引 < 背包物品.size():
				var 物品的名称 = 背包物品[物品索引]
				设置物品栏(物品栏路径, 物品的名称)
				物品索引 += 1
			else:
				设置物品栏初始值(物品栏路径)
			

func 设置物品栏(物品栏路径: String, 物品名称: String):
	var 数量标签 = get_node(物品栏路径 + "/数量")
	var 名称标签 = get_node(物品栏路径 + "/名称")
	var 物品贴图 = get_node(物品栏路径 + "/物品图片")
	print(物品栏路径,"：",物品名称)
	print(str(全局放置.读取物品(物品名称)),"：",物品名称,"：",全局放置.加载物品贴图(物品名称))
# 安全检查
	if 数量标签 != null:
		数量标签.text = str(全局放置.读取物品(物品名称))  # 获取物品数量

	if 名称标签 != null:
		名称标签.text = 物品名称  # 使用数组中的名称

	if 物品贴图 != null:
		物品贴图.texture = 全局放置.加载物品贴图(物品名称)  # 获取物品贴图

func 设置物品栏初始值(物品栏路径: String):
	#print(物品栏路径)
	var 数量标签 = get_node(物品栏路径 + "/数量")
	var 名称标签 = get_node(物品栏路径 + "/名称")
	var 物品贴图 = get_node(物品栏路径 + "/物品图片")
	# 安全检查
	if 数量标签 != null:
		数量标签.text = ""
	if 名称标签 != null:
		名称标签.text = ""
	if 物品贴图 != null:
		#物品贴图.texture = 全局放置.加载物品贴图("金币")#金币
		物品贴图.texture = null#空


## 返回开始菜单
func _on_主菜单() -> void:
	get_tree().change_scene_to_file("res://FZB/场景/放置版主菜单.tscn")
