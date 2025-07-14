extends Node2D
class_name ZombieManager

@onready var main_game: MainGameManager = $"../.."
## 最大波次
var max_wave :int
var current_wave := 0
var wave_total_health := 0
var wave_current_health := 0
var refresh_threshold := 0.5  # 波次触发激活刷新的血量流失比例
var refresh_triggered := false
var refresh_health := 0  # 波次触发激活刷新的血量流失

var curr_flag := -1
var flag_front_wave := false	#是否为旗前波
@export var curr_zombie_num:int = 0:
	get:
		return curr_zombie_num
	set(v):
		curr_zombie_num=v
		label_zombie_sum.text = "僵尸：" + str(curr_zombie_num)
		


## 所有僵尸行的节点
@export var zombies_row_node:Array[Node]
## 按行保存僵尸，用于保存僵尸列表的列表
@export var zombies_all_list:Array 

@onready var flag_progress_bar: FlagProgressBar = $FlagProgressBar

## 自然刷新计时器
@onready var wave_timer: Timer = $WaveTimer
## 每秒进度条更新计时器
@onready var one_wave_progress_timer: Timer = $OneWaveProgressTimer

@onready var label_zombie_sum: Label = $FlagProgressBar/LabelZombieSum

## 是否为最后一波
@export var end_wave:= false
## 每波进度条所占大小
@export var progress_bar_segment_every_wave:float

## 每段根据当前波次时间，每秒多长
@export var progress_bar_segment_mini_every_sec:float

## 冰冻特效场景
const IceEffectScenes:PackedScene =  preload("res://scenes/fx/ice_effect.tscn")
## 刷新僵尸时怪叫
@export var groan_SFX : Array[AudioStreamPlayer]


#region 僵尸出怪列表相关参数
# 创建出怪列表
var spawn_list = []

# 生成僵尸的波次，最大为100波
@export var max_waves_spawn_list = 100
@export var max_zombies_per_wave = 50

# 定义每个僵尸的战力值
var zombie_power = {
	Global.ZombieType.ZombieNorm: 1,        # 普僵战力
	Global.ZombieType.ZombieFlag: 1,        # 旗帜战力
	Global.ZombieType.ZombieCone: 1,        # 路障战力
	Global.ZombieType.ZombiePoleVaulter: 2, # 撑杆战力
	Global.ZombieType.ZombieBucket: 2,      # 铁桶战力
	Global.ZombieType.ZombiePaper: 2,       # 读报战力
	Global.ZombieType.ZombieScreenDoor: 2,      # 铁门战力
	Global.ZombieType.ZombieFootball: 3,       # 橄榄球战力
	Global.ZombieType.ZombieJackson: 3,       # 舞王战力
}

# 创建 zombie_weights 字典，存储初始权重
var zombie_weights = {
	Global.ZombieType.ZombieNorm: 4000,        # 普僵权重
	Global.ZombieType.ZombieFlag: 0,           # 旗帜权重
	Global.ZombieType.ZombieCone: 4000,        # 路障权重
	Global.ZombieType.ZombiePoleVaulter: 2000,  # 撑杆权重
	Global.ZombieType.ZombieBucket: 3000,       # 铁桶权重
	Global.ZombieType.ZombiePaper: 3000,       # 读报权重
	Global.ZombieType.ZombieScreenDoor: 3000,      # 铁门权重
	Global.ZombieType.ZombieFootball: 3000,       # 橄榄球权重
	Global.ZombieType.ZombieJackson: 3000,       # 舞王权重
}

#endregion

#region 关卡前展示僵尸
@export_group("展示僵尸相关")
@onready var show_zombie: Node2D = $"../../ShowZombie"
@export var show_zombie_pos_start := Vector2(50, 50)
@export var show_zombie_pos_end := Vector2(250, 450)
@export var show_zombie_array : Array[ZombieBase] = []

#endregion

## 奖杯
const trophy_scenes = preload("res://scenes/ui/trophy.tscn")

#region 魅惑僵尸管理
@export var zombie_list_be_hypno:Array[ZombieBase] = []
## 每波查看是否有被魅惑的僵尸走出屏幕后没被销毁
## 超出屏幕500像素删除
var screen_rect: Rect2 

# 生成100波出怪列表，每波最多50只僵尸
func _ready():
	create_spawn_list()
	## 被魅惑僵尸移动边界
	screen_rect = get_viewport_rect().grow(500)

