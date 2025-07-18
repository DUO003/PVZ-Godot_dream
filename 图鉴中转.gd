extends Control
func _ready():
	实例化植物($"植物实例",preload("res://FZB/ZW/ZJ_001_dmsfss.tscn"))
	实例化植物($"僵尸实例",preload("res://scenes/character/zombie/001_zombie_norm.tscn"))

func _打开B站(extra_arg_0: int) -> void:
	if extra_arg_0==0:
		OS.shell_open("https://space.bilibili.com/97213827")#潜艇伟伟迷
	elif extra_arg_0==2:
		OS.shell_open("https://space.bilibili.com/483986367")#睡觉做大梦
	else:
		OS.shell_open("https://space.bilibili.com/472181151")#多003

func 实例化植物(植物场景,植物路径):
	if 植物场景:
		# 遍历并移除所有子节点
		for 子节点 in 植物场景.get_children():
			子节点.queue_free()# 使用queue_free()安全移除节点
				
	# 加载并实例化植物场景下
	if 植物路径:
		var 植物 = 植物路径.instantiate()
		# 可选：如果需要禁用植物场景的脚本
		植物.script = null
		# 将植物实例添加到"植物/植物场景"下
		植物场景.add_child(植物)


func _没做() -> void:
	var 提示框=$"没做"
	提示框.appear_dialog()
	pass # Replace with function body.


func _查看植物() -> void:
	get_tree().change_scene_to_file("res://FZB/场景/放置版主菜单.tscn")
	pass # Replace with function body.



func _on_主菜单() -> void:
	get_tree().change_scene_to_file("res://FZB/场景/放置版主菜单.tscn")
	pass # Replace with function body.
