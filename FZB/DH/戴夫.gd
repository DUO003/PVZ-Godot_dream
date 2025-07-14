extends DialogicPortrait

# 返回肖像的覆盖矩形区域（相对于根节点）
func _get_covered_rect() -> Rect2:
	# 获取显示肖像的TextureRect节点
	var texture_rect = get_node_or_null("PortraitTextureRect")
	
	# 如果节点存在且已加载纹理，返回实际纹理大小
	if texture_rect and texture_rect.texture:
		return Rect2(
			Vector2.ZERO,  # 矩形左上角相对于根节点的位置（0,0）
			Vector2(       # 矩形大小（宽高）
				texture_rect.texture.get_width(),
				texture_rect.texture.get_height()
			)
		)
	else:
		print("报错")
		# 如果节点或纹理不存在，返回默认大小（避免布局错误）
		return Rect2(Vector2.ZERO, Vector2(300, 400))  # 默认大小为300x400像素
