extends Control
class_name 放置版主菜单

@onready var dialog: 提示 = $Dialog
@export var bgm:AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Cloud/AnimationPlayer.play("Idle")
	$BG_Right/杂草分组/AnimationPlayer.play("Idle")
	$AnimationPlayer.play("Idle")
	
	SoundManager.setup_ui_start_menu_sound(self)
	SoundManager.play_bgm(bgm)
	
	Global.time_scale = 1.0
	Engine.time_scale = Global.time_scale


	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## 功能未实现
func _unrealized():
	dialog.appear_dialog()

## 开始游戏
#func _on_menu_button_1_pressed() -> void:
	#get_tree().change_scene_to_file(Global.MainScenesMap[Global.MainScenes.ChooseLevel])
func _on_开始冒险() -> void:
	get_tree().change_scene_to_file("res://FZB/场景/主线关卡选择.tscn")

func _on_背包() -> void:
	get_tree().change_scene_to_file("res://FZB/场景/背包.tscn")


func _on_option_button_1_pressed() -> void:
	$StartMenuOptionDialog.appear_menu()
	

func _on_option_button_2_pressed() -> void:
	$Dialog_Help.appear_dialog()

## 退出游戏
func _on_退出游戏() -> void:
	get_tree().quit()


func _on_full_screen_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
