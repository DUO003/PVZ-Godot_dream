extends Control
class_name 主线选关

## 进入游戏关卡
func choose_level_start_game():
	get_tree().change_scene_to_file(Global.MainScenesMap[Global.MainScenes.MainGame])

## 返回开始菜单
func back_start_menu():
	get_tree().change_scene_to_file("res://FZB/场景/放置版主菜单.tscn")
