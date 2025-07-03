extends PotatoMine
@export var sun_scene: PackedScene
@onready var sun: Node2D = $阳光
@export var day_suns:DaySuns
@export var 阳光产量 = 50

func _ready():
	super._ready()
	day_suns = get_tree().root.get_node("MainGame/DaySuns")

func _plant_free():
	var new_sun = sun_scene.instantiate()
	if new_sun is Sun:
		
		day_suns.add_child(new_sun)
		new_sun.sun_value = 阳光产量
		new_sun._sun_scale(阳光产量)
		new_sun.global_position = sun.global_position
	super._plant_free()
