extends PlantBase
class_name 带妹上分射手
#region 变量创建
@export var 阳光产量 = 25
@export var 阳光间隔: float = 25.0
@export var sun_scene: PackedScene
@onready var production_timer: Timer = $"阳光动画"
@export var day_suns:DaySuns
@onready var sun: Node2D = $阳光

@export var 攻击间隔 = 2
@export var 子弹列表 = ["豌豆"]
@export var 弹道列表 = [0]
@export var 攻击状态 = 0
@onready var 子弹位置 :Node2D = $"豌豆"
@onready var 动画节点: AnimationTree = $AnimationTree
@onready var 射线节点: RayCast2D = $RayCast2D
var 运行次数 = 0

#endregion
@onready var 阳光计时器 = $"阳光生产"
func _ready():
	super._ready()
	#await get_tree().create_timer(1.0).timeout#暂停执行一秒
	阳光计时器.wait_time = 阳光间隔
	阳光计时器.timeout.connect(_on_阳光计时器_timeout)
	阳光计时器.start()
	day_suns = get_tree().root.get_node("MainGame/DaySuns")
	
	#动画节点.set("parameters/攻击条件/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)#开始攻击
	#动画节点.set("parameters/攻击条件/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)#结束攻击

func _process(delta):
	# 每帧检查射线是否碰到僵尸
	if 射线节点.is_colliding():
		if 攻击状态 == 0:
			#print("A")  # 攻击状态为 0 时执行
			动画节点.set("parameters/攻击条件/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)#开始攻击
			攻击状态 = 1
	else:
		if 攻击状态 == 1:
			#print("B")  # 攻击状态为 1 时执行
			攻击状态 = 0


func _on_阳光计时器_timeout():
	阳光产出()

func 阳光产出():
	发光()
	# 继续循环计时	
	阳光计时器.start()
# 身体发光函数
func 发光():
	# 创建新的 tween
	var tween = get_tree().create_tween()
	
	tween.tween_property(self, "modulate",  Color(2, 2, 2), 0.5)
	# 在第一个 tween 完成后、第二个 tween 开始前调用函数
	tween.tween_callback(Callable(self, "spawn_sun"))
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.5)

 #创建阳光
func spawn_sun():
	# SFX 向日葵生产阳光
	$阳光音效.play()
	
	var new_sun = sun_scene.instantiate()
	if new_sun is Sun:
		
		day_suns.add_child(new_sun)
		new_sun.sun_value = 阳光产量
		new_sun._sun_scale(阳光产量)
		# 控制阳光下落
		var tween = get_tree().create_tween()
		new_sun.global_position = sun.global_position
		
		var center_y : float = -15
		var target_y : float = 45
		tween.tween_property(new_sun, "position:y", center_y, 0.3).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(new_sun, "position:y", target_y, 0.6).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		var tween2 = get_tree().create_tween()
		tween2.tween_property(new_sun, "position:x", randf_range(-30, 30), 0.9).as_relative()
		

		tween2.finished.connect(new_sun.on_sun_tween_finished)
		
func 豌豆():
	$"豌豆音效1".play()
	var 子弹节点 = load("res://scenes/bullet/001_bullet_pea.tscn")
	var 子弹 = 子弹节点.instantiate()
	
	bullets.add_child(子弹)
	子弹.global_position = 子弹位置.global_position
	子弹.apply_random_offset()
	子弹.start_pos = 子弹.global_position
	if 攻击状态 == 0:
		动画节点.set("parameters/攻击条件/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)#结束攻击
		#print("停止攻击",攻击状态)
	#else:
		#print("继续攻击",攻击状态)
	运行次数 += 1 
	print("运行次数: %d 次" % 运行次数)
