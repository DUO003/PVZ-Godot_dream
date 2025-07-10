extends TextureButton
class_name 关卡按钮

@export var curr_level := Global.MainGameLevel.FrontDay
@onready var choose_level: 主线选关 = $"../../../.."


func _on_pressed() -> void:
	Global.main_game_level = curr_level
	choose_level.choose_level_start_game()
	
