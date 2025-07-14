extends TextureRect

signal shovel_click		#点击信号

@onready var card_bar_and_shovel: HBoxContainer = $"../.."


func _on_button_pressed() -> void:
	shovel_click.emit()


func _on_mouse_entered():
	# 鼠标进入时，提高z_index，保证在前面显示
	card_bar_and_shovel.z_index = 900
	

func _on_mouse_exited():
	# 鼠标离开时，恢复原始z_index
	card_bar_and_shovel.z_index = 100
