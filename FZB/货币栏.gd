extends Node2D
@onready var 金币位置: Label = $货币栏/金币文本
@onready var 关卡名称位置: Label = $关卡名称
@onready var 僵尸数量: Label = $"../Manager/ZombieManager/FlagProgressBar/LabelZombieSum"
func _ready():
	金币位置.text = str(全局放置.读取金币())
	关卡名称位置.text = str(全局放置.获取当前关卡名称())
	关卡名称位置.visible = false
	僵尸数量.visible = false

func _游戏开始() -> void:
	关卡名称位置.visible = true
	僵尸数量.visible = true