## 初始僵尸管理器
func init_zombie_manager(zombies:Node2D, max_wave:int):
	zombies_row_node = zombies.get_children()
	for i in range(len(zombies_row_node)):
		zombies_all_list.append([])  # 每次添加一个新的空列表
		
	self.max_wave = max_wave
	flag_progress_bar.init_flag_from_wave(max_wave)

	progress_bar_segment_every_wave = 100.0 / (max_wave - 1)


## 显示僵尸血量
func display_zombie_HP_label():
	if Global.display_zombie_HP_label:
		for zombies_row_list in zombies_all_list:
			for zombie:ZombieBase in zombies_row_list:
				zombie.label_hp.visible = true
	else:
		for zombies_row_list in zombies_all_list:
			for zombie:ZombieBase in zombies_row_list:
				zombie.label_hp.visible = false

	
#region 生成僵尸列表

func 替换僵尸出怪():
	# 获取全局放置.关卡权重字典
	var level_weights = 全局放置.关卡权重
	
	# 遍历关卡权重字典
	for zombie_type in level_weights.keys():
		# 检查当前僵尸类型是否存在于默认权重字典中
		if zombie_weights.has(zombie_type):
			# 如果存在，则用关卡权重替换默认权重
			zombie_weights[zombie_type] = level_weights[zombie_type]
			print("已替换权重: ", zombie_type, " = ", zombie_weights[zombie_type])
		else:
			# 如果不存在，则跳过
			print("跳过未知僵尸类型: ", zombie_type)

# 生成100波出怪列表，每波最多50只僵尸
func create_spawn_list():
	"""
	大波（每10波一次）会优先生成一定数量的特殊僵尸（旗帜僵尸和普通僵尸），且战力上限是普通波的2.5倍。
	普通波的僵尸类型和数量是根据权重进行随机生成的。
	权重递减机制：随着波次的增加，普通僵尸和路障僵尸的权重会逐渐下降，直到固定值（第25波以后）
	"""
	for wave_index in range(max_waves_spawn_list):
		var wave_spawn = []  # 当前波的僵尸列表
		var remaining_slots = max_zombies_per_wave
		
		# 判断是否为大波
		var is_big_wave = (wave_index + 1) % 10 == 0
		# 计算当前波的战力上限
		var current_power_limit = calculate_wave_power_limit(wave_index + 1, is_big_wave)

		# 如果是大波，先刷新特殊僵尸
		var total_power = 0
		if is_big_wave:
			# 第一个旗帜僵尸
			wave_spawn.append(Global.ZombieType.ZombieFlag)
			total_power += zombie_power[Global.ZombieType.ZombieFlag]
			remaining_slots -= 1
			
			# 第一次大波（第10波），刷新4个普通僵尸
			if wave_index == 9:
				for i in range(4):
					wave_spawn.append(Global.ZombieType.ZombieNorm)
					total_power += zombie_power[Global.ZombieType.ZombieNorm]
					remaining_slots -= 1
			# 之后的大波（第20波、30波...），刷新8个普通僵尸
			else:
				for i in range(8):
					wave_spawn.append(Global.ZombieType.ZombieNorm)
					total_power += zombie_power[Global.ZombieType.ZombieNorm]
					remaining_slots -= 1

		# 动态调整普通僵尸和路障僵尸的权重
		update_weights(wave_index)

		# 生成剩余僵尸，直到总战力符合当前战力上限
		while remaining_slots > 0 and total_power < current_power_limit:
			var selected_zombie = get_random_zombie_based_on_weight()
			var zombie_power_value = zombie_power[selected_zombie]
			
			# 检查如果加上该僵尸的战力后超过当前波的战力上限，重新选择
			if total_power + zombie_power_value <= current_power_limit:
				wave_spawn.append(selected_zombie)
				total_power += zombie_power_value
				remaining_slots -= 1
			else:
				continue
		
		# 将当前波的僵尸列表添加到出怪列表中
		spawn_list.append(wave_spawn)
		
		#print(wave_index, " ", current_power_limit, " ", wave_spawn)
	return spawn_list

# 计算每波的战力上限
func calculate_wave_power_limit(wave_index:int, is_big_wave: bool) -> int:
	# 计算战力上限 = y=int((x-1)/3)+1
	var base_power_limit:int = (wave_index - 1) / 3 + 1
	
	# 如果是大波，战力上限是原战力上限的2.5倍
	if is_big_wave:
		return int(base_power_limit * 2.5)
	
	return base_power_limit


