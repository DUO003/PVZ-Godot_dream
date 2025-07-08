extends CherryBomb
class_name ygzd
@export var 阳光产量 = 50
@export var sun_scene: PackedScene
@onready var sun: Node2D = $阳光
@export var day_suns:DaySuns

func _ready():
	super._ready()
	day_suns = get_tree().root.get_node("MainGame/DaySuns")

#region 植物死亡相关
func _plant_free():
	var new_sun = sun_scene.instantiate()
	if new_sun is Sun:
	
		day_suns.add_child(new_sun)
		new_sun.sun_value = 阳光产量
		new_sun._sun_scale(阳光产量)
		new_sun.global_position = sun.global_position
	super._plant_free()
# 铲掉植物
func be_shovel_kill():
	self.queue_free()
#endregion
