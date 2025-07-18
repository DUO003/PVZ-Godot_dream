extends CharacterBase
class_name ZombieBase

#region 僵尸基础属性
@export_group("僵尸基础属性")
## 僵尸类型
@export var zombie_type : Global.ZombieType
## 僵尸攻击力每帧扣血
var frame_counter := 0
@export var damage_per_second := 100
var _curr_damage_per_second : int
var _curr_character :CharacterBase

## 僵尸所在行
@export var lane : int = -1
## 僵尸所属波次
@export var curr_wave:int = -1
## 僵尸受击音效是否为铁器防具 一类防具
@export var be_bullet_SFX_is_shield_first := false
## 僵尸受击音效是否为铁器防具 二类防具
@export var be_bullet_SFX_is_shield_second := false

#endregion

#region 僵尸状态，用于动画改变
@export_group("僵尸状态")
@export_subgroup("管理僵尸动画")
@export var is_idle := false
@export var is_walk := true			## 默认为移动状态
@export var is_attack := false
@export var is_death := false

@export_subgroup("管理僵尸死亡")
## 僵尸是否删除碰撞器，表示僵尸是否死亡，用于传递僵尸被击杀信号
@export var area2d_free:bool = false

#endregion

#region 僵尸防具血量变化

@export_group("僵尸防具血量变化")
@export_subgroup("血量状态")
@export var curr_hp_status := 1			## 血量状态

@export var zombie_outerarm_upper: Sprite2D							## 上半胳膊
@export var zombie_outerarm_upper_sprite2d_textures : Texture2D		## 上半胳膊残血图片

@export var zombie_status_2_fade: Array[Sprite2D]					## 僵尸血量状态2时隐藏精灵图（下半胳膊和手）
@export var hand_drop: Node2D		## 僵尸掉落的手

@export var zombie_status_3_fade: Array[Sprite2D]					## 僵尸血量状态3时隐藏精灵图（头部）
@export var head_drop: Node2D		## 僵尸掉落的头


@export_subgroup("一类防具状态")
@export var curr_armor_1_hp_status := 1

@export var armor_first_max_hp := 0
@export var armor_first_curr_hp : int

@export var armor_1_sprite2d : Sprite2D
@export var armor_1_sprite2d_textures : Array[Texture2D]

@export var arm_1_drop: Node2D


@export_subgroup("二类防具状态")
@export var curr_armor_2_hp_status := 1

@export var armor_second_max_hp := 0
@export var armor_second_curr_hp : int

@export var armor_2_sprite2d : Sprite2D
@export var armor_2_sprite2d_textures : Array[Texture2D]

@export var arm_2_drop: Node2D

#endregion

#region 僵尸移动相关
@export_group("移动相关")
@onready var area2d : Area2D = $Area2D
var _ground : Sprite2D
var _previous_ground_global_x:float
enum  WalkingStatus {start, start2, walking, end}
@export var walking_status := WalkingStatus.start
## 动画控制器
var playback: AnimationNodeStateMachinePlayback

var prev_state:StringName
var is_transitioning: bool = false
#endregion

@export_group("其他")
## 僵尸攻击射线
@onready var ray_cast_2d: RayCast2D = $RayCast2D

#region 被爆炸炸死相关
@onready var zombie_charred: Node2D = $ZombieCharred
@onready var anim_lib: AnimationPlayer = $ZombieCharred/AnimLib
@export var is_bomb_death:bool = false	## 被炸死标记，控制僵尸不在移动

#endregion

## 僵尸被攻击信号，传递给ZombieManager
signal zombie_damaged
## 僵尸被击杀信号，传递给ZombieManager
signal zombie_dead
## 僵尸被魅惑信号，传递给ZombieManager
signal zombie_hypno


#region 被魅惑相关
@export_group("被魅惑相关")
@export var is_hypnotized: bool = false
## 被魅惑颜色
var be_hypnotized_color := Color(1, 1, 1)
var be_hypnotized_color_res := Color(1, 0.5, 1)

#endregion