# 获取根据权重选择的僵尸
func get_random_zombie_based_on_weight() -> int:
	# 基于统一的刷新种类随机选择僵尸
	var cumulative_weight = 0
	var max_weight = 0
	
	# 计算所有可能僵尸的权重总和
	for zombie_type in main_game.zombie_refresh_types:
		max_weight += zombie_weights[zombie_type]

	var random_value = randi_range(0, max_weight)  # 使用动态计算的最大权重

	for zombie_type in main_game.zombie_refresh_types:
		cumulative_weight += zombie_weights[zombie_type]
		
		if random_value < cumulative_weight:
			return zombie_type  # 返回选中的僵尸类型

	# 如果没有选中，默认返回普通僵尸
	return Global.ZombieType.ZombieNorm


# 更新僵尸权重
func update_weights(wave_index: int):
	# 普通僵尸权重调整逻辑
	if wave_index >= 5:
		var norm_weight = 4000 - (wave_index - 4) * 180
		if wave_index >= 25:
			norm_weight = 400  # 当轮次达到25时，普通僵尸权重固定为400
		zombie_weights[Global.ZombieType.ZombieNorm] = norm_weight

	# 路障僵尸权重调整逻辑
	if wave_index >= 5:
		var cone_weight = 4000 - (wave_index - 4) * 150
		if wave_index >= 25:
			cone_weight = 1000  # 当轮次达到25时，路障僵尸权重固定为1000
		zombie_weights[Global.ZombieType.ZombieCone] = cone_weight
	
#endregion

#region 僵尸刷新

"""

除了W9, W19和W20 外, 对刷新出来的每波僵尸，存在一个0.5~0.67之间的值k，
记刷新之后ts时场上该波僵尸总血量开始小于总血量的k倍( 称为激活 )，则存在一个区间[25,31]内的随机数T(自然刷新)，
在刷新之后min{T,max{6.01,t+2}}s刷新下一波僵尸; 对W9和W19, 记刷新之后ts时场上该波僵尸( 除伴舞 )全部死亡,
则在刷新之后min{52.45, max{6.01+7.5, t+2+7.5}}s刷新下一波僵尸(包括其中的7.5s红字时间); 
对W20, 记刷新之后ts时场上僵尸全部死亡, 则在刷新之后min{60, max{6.01+5, t+2+5}}s后进入下一次选卡. 这个时间称为该波的波长.

"""

## 计算当前进度并更新进度条
func set_progress_bar():
	var curr_progress = current_wave * progress_bar_segment_every_wave
	flag_progress_bar.set_progress(curr_progress, curr_flag)
	
func start_first_wave():
	start_next_wave()
	one_wave_progress_timer.start()


## 开始刷新下一波
func start_next_wave() -> void:
	print("-----------------------------------")
	if current_wave >= max_wave:
		print("🎉 结束(该语句应该不出现逻辑才对)")
		return
	
	## 黑夜旗帜波生成墓碑和僵尸
	if current_wave % 10 == 9 and current_wave != 0:
		print("当前为旗帜波刷新")
		
		if main_game.game_bg == Global.GameBg.FrontNight:
			#创建墓碑 (1-3个)
			main_game.hand_manager.create_tombstone(randi()%3+1)
			await get_tree().create_timer(2).timeout
		# 更新墓碑
		main_game.hand_manager.update_tombstone_list()
		## 墓碑生成僵尸
		for tombstone:TombStone in main_game.hand_manager.tombstone_list:
			tombstone.create_new_zombie()
		
	spawn_wave_zombies(spawn_list[current_wave])
	
	refresh_triggered = false
	end_wave = current_wave == max_wave - 1
	if end_wave:
		print("最后一波")
		wave_timer.stop()
		one_wave_progress_timer.stop()
		return 
		
	start_natural_refresh_timer()
	
	## 残半刷新血量倍率
	refresh_threshold = randf_range(0.5, 0.67)
	refresh_health = int(refresh_threshold * wave_total_health)
	print("🌀 第 %d 波开始，刷新阈值设为 %.2f，刷新血量为 %d，自然刷新时间为 %f" % [current_wave, refresh_threshold, refresh_health, wave_timer.wait_time])
	
#region 生成波次僵尸
## 生成当前波次僵尸
func spawn_wave_zombies(zombie_data: Array) -> void:
	# 更新当前波次僵尸总血量
	wave_total_health = 0
	wave_current_health = 0
	
	for z in zombie_data:
		var lane : int = randi() % len(zombies_row_node)
		spawn_zombie(z, lane)
		
	wave_current_health = wave_total_health
	
