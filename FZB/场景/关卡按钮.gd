extends TextureButton
class_name 关卡按钮

@export var 地图选择 := Global.MainGameLevel.FrontDay
@export var 主题关卡 = 全局放置.关卡列表.测试
@onready var choose_level: 主线选关 = $"../../../.."


func _on_pressed() -> void:
	Global.main_game_level = 地图选择
	全局放置.选中关卡 = 主题关卡
	choose_level.choose_level_start_game()
	
