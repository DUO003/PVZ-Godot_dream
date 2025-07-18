extends Control
class_name FlagProgressBar
##增加了允许非整10波僵尸的支持
## 使用真实进度值和追赶进度值，使进度条平滑移动

## 真实进度值 (0-100)
var real_value: float = 0.0
## 追赶进度值 (0-100)
var chase_value: float = 0.0

## 进度条
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
## 小僵尸头表示进度条
@onready var mini_zombie: TextureRect = $MiniZombie
## 旗帜
@onready var flag: Control = $Flag

## 小僵尸的起始位置
var start_minizombie :float = 142
## 小僵尸的结束位置
var end_minizombie :float = -4
## 小僵尸的当前位置
var curr_minizombie : float
## 进度条开始位置，用于生成旗帜
var start_flag = start_minizombie + 6
## 进度条结束位置，用于生成旗帜
var end_flag = end_minizombie + 6
## 存储生成的旗帜
var flag_arr : Array[FlagProgressBarFlag] = []
## 当前旗帜的索引
@export var curr_flag_i : int = 0


func _ready() -> void:
	curr_minizombie = start_minizombie
	set_progress(0)
	texture_progress_bar.value = 0
	mini_zombie.position.x = start_minizombie
	
	
## 根据旗帜数量生成旗帜，并删除原本的旗帜
func create_flag(flag_num:int, total_waves:int):
	flag_arr.clear()
	# 计算总距离
	var total_distance = start_flag - end_flag
	
	# 计算每个分段的结束位置
	for i in range(1, flag_num+1):
		# 根据总波数计算旗帜位置
		var ratio = i / float(total_waves)
		var end_pos = start_flag - total_distance * ratio

		var flag_new : FlagProgressBarFlag = flag.duplicate()
		
		add_child(flag_new)
		move_child(flag_new, 1)
		flag_arr.append(flag_new)
		flag_new.position.x = end_pos
	
	## 删除原始的flag
	flag.queue_free()
	

## 根据波数生成大波的旗帜
func init_flag_from_wave(wave_num:int):
	# 移除10的倍数限制，改为：如果小于10波，在最后一波添加旗帜
	var flag_num = 1  # 默认至少1个旗帜（最后一波）
	
	# 如果波数大于10，每10波添加一个旗帜
	if wave_num > 10:
		flag_num = ceil(wave_num / 10)
	
	create_flag(flag_num, wave_num)


# 设置真实进度
func set_progress(value: float, flag_i:int = -1):
	real_value = clamp(value, 0.0, 100.0)
	
	if flag_i != -1 and flag_i < flag_arr.size():
		flag_arr[flag_i].up_flag()


## 设置每秒进度增加	
func set_progress_add_every_sec(add_value:float):
	var value = real_value + add_value
	real_value = clamp(value, 0.0, 100.0)


# 动画追赶进度
func _process(delta):
	# 检查旗帜数组是否为空，避免错误
	if flag_arr.size() == 0:
		return
	
	# 在1秒内追赶真实进度
	if abs(chase_value - real_value) > 0.1:
		# 计算追赶速度 (每秒100单位)
		var speed = 100.0 * delta
		
		if chase_value < real_value:
			chase_value = min(chase_value + speed, real_value)
		else:
			# 如果真实进度减小，追赶进度也会减小
			chase_value = max(chase_value - speed, real_value)

		# 更新UI
		texture_progress_bar.value = chase_value
		curr_minizombie = start_minizombie + chase_value * (end_minizombie - start_minizombie) * 0.01
		mini_zombie.position.x = curr_minizombie
		
		if curr_flag_i < flag_arr.size() and curr_minizombie <= flag_arr[curr_flag_i].position.x - 6:
			flag_arr[curr_flag_i].up_flag()
			curr_flag_i += 1
		
	else:
		# 如果非常接近，直接设为相等
		if chase_value != real_value:
			chase_value = real_value
			
			texture_progress_bar.value = chase_value
			curr_minizombie = start_minizombie + chase_value * (end_minizombie - start_minizombie) * 0.01
			mini_zombie.position.x = curr_minizombie
		
	
			if curr_flag_i < flag_arr.size() and curr_minizombie <= flag_arr[curr_flag_i].position.x - 6:
				flag_arr[curr_flag_i].up_flag()
				curr_flag_i += 1