@export var 掉落物节点:掉落物管理
func _ready() -> void:
	掉落物节点 = get_tree().root.get_node("MainGame/掉落物管理")
	super._ready()
	walking_status = WalkingStatus.start
	#_previous_ground_global_x = _ground.position.x
	
	armor_first_curr_hp = armor_first_max_hp
	armor_second_curr_hp = armor_second_max_hp
	
	_curr_damage_per_second = damage_per_second
	
	# 设置检测射线的碰撞层
	ray_cast_2d.collision_mask = 0
	# 添加第2层和第6层（注意层索引从0开始）
	ray_cast_2d.collision_mask |= 1 << 1  # 第2层 植物层
	ray_cast_2d.collision_mask |= 1 << 5  # 第6层 被魅惑僵尸
	
	# 设置碰撞器所在层数
	area2d.collision_layer = 4	# 第3层
	
	updata_hp_label()

## 僵尸子类重写该方法，获取ground，部分僵尸修改body位置在panel节点下
func _get_some_node():
	body = $Body
	_ground = $Body/_ground
	animation_tree = $AnimationTree
	
	# 获取状态机播放控制器
	playback = animation_tree.get("parameters/StateMachine/playback")


func updata_hp_label():
	label_hp.get_node('Label').text = str(curr_Hp)
	if armor_first_curr_hp > 0:
		label_hp.get_node('Label').text = label_hp.get_node('Label').text + "+" + str(armor_first_curr_hp)
	if armor_second_curr_hp > 0:
		label_hp.get_node('Label').text = label_hp.get_node('Label').text + "+" + str(armor_second_curr_hp)
	
	if Global.display_zombie_HP_label:
		label_hp.visible = true
	else:
		label_hp.visible = false



func _process(delta):
	_zombie_walk()
	
	# 每帧检查射线是否碰到植物
	if ray_cast_2d.is_colliding():
				# 获取Area2D的父节点
		var collider = ray_cast_2d.get_collider()
		if collider:
			_curr_character = collider.get_parent()

		if not is_attack:
			start_attack()
		
	else:
		if is_attack:
			end_attack()

		
func _zombie_walk():
	# 检查状态变化,若动画改变，更新_walking_start()
	state_transition_judge_walking_status()

	## 检查是否移动,is_bomb_death不移动
	if is_walk and not is_bomb_death:
		if walking_status == WalkingStatus.end:
			_previous_ground_global_x = _ground.global_position.x
		elif walking_status == WalkingStatus.start:
			## 等待1帧，避免僵尸闪现
			await get_tree().process_frame
			walking_status = WalkingStatus.walking
			_previous_ground_global_x = _ground.global_position.x
		else:
			_walk()

			
func start_attack():

	is_walk = false
	is_attack = true
	
func end_attack():
	_curr_character = null
	is_attack = false
	is_walk = true
	

func _physics_process(delta: float) -> void:
	
	## 每帧扣血一次
	if curr_hp_status == 3 and curr_Hp >0:
		curr_Hp -= 1
		updata_hp_label()
	
	## 如果正在攻击
	if judge_can_attack():
		## 每4帧扣血一次
		frame_counter += 1
		
		if not is_iced:
			# 每三帧植物掉血一次，被减速每6帧植物掉血一次 
			if is_decelerated:
				if frame_counter % 6 == 0:
					_curr_character.be_eated(_curr_damage_per_second * delta * 3, self)
				
			else:
				if frame_counter % 3 == 0:
					_curr_character.be_eated(_curr_damage_per_second * delta * 3, self)
			
		# 防止过大，每 10000 帧归零（大概每 167 秒）
		if frame_counter >= 10000:
			frame_counter = 0
	

## 判断是否攻击，舞王重写
func judge_can_attack():
	return _curr_character and is_attack and not area2d_free

## 判断动画是否改变,修改walking_status，由于从攻击动画到移动动画有渐变，需要先等待时间在更新_walking_start
## 子类可重写await的条件
func state_transition_judge_walking_status():
	 #检查从"eat"到"walk"的转换
	var current_state = playback.get_current_node()
	if current_state != prev_state:
		_walking_start()
		prev_state = current_state


