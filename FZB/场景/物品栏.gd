extends TextureButton
@export var 按钮编号: int = -1
signal 物品点击(按钮编号: int)  # 传递按钮编号


func _按钮按下() -> void:
	物品点击.emit(按钮编号)
	pass # Replace with function body.
