extends Node
class_name 放置版管理

# 存档路径
const 存档地址 = "user://放置版存档.json"

# 存档数据结构
var 放置版存档 = {
	"植物数据": [
		{
			"名称": "豌豆射手",
			"解锁": true,
			"植物碎片": 0,
			"升星等级": 0,
			"精通等级": 0,
			"精通": 0
		}
	],
	"物品": {
		"金币": 100,
		"豌豆": 1
	},
	"关卡": {
		"前院告急1-1":{
			"通关次数":0,
			"最高评分":0,
			"奖杯":[],
			"自动种植方案A":{
				"植物方阵":[],
				"种植策略":[]
		},
	}
	},
	"存档版本":1.0
}

#region 物品管理
# 物品系统单例 - 管理所有物品信息和操作

# 物品类型枚举
enum 物品类型 {
	精通道具,
	任务物品,
	货币
}

# 物品定义
#class_name 物品数据
var 物品名称: String
var 物品贴图路径: String
var 物品缩放比例: float = 1.0
var 物品的类型: int
var 物品参数: Dictionary

# 所有物品的注册表
var 物品注册表 = {}

# 初始化物品注册表
#func _ready():
	#注册物品("金币", "res://assets/icons/coin.png", 物品类型.货币, {"价值": 1})
	#注册物品("精通药水", "res://assets/icons/mastery_potion.png", 物品类型.精通养成道具, {"精通值": 100})
	#注册物品("力量之戒", "res://assets/icons/ring_strength.png", 物品类型.装备, {"攻击力": 15, "防御力": 5}, 0.8)
	#注册物品("任务卷轴", "res://assets/icons/quest_scroll.png", 物品类型.任务物品, {"任务ID": 101})
	#注册物品("经验药水", "res://assets/icons/exp_potion.png", 物品类型.消耗品, {"经验值": 500})

# 注册新物品
func 注册新物品(名称: String, 贴图路径: String, 类型: int, 参数: Dictionary, 缩放比例: float = 1.0):
	var 新物品 = 放置版管理.new()
	新物品.物品名称 = 名称
	新物品.物品贴图路径 = 贴图路径
	新物品.物品缩放比例 = 缩放比例
	新物品.物品的类型 = 类型
	新物品.物品参数 = 参数
	
	物品注册表[名称] = 新物品
	print("已注册物品: ", 名称)

# 获取物品信息
func 获取物品注册信息(名称: String) -> 放置版管理:
	if 名称 in 物品注册表:
		return 物品注册表[名称]
	print("错误: 未找到物品 - ", 名称)
	return null

# 获取物品类型名称
func 获取物品类型名称(类型: int) -> String:
	match 类型:
		物品类型.精通道具: return "精通道具"
		物品类型.任务物品: return "任务物品"
		物品类型.货币: return "货币"
	return "未知类型"

# 加载物品贴图
func 加载物品贴图(名称: String) -> Texture2D:
	var 物品 = 获取物品注册信息(名称)
	if 物品:
		return load(物品.物品贴图路径)
	return null
#endregion
# 初始化存档系统
func _ready():
	加载存档()
	注册新物品("金币", "res://assets/ZJ/reanim/coin_gold_dollar.png", 物品类型.货币, {"价值": 1})
	注册新物品("豌豆", "res://assets/ZJ/images/ProjectilePea.png", 物品类型.精通道具, {"精通值": 100,"突破率":0.15})
	注册新物品("寒冰豌豆", "res://assets/ZJ/images/ProjectileSnowPea.png", 物品类型.精通道具, {"精通值": 125,"突破率":0.15})
	注册新物品("图鉴", "res://assets/ZJ/images/Almanac.png", 物品类型.任务物品, {})
	print("读取到的参数:",读取物品数组())

	