## 获取当前僵尸所有血量（HP+防具）
func get_zombie_all_hp():
	return max_hp + armor_first_curr_hp + armor_second_curr_hp


#region 僵尸移动相关
func _walking_end():
	walking_status = WalkingStatus.end
	_previous_ground_global_x = _ground.global_position.x


func _walking_start():
	walking_status = WalkingStatus.start
	_previous_ground_global_x = _ground.global_position.x


func _walk():
	# 计算ground的全局坐标变化量
	var ground_global_offset = _ground.global_position.x - _previous_ground_global_x
	# 反向调整zombie的position.x以抵消ground的移动
	self.position.x -= ground_global_offset
	# 更新记录值
	_previous_ground_global_x = _ground.global_position.x
#endregion

#region 僵尸被攻击
## 被子弹攻击，重写父类方法
func be_attacked_bullet(attack_value:int, bullet_mode : Global.BulletMode, bullet_shield_SFX:=true):
	# SFX 根据防具是否有铁器进行判断，防具掉落时修改bool值
	if (be_bullet_SFX_is_shield_first or be_bullet_SFX_is_shield_second) and bullet_shield_SFX: 
		get_node("SFX/Bullet/Shieldhit" + str(randi_range(1,2))).play()
	else:
		get_node("SFX/Bullet/Splat" + str(randi_range(1,3))).play()
		
	## 掉血，发光,直接调用父类方法
	super.be_attacked_bullet(attack_value, bullet_mode)


#region 僵尸血量防具改变
## 有二类防具的情况下判断，掉血前二类防具血量大于0
func _judge_status_armor_2():

	# 二类防具第一次血量小于0， 将小于0的血量返回，表示剩余攻击力
	if armor_second_curr_hp <= 0 and curr_armor_2_hp_status < 4:
		curr_armor_2_hp_status = 4
		armor_2_sprite2d.visible = false
		
		## 二类防具音效改变
		be_bullet_SFX_is_shield_second = false
		arm2_drop()
		
		return -armor_second_curr_hp
		
	# 第一次血量小于1/3
	elif armor_second_curr_hp <= armor_second_max_hp / 3 and curr_armor_2_hp_status < 3:
		curr_armor_2_hp_status = 3
		armor_2_sprite2d.texture = armor_2_sprite2d_textures[1]
		
		return 0
	
	# 第一次血量小于2/3
	elif armor_second_curr_hp <= armor_second_max_hp * 2/ 3 and curr_armor_2_hp_status < 2:
		curr_armor_2_hp_status = 2
		armor_2_sprite2d.texture = armor_2_sprite2d_textures[0]

		return 0
		
	else:
		return 0

## 二类防具掉落
func arm2_drop():
	arm_2_drop.acitvate_it()
	


## 有一类防具的情况下判断，掉血前一类防具血量大于0
func _judge_status_armor_1():
	# 一类防具第一次血量小于0， 将小于0的血量返回，表示剩余攻击力
	if armor_first_curr_hp <= 0 and curr_armor_1_hp_status < 4:
		curr_armor_1_hp_status = 4
		armor_1_sprite2d.visible = false
		
		## 一类防具音效改变
		be_bullet_SFX_is_shield_first = false
		arm1_drop()
		
		return -armor_first_curr_hp
		
	# 第一次血量小于1/3
	elif armor_first_curr_hp <= armor_first_max_hp / 3 and curr_armor_1_hp_status < 3:
		curr_armor_1_hp_status = 3
		armor_1_sprite2d.texture = armor_1_sprite2d_textures[1]
		
		return 0
	
	# 第一次血量小于2/3
	elif armor_first_curr_hp <= armor_first_max_hp * 2/ 3 and curr_armor_1_hp_status < 2:
		curr_armor_1_hp_status = 2
		armor_1_sprite2d.texture = armor_1_sprite2d_textures[0]

		return 0
		
	else:
		return 0

## 一类防具掉落
func arm1_drop():
	arm_1_drop.acitvate_it()

#endregion

