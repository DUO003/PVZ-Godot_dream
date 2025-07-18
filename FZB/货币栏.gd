extends Control
@onready var 金币位置: Label = $货币栏/金币文本
@onready var 关卡名称位置: Label = $关卡名称
@onready var 僵尸数量: Label = $"../Manager/ZombieManager/FlagProgressBar/LabelZombieSum"
var 显示类型:bool=false
func _ready():
	更新金币信息()
	关卡名称位置.text = str(全局放置.获取当前关卡名称())
	关卡名称位置.visible = false
	僵尸数量.visible = false

func _游戏开始() -> void:
	关卡名称位置.visible = true
	僵尸数量.visible = true

func 更新金币信息():
	if 显示类型:
		金币位置.text = str(全局放置.读取金币())
	else:
		金币位置.text = str(全局放置.关卡金币奖励)

func _切换显示全局金币() -> void:
	显示类型=true
	更新金币信息()
	print("切换显示全局金币")
	pass # Replace with function body.


func _切换显示当前金币() -> void:
	显示类型=false
	更新金币信息()
	print("切换显示当前金币")
	pass # Replace with function body.