# 从文件加载存档
func 加载存档() -> bool:
	var file = FileAccess.open(存档地址, FileAccess.READ)

	if file != null:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			放置版存档 = json.get_data()
			
			# 新增：检查并初始化键（兼容旧存档）
			var 存档修复次数 = 0
			if "植物数据" not in 放置版存档:
				放置版存档["植物数据"] = {}  # 创建空的植物数据字典
				存档修复次数+=1
				print("存档修复：添加植物数据")
			if "物品" not in 放置版存档:
				放置版存档["物品"] = {}  # 创建空的物品字典
				存档修复次数+=1
				print("存档修复：添加物品")
			if "关卡" not in 放置版存档:
				放置版存档["关卡"] = {}  # 创建空的关卡字典
				存档修复次数+=1
				print("存档修复：添加关卡")
			file.close()
			if 存档修复次数 != 0:
				保存存档()
				print("检测到存档损坏，已修复并保存。
存档修复次数:",存档修复次数)
			print("存档加载成功")
			return true
		else:
			print("JSON解析错误")
		file.close()

	print("存档文件不存在或加载失败，创建新存档")
	保存存档()
	return false
	
# 保存存档到文件
func 保存存档() -> bool:
	var file = FileAccess.open(存档地址, FileAccess.WRITE)
	
	if file != null:
		# 将存档数据转换为JSON字符串（关键修复：print() 改为 stringify()）
		var json = JSON.new()
		var json_string = json.stringify(放置版存档)  # 这里是修复的地方
		file.store_string(json_string)
		file.close()
		print("存档保存成功")
		return true
	else:
		print("无法保存存档文件")
		return false

# ========== 植物数据管理方法 ==========

# 获取所有植物数据
func 获取所有植物数据() -> Array:
	return 放置版存档["植物数据"]

# 根据名称查找植物数据
func 获取存档植物(name: String) -> Dictionary:
	for plant in 放置版存档["植物数据"]:
		if plant["名称"] == name:
			return plant
	return {}  # 返回空字典而不是null

# 添加新植物
func 新建植物(植物: String) -> bool:
	# 检查植物是否已存在
	if 获取存档植物(植物) != {}:  # 修复：之前判断null，现在应为空字典
		print("植物已存在:", 植物)
		return false
	
	# 添加新植物
	var new_plant = {
		"名称": 植物,
		"解锁": false,
		"植物碎片": 0,
		"升星等级": 0,
		"精通等级": 0,
		"精通": 0
	}
	
	放置版存档["植物数据"].append(new_plant)
	保存存档()  # 保存更改
	return true

# 解锁植物
func 解锁植物(植物: String) -> bool:
	var plant = 获取存档植物(植物)
	if plant != {} and !plant["解锁"]:  # 修复：判断空字典而非null
		plant["解锁"] = true
		保存存档()
		return true
	return false

# 增加植物碎片
func 增加植物碎片(name: String, 数量: int) -> bool:
	var plant = 获取存档植物(name)
	if plant != {}:  # 修复：判断空字典而非null
		plant["植物碎片"] += 数量
		保存存档()
		return true
	return false

# ========== 物品管理方法 ==========

# 获取物品数量
func 获取物品数量(item_name: String) -> int:
	return 放置版存档["物品"].get(item_name, 0)

# 设置物品数量
func 设置物品数量(item_name: String, count: int) -> bool:
	if 放置版存档["物品"].has(item_name):
		放置版存档["物品"][item_name] = count
		保存存档()
		return true
	return false

# 增加物品数量
func 增加物品数量(item_name: String, 数量: int) -> bool:
	if 放置版存档["物品"].has(item_name):
		放置版存档["物品"][item_name] += 数量
		保存存档()
		return true
	return false

# 减少物品数量（检查是否足够）
func 减少物品数量(item_name: String, 数量: int) -> bool:
	if 放置版存档["物品"].has(item_name) and 放置版存档["物品"][item_name] >= 数量:
		放置版存档["物品"][item_name] -= 数量
		保存存档()
		return true
	return false

# ========== 快捷方法 ==========

func 读取金币() -> int:
	return 获取物品数量("金币")

func 读取物品(物品名称: String = "金币") -> int:
	# 参数校验
	if 物品名称.is_empty():
		物品名称 = "金币"
	return 获取物品数量(物品名称)
	
# 读取物品数组（排除金币，仅返回物品名称）
func 读取物品数组() -> Array:
	var 物品列表 = []
	var 存档物品 = 放置版存档["物品"]
	
	for 物品名称 in 存档物品:
		if 物品名称 != "金币":
			物品列表.append(物品名称)
	
	return 物品列表    

# 获得物品函数（支持任意物品，默认操作金币）
func 获得物品(物品名称: String = "金币", 数量: int = 1) -> bool:
	# 参数校验
	if 物品名称.is_empty():
		物品名称 = "金币"
	return 增加物品数量(物品名称, 数量)

func 消耗物品(物品名称: String = "金币", 数量: int = 1) -> bool:
	# 参数校验
	if 物品名称.is_empty():
		物品名称 = "金币"
	return 减少物品数量(物品名称, 数量)

func 指定物品数量(物品名称: String = "金币", 数量: int = 1) -> bool:
	# 参数校验
	if 物品名称.is_empty():
		物品名称 = "金币"
	return 设置物品数量(物品名称, 数量)
# ========== 关卡管理方法 ==========

# 通关关卡（通关次数+1，自动创建不存在的关卡）
func 通关(关卡名称: String) -> bool:
	# 1. 检查关卡是否存在，不存在则创建空白关卡
	if !放置版存档["关卡"].has(关卡名称):
		# 创建空白关卡数据（与存档中"前院告急1-1"格式一致）
		放置版存档["关卡"][关卡名称] = {
			"通关次数": 0,
			"最高评分": 0,
			"奖杯": [],
			"自动种植方案A": {
				"植物方阵": [],
				"种植策略": []
			}
		}
		print("创建新关卡存档: ", 关卡名称)
	
	# 2. 通关次数+1
	放置版存档["关卡"][关卡名称]["通关次数"] += 1
	print("关卡 [", 关卡名称, "] 通关次数更新为: ", 放置版存档["关卡"][关卡名称]["通关次数"])
	
	# 3. 保存存档
	return 保存存档()