## 生成一个僵尸
func spawn_zombie(zombie_type: Global.ZombieType, lane: int) -> Node:

	var z:ZombieBase = Global.ZombieTypeSceneMap[zombie_type].instantiate()
	zombies_row_node[lane].add_child(z)

	## 如果是舞王僵尸
	if z is ZombieJackson:
		z.gmae_init_zombie_jackson()
			
	z.lane = lane
	z.zombie_damaged.connect(_on_zombie_damaged)
	z.zombie_dead.connect(_on_zombie_dead)
	z.zombie_hypno.connect(_on_zombie_hypno)
	z.curr_wave = current_wave
	z.is_idle = false
	if z.zombie_type == Global.ZombieType.ZombieFlag:
		print("旗帜僵尸")
		z.position.x = -20
	else:
		z.position.x = randf_range(0, 20)
		
		wave_total_health += z.get_zombie_all_hp()
	
	zombies_all_list[lane].append(z)
	curr_zombie_num += 1
	
	return z

func return_zombie(zombie_type: Global.ZombieType):
	var z:ZombieBase = Global.ZombieTypeSceneMap[zombie_type].instantiate()
	return z
	
#endregion

## 僵尸收到伤害调用函数
func _on_zombie_damaged(damage: int, wave:int) -> void:
	# 不是最后一波
	if wave == current_wave and not end_wave:
		wave_current_health = max(wave_current_health - damage, 0)
		check_refresh_condition()

## 僵尸发射死亡信号后调用函数
func _on_zombie_dead(zombie: ZombieBase) -> void:
	# 不额外减血；死亡前已由 take_damage 扣减
	curr_zombie_num -= 1
	
	zombies_all_list[zombie.lane].erase(zombie)
	
	## 当前是旗前波并僵尸全部死亡
	if flag_front_wave and curr_zombie_num == 0:
		
		refresh_flag_wave()
	
	# 如果到了最后一波刷新,且僵尸全部死亡
	if end_wave and curr_zombie_num == 0 :
		print("=======================游戏结束，您获胜了=======================")
		var trophy = trophy_scenes.instantiate()
		get_tree().current_scene.add_child(trophy)
		trophy.global_position = zombie.global_position
		if trophy.global_position.x >= 750:
			var x_diff = trophy.global_position.x - 750
			throw_to(trophy, trophy.position - Vector2(x_diff + randf_range(0,50), 0))
		else:
			throw_to(trophy, trophy.position - Vector2(randf_range(-50,50), 0))

