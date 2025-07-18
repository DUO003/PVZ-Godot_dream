extends Node2D

# 金币面额
var 面额 = 1
var 收集 = false

@export var scale_factor: float = 1  # 缩放幅度
@export var speed: float = 2.0        # 动画速度
var 货币节点

func _process(delta: float):
	# 每帧更新X轴缩放，基于sin函数实现脉动效果
	scale.x = abs(sin(Time.get_ticks_msec() / 1000.0 * speed) * scale_factor)

signal 货币更新()
func _ready():
	# 初始化金币面额
	随机生成面额()
	if get_tree().root.has_node("MainGame/资源管理"):
		货币节点 = get_tree().root.get_node("MainGame/资源管理")
		self.货币更新.connect(货币节点.更新金币信息)
	await get_tree().create_timer(randf()*2+1).timeout
	检查自动拾取()
	

	
# 随机生成金币面额
func 随机生成面额():
	var 随机数 = randf()  # 生成0-1之间的随机数
	var 图片地址
	if 随机数 < 0.01:  # 1%概率
		面额 = 100
		图片地址=$"3"
	elif 随机数 < 0.2:  # 20%概率（0.01到0.21之间）
		面额 = 10
		图片地址=$"2"
	else:  # 79%概率
		图片地址=$"1"
	图片地址.visible=true
		
	
	# 可以在这里更新金币显示（例如修改纹理或文本）
	#print("金币面额: ", 面额)

# 移动到屏幕左下角
func 移动到屏幕左下角():
	# 获取屏幕大小（视口大小）
	var 屏幕大小 = get_viewport_rect().size
	# 左下角位置（稍微留一点边距，比如20像素）
	var 目标位置 = Vector2(20, 屏幕大小.y - 20)
	# 创建移动动画
	var tween = create_tween()
	tween.tween_property(self, "global_position", 目标位置, 0.5)  # 0.5秒移动
	tween.finished.connect(处理移动完成)

# 移动完成后执行（例如添加到玩家金币总数）
func 处理移动完成():
	# 这里可以添加金币收集逻辑，比如通知游戏管理器增加金币
	# 例如: GameManager.实例.增加金币(面额)
	全局放置.关卡金币奖励 += 面额
	emit_signal("货币更新")
	# 收集完成后删除金币节点
	queue_free()


func 点击() -> void:
	if 收集:
		return  # 防止重复点击
	收集 = true  # 设置已被收集
	# 处理点击事件
	移动到屏幕左下角()
	pass # Replace with function body.
	
func 检查自动拾取():
	if Global.auto_collect_coin:
		点击()
