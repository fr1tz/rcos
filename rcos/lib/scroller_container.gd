
extends ReferenceFrame

func _init():
	add_user_signal("scrolling_started")
	add_user_signal("scrolling_stopped")

func _draw():
     VisualServer.canvas_item_set_clip(get_canvas_item(),true)

func scroll(scroll_vec):
	var container = get_child(0)
	if container == null:
		return
	var viewport_width = get_rect().size.x
	var container_width = container.get_size().x
	if container_width > viewport_width:
		var x = container.get_pos().x + scroll_vec.x
		x = clamp(x, viewport_width-container_width, 0)
		container.set_pos(Vector2(x, container.get_pos().y))
	var viewport_height = get_rect().size.y
	var container_height = container.get_size().y
	if container_height > viewport_height:
		var y = container.get_pos().y + scroll_vec.y
		y = clamp(y, viewport_height-container_height, 0)
		container.set_pos(Vector2(container.get_pos().x, y))
