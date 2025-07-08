extends Node2D
@onready var 金币位置: Label = $货币栏/金币文本

func _ready():
		金币位置.text = str(全局放置.读取金币())