## 奖杯抛出
func throw_to(node:Node2D, target_pos: Vector2, duration: float = 1.0):
	
	var start_pos = node.position
	var peak_pos = start_pos.lerp(target_pos, 0.5)
	peak_pos.y -= 50  # 向上抛

	var tween = create_tween()
	tween.tween_property(node, "position:x", target_pos.x, duration).set_trans(Tween.TRANS_LINEAR)

	tween.parallel().tween_property(node, "position:y", peak_pos.y, duration / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "position:y", target_pos.y, duration / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(duration / 2)



# 僵尸扣血时检测刷新状态
func check_refresh_condition() -> void:
	if refresh_triggered:
		return
		
	# 不是旗前波进行残半刷新判断
	if not flag_front_wave and wave_current_health <= refresh_health:
		refresh_health_half()
	
		
## 残半刷新判断
func refresh_health_half():
	if refresh_triggered:
		return
	
	print("⚡ 激活刷新达成（当前血量:,",wave_current_health,"刷新血量", refresh_health)
	refresh_triggered = true
	if wave_timer.is_stopped() == false:
		wave_timer.stop()
		
	update_current_wave()
	await get_tree().create_timer(2.0).timeout
	start_next_wave()


## 旗帜波僵尸全部死亡刷新
func refresh_flag_wave():
	if refresh_triggered:
		print("进旗帜波刷新机制，旗前波的前一波残半刷新时全部死亡会进到这个里面，此时正在刷新旗前波，直接返回")
		return
	print("⚡ 旗帜波提前刷新")
	refresh_triggered = true
	if wave_timer.is_stopped() == false:
		wave_timer.stop()
	
	
	update_current_wave()	# 更新当前波次
	print("等待开始")
	var start_time = Time.get_ticks_msec()
	
	await main_game.ui_remind_word.zombie_approach(current_wave == max_wave-1)
	await get_tree().create_timer(2.0).timeout
	
	## 汽笛音效
	SoundManager.play_sfx("Progress/Siren")
	
	var end_time = Time.get_ticks_msec()
	var elapsed = (end_time - start_time) / 1000.0  # 转换为秒

	print("等待结束，耗时:", elapsed, "秒")
	
	start_next_wave()

#region 自然刷新
## 开始计算自然刷新时间
func start_natural_refresh_timer() -> void:
	# 如果是旗前波刷新时间固定52.45 -7.5
	var interval = randf_range(23.0, 29.0) if not flag_front_wave else 52.45 -7.5
	print("当前波次：", current_wave, "旗前波：", flag_front_wave, "刷新时间：",interval)
	wave_timer.wait_time = interval
	wave_timer.start()
	# 每次更新每秒进度条大小
	if flag_front_wave:
		progress_bar_segment_mini_every_sec = progress_bar_segment_every_wave / (wave_timer.wait_time + 7.5)
	else:
		progress_bar_segment_mini_every_sec = progress_bar_segment_every_wave / (wave_timer.wait_time + 2)
	
## 自然刷新时间触发
func _on_WaveTimer_timeout() -> void:
	if refresh_triggered:
		return
	print("⌛ 自然刷新触发")
	update_current_wave()
	## 旗帜波
	if current_wave % 10 == 9:
		await main_game.ui_remind_word.zombie_approach(current_wave == max_wave-1)
		await get_tree().create_timer(2.0).timeout
	else:
		await get_tree().create_timer(2.0).timeout
	refresh_triggered = true
	start_next_wave()
#endregion

## 更新当前wave,在残半刷新或自然刷新时使用
func update_current_wave():
	current_wave += 1
	if current_wave % 10 == 8:
		flag_front_wave = true
		one_wave_progress_timer.stop()	# 更新进度条的计时器
	else:
		flag_front_wave = false
		one_wave_progress_timer.start()
	
	## 旗帜波更新第几个旗帜，用于更新进度条旗帜升旗
	if current_wave % 10 == 9:
		curr_flag = current_wave/10
		
	set_progress_bar()
	
	free_zombie_hypno()
	
## 删除被魅惑的移动超出限制的僵尸,每次刷新僵尸调用
func free_zombie_hypno():
	#：使用临时集合（更安全）
	var zombies_to_remove = []
	## 清空失效索引（已经死亡的被魅惑僵尸）
	zombie_list_be_hypno = zombie_list_be_hypno.filter(func(z):
		return is_instance_valid(z)
	)
	
	for z:ZombieBase in zombie_list_be_hypno:
		if z:
			# 检查是否在屏幕外
			if not screen_rect.has_point(z.global_position):
				zombies_to_remove.append(z)

			
	# 处理需要移除的对象
	for z:ZombieBase in zombies_to_remove:
		zombie_list_be_hypno.erase(z)
		## 僵王被魅惑后删除需要有一些更新在_delete_area2d()
		z._delete_area2d()
		z.queue_free()
	
	print(zombie_list_be_hypno)

## 僵尸被魅惑发射信号
func _on_zombie_hypno(zombie:ZombieBase):
	zombie_list_be_hypno.append(zombie)
	
	
#endregion
	

## 随时间更新进度条
func _on_one_wave_progress_timer_timeout() -> void:
	# 每秒进度条增加对应的进度值
	flag_progress_bar.set_progress_add_every_sec(progress_bar_segment_mini_every_sec)


#region 生成关卡前展示僵尸
func show_zombie_create():
	for zombie_type in main_game.zombie_refresh_types:
		for i in range(randi_range(1, 4)):

			var z:ZombieBase = Global.ZombieTypeSceneMap[zombie_type].instantiate()
			
			z.is_idle = true

			# 避免僵尸移动
			z.walking_status = z.WalkingStatus.end
			z.position = Vector2(
				randf_range(show_zombie_pos_start.x, show_zombie_pos_end.x),
				randf_range(show_zombie_pos_start.y, show_zombie_pos_end.y)
			)
			show_zombie.add_child(z)
			
			z.label_hp.visible = false
			
			## 如果是舞王僵尸
			if z is ZombieJackson:
				z.show_init_zombie_jackson()
			
			
			show_zombie_array.append(z)
			
			
func show_zombie_delete():
	for z in show_zombie_array:
		z.queue_free()  # 标记节点待释放

	show_zombie_array.clear()  # 最后清空数组

#endregion


#region 植物调用相关，冰冻所有僵尸
func ice_all_zombie(time_ice:float, time_decelerate: float):
	for zombie_row:Array in zombies_all_list:
		if zombie_row.is_empty():
			continue
		for zombie:ZombieBase in zombie_row:
			zombie.be_ice(time_ice, time_decelerate)
			## 冰冻效果
			var ice_effect = IceEffectScenes.instantiate()
			zombie.add_child(ice_effect)
			ice_effect.init_ice_effect(time_ice)
			

#endregion
