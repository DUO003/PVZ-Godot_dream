extends PanelContainer


func _on_mouse_entered():
	# 鼠标进入时，提高z_index，保证在前面显示
	get_parent().z_index = 900

func _on_mouse_exited():
	# 鼠标离开时，恢复原始z_index
	get_parent().z_index = 100