#region 僵尸血量改变
# 僵尸被攻击时掉血（包括防具变化）
func Hp_loss(attack_value:int, bullet_mode : Global.BulletMode = Global.BulletMode.Norm):
	var ori_hp = get_zombie_all_hp()
	match bullet_mode:
		## 普通子弹
		Global.BulletMode.Norm:
			# 如果有二类防具，先对二类防具掉血，若二类防具血量<0, 修改
			if armor_second_curr_hp > 0:
				armor_second_curr_hp -= attack_value
				attack_value = _judge_status_armor_2()
				
			# 如果有一类防具
			if armor_first_curr_hp > 0 and attack_value > 0:
				armor_first_curr_hp -= attack_value
				attack_value = _judge_status_armor_1()
			
			# 血量>0
			if curr_Hp > 0 and attack_value > 0:
				curr_Hp -= attack_value
				judge_status()
		# 穿透子弹
		Global.BulletMode.penetration:
			
			# 如果有二类防具，先对二类防具掉血，若二类防具血量<0, 修改
			if armor_second_curr_hp > 0:
				armor_second_curr_hp -= attack_value
				_judge_status_armor_2()
				
			# 如果有一类防具
			if armor_first_curr_hp > 0 and attack_value > 0:
				armor_first_curr_hp -= attack_value
				attack_value = _judge_status_armor_1()
			
			# 血量>0
			if curr_Hp > 0 and attack_value > 0:
				curr_Hp -= attack_value
				judge_status()
				
		Global.BulletMode.real:
				
			# 如果有一类防具
			if armor_first_curr_hp > 0 and attack_value > 0:
				armor_first_curr_hp -= attack_value
				attack_value = _judge_status_armor_1()
			
			# 血量>0
			if curr_Hp > 0 and attack_value > 0:
				curr_Hp -= attack_value
				judge_status()
	
	updata_hp_label()
	
	var res_hp = get_zombie_all_hp()
	var loss_hp = ori_hp - res_hp
	
	zombie_damaged.emit(loss_hp, curr_wave)

## 血量状态判断
func judge_status():
	## 若僵尸满血被小推车碾压，需要先判断掉手阶段血量，在判断掉头阶段血量
	if curr_Hp <= max_hp*2/3 and curr_hp_status < 2:
		curr_hp_status = 2
		_hp_2_stage()
		
	if curr_Hp <= max_hp/3 - 1 and curr_hp_status < 3:
		curr_hp_status = 3
		hp_status_3_anim_para()
		_delete_area2d()	# 删除碰撞器
		
		## 让有一类防具和二类防具的僵尸防具血量都置为0，更新状态
		if armor_first_curr_hp > 0:
			armor_first_curr_hp = 0
			_judge_status_armor_1()
			
		if armor_second_curr_hp > 0:
			armor_second_curr_hp = 0
			_judge_status_armor_2()
			
		_hp_3_stage()
		
		
## 血量状态为3时的动画相关参数变化
func hp_status_3_anim_para():
	is_death = true

## 第一次血量2阶段变化 掉手状态
func _hp_2_stage():
	_hand_fade()

# 下半胳膊消失
func _hand_fade():
	## 隐藏下半胳膊
	for arm_hand_part in zombie_status_2_fade:
		arm_hand_part.visible = false
	## 掉落下半胳膊
	hand_drop.acitvate_it()
	
	## 修改上半胳膊图片（残血图片）
	zombie_outerarm_upper.texture = zombie_outerarm_upper_sprite2d_textures
	

## 第一次血量3阶段变化 掉头状态
func _hp_3_stage():
	_head_fade()
	掉落金币()
	
# 头消失，
func _head_fade():
	# SFX 僵尸头掉落
	$SFX/Shoop.play()
	for head_part in zombie_status_3_fade:
		head_part.visible = false
		
	head_drop.acitvate_it()
	
#独立的金币掉落方法

func 掉落金币():
	# 50%概率掉落金币
	if randf() < 0.5:
	# 加载并实例化金币场景
		var 金币场景 = preload("res://FZB/场景/场景内道具/金币.tscn").instantiate()
		掉落物节点.add_child(金币场景)
		金币场景.global_position = global_position
		print("金币生成")


