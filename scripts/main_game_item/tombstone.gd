extends Node2D
class_name  TombStone

@onready var tombstone: Sprite2D = $TombstoneMask/tombstone
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var mound: Sprite2D = $MoundMask/mound
@onready var tombstone_mask: Panel = $TombstoneMask
## 新生成僵尸相关
@onready var new_zombie_mask: Panel = $NewZombieMask
@onready var dirt: DirtNewZombie = $Dirt

@export var zombie_candidate_list :Array[Global.ZombieType]
@export var zombie_manager:Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_tombstone()
	zombie_manager = get_tree().current_scene.get_node("Manager/ZombieManager")

## 随机生成一种墓碑（一共5种）
func _init_random_frame():
	var random_frame = randi_range(0,4)
	tombstone.frame = random_frame
	mound.frame = random_frame
	SoundManager.play_sfx("GravestoneRumble")
	

## 初始化墓碑
func _init_tombstone():
	
	_init_random_frame()
	gpu_particles_2d.emitting = true
	var mound_ori_position = mound.position
	var tombstone_ori_position = tombstone.position
	mound.position = Vector2(39, 84)
	tombstone.position = Vector2(39, 136)
	await get_tree().create_timer(0.5).timeout
	var tween := create_tween()
	tween.tween_property(mound, "position", mound_ori_position, 0.1)
	tween.tween_property(tombstone, "position", tombstone_ori_position, 0.5)
	

## 被墓碑吞吃时修改mask位置
func start_be_grave_buster_eat():
	tombstone_mask.position.y += 20
	tombstone.position.y -= 20

## 生成僵尸
func create_new_zombie():
	var new_zombie_type = zombie_candidate_list.pick_random()

	var z:ZombieBase = zombie_manager.return_zombie(new_zombie_type)
	var body:Node2D = z.get_node("Body")
	
	var plant_cell:PlantCell = get_parent()
	## 僵尸目标位置
	new_zombie_mask.add_child(z)
	z.position = Vector2(110, 162)
	
	## 如果是舞王僵尸
	if z is ZombieJackson:
		z.gmae_init_zombie_jackson()
			
	z.lane = plant_cell.row_col.x
	z.zombie_dead.connect(zombie_manager._on_zombie_dead)
	z.zombie_hypno.connect(zombie_manager._on_zombie_hypno)
	z.curr_wave = zombie_manager.current_wave
	z.is_idle = false
	
	zombie_manager.zombies_all_list[plant_cell.row_col.x].append(z)
	zombie_manager.curr_zombie_num += 1
	
	## 僵尸出现,更新body位置
	dirt.start_dirt_no_free()
	var tween = create_tween()
	var target_position_body = body.position
	var origional_position_body = body.position + Vector2(0, 100)
	body.position = origional_position_body
	# 设置移动动画
	tween.tween_property(body, "position", target_position_body, 0.5)
	await tween.finished
	
	var global_position_res = z.global_position 
	
	new_zombie_mask.remove_child(z)
	zombie_manager.zombies_row_node[plant_cell.row_col.x].add_child(z)
	z.global_position = global_position_res 