#endregion
#endregion

## 僵尸啃咬一次，动画中调用,攻击音效
func _attack_once():
	if not area2d_free:
		get_node("SFX/Chomp").play()
		if _curr_character:
			_curr_character.be_eated_once(self)

#region 僵尸特殊状态:魅惑
#僵尸被魅惑
func be_hypnotized():
	be_hypnotized_base()
	be_hypnotized_signal()

## 被魅惑后的基础改变
func be_hypnotized_base():
	
	is_hypnotized = true
	# 重置碰撞器所在层数
	area2d.collision_layer = 32		#第6层
	
	# 重置检测射线的碰撞层
	ray_cast_2d.collision_mask = 0
	# 添加第4层和第5层（注意层索引从0开始，所以第3层是索引2，第5层是索引4）
	ray_cast_2d.collision_mask |= 1 << 2  # 第3层 僵尸层
	ray_cast_2d.collision_mask |= 1 << 4  # 第5层 撑杆跳跳跃层
	
	flip_zombie()
	
	# 更新僵尸颜色
	be_hypnotized_color = be_hypnotized_color_res
	_update_modulate()
	## 被魅惑后重新移动
	walking_status = WalkingStatus.start
	
	
## 被魅惑后信号更新
func be_hypnotized_signal():
	## 发送僵尸被攻击和死亡信号
	var zombie_all_hp = get_zombie_all_hp()
	zombie_damaged.emit(zombie_all_hp, curr_wave)
	zombie_dead.emit(self)
	## 断开信号连接
	var connections_damaged = zombie_damaged.get_connections()
	for conn in connections_damaged:
		zombie_damaged.disconnect(conn["callable"])
		
	var connections_dead = zombie_dead.get_connections()
	for conn in connections_dead:
		zombie_dead.disconnect(conn["callable"])
	
	zombie_hypno.emit(self)
	
	var connections_hypno = zombie_hypno.get_connections()
	for conn in connections_hypno:
		zombie_hypno.disconnect(conn["callable"])
	



# 重写父类颜色变化
func _update_modulate():
	var final_color = base_color * _hit_color * debuff_color * be_hypnotized_color
	body.modulate = final_color

	
# 直接设置scale
func flip_zombie():
	# 进行水平翻转
	scale = scale * Vector2(-1, 1)
	
	label_hp.scale = scale

#endregion


#region 僵尸死亡相关
# 删除僵尸
func delete_zombie():
	self.queue_free()


## 被小推车碾压
func be_mowered_run():
	# 减速当前所有血量
	Hp_loss(get_zombie_all_hp())


## 僵尸删除area,即僵尸死亡
func _delete_area2d():
	## 未死亡或
	if not area2d_free:
		area2d_free = true
		_curr_damage_per_second = 0
		
		var zombie_all_hp = get_zombie_all_hp()
		zombie_damaged.emit(zombie_all_hp, curr_wave)
		zombie_dead.emit(self)
		area2d.queue_free()
	
	
## 僵尸被炸死	
func be_bomb_death():
	
	_delete_area2d()	# 删除碰撞器
	
	## 清空血量
	armor_second_curr_hp -= armor_second_curr_hp
	armor_first_curr_hp -= armor_first_curr_hp
	curr_Hp -= curr_Hp
	updata_hp_label()
	
	body.visible = false
	#animation_tree.active = false
	zombie_charred.visible = true
	is_bomb_death = true
	# 播放僵尸灰烬动画
	anim_lib.play("ALL_ANIMS")
	await anim_lib.animation_finished
	delete_zombie()

## 僵尸直接死亡 （大嘴花、土豆雷）
func disappear_death():
	_delete_area2d()	# 删除碰撞器
	delete_zombie()


## 僵尸死亡后逐渐透明，最后删除节点
func _fade_and_remove():
	var tween = create_tween()  # 自动创建并绑定Tween节点
	tween.tween_property(self, "modulate:a", 0.0, 1.0)  # 1秒内透明度降为0
	tween.tween_callback(delete_zombie)  # 动画完成后删除僵尸

#endregion
	
