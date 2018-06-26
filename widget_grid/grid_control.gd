# Copyright © 2017, 2018 Michael Goldener <mg@wasted.ch>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

extends ColorFrame

var mWidgetHostApi = null
var mNextWidgetId = 1
var mOverlayDrawNodes = {}
var mEditMode = false
var mSelectedWidgetContainer = null
var mIndexToWidgetContainer = []

onready var mWidgetContainers = get_node("widget_containers")
onready var mOverlay = get_node("overlay")

func _ready():
	mWidgetHostApi = preload("widget_host_api.gd").new(self)
	for i in range(0, 8):
		mIndexToWidgetContainer.push_back(null)
	#load_from_file()
	rcos.connect("task_added", self, "_on_task_added")
	rcos.enable_canvas_input(self)

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var container = null
	var canvas = null
	var index = 0
	var fpos = null
	var down = null
	if touchscreen && event.index < 8:
		index = event.index
	if touch:
		if event.pressed:
			if !get_global_rect().has_point(event.pos):
				return
			for c in get_widget_containers():
				if c.get_global_rect().has_point(event.pos):
					mIndexToWidgetContainer[index] = c
					container = c
					canvas = c.get_widget_canvas()
					down = true
					break
		else:
			var widget_container = mIndexToWidgetContainer[index]
			if widget_container == null:
				return
			mIndexToWidgetContainer[index] = null
			container = widget_container
			canvas = widget_container.get_widget_canvas()
			down = false
	else:
		var widget_container = mIndexToWidgetContainer[index]
		if widget_container == null:
			return
		container = widget_container
		canvas = widget_container.get_widget_canvas()
		down = null
	if container == null || canvas == null:
		return
	var win_rect = container.get_global_rect()
	var win_center = win_rect.pos + win_rect.size/2
	var rot = container.get_widget_rotation()
	var vec = (event.pos - win_center).rotated(-rot)
	var canvas_pos = canvas.get_rect().size/2 + vec
	var fpos = canvas_pos
	canvas.update_input(index, fpos, down)

func _on_reshape_control_clicked(reshape_control):
	if mSelectedWidgetContainer != null:
		if reshape_control == mSelectedWidgetContainer.get_reshape_control():
			return
	if mSelectedWidgetContainer:
		mSelectedWidgetContainer.get_reshape_control().deselect()
	mSelectedWidgetContainer = reshape_control.get_control()
	reshape_control.select()

func add_widget_container():
	var widget_container = rlib.instance_scene("res://widget_grid/widget_container.tscn")
	mWidgetContainers.add_child(widget_container)
	widget_container.toggle_edit_mode(mEditMode)
	widget_container.connect("item_rect_changed", self, "update_size")
	var reshape_control = widget_container.get_reshape_control()
	reshape_control.connect("clicked", self, "_on_reshape_control_clicked", [reshape_control])
	update_size()
	return widget_container

func add_widget(widget_factory_task_id, pos):
	var task = rcos.get_task(widget_factory_task_id)
	if !task.has("product_id"):
		return
	var widget_id = mNextWidgetId
	mNextWidgetId += 1
	var widget_product_id = task.product_id
	var widget = task.create_widget_func.call_func()
	if widget == null:
		return
	var widget_container = add_widget_container()
	widget_container.init(mWidgetHostApi, widget_id, task.product_id)
	widget_container.add_widget(widget)
	widget_container.set_pos(pos)

func toggle_edit_mode(edit_mode):
	if edit_mode:
		rcos.disable_canvas_input(self)
	else:
		rcos.enable_canvas_input(self)
	mEditMode = edit_mode
	for widget_container in mWidgetContainers.get_children():
		widget_container.toggle_edit_mode(edit_mode)

func update_size():
	var w = 0
	var h = 0
	for widget_container in mWidgetContainers.get_children():
		var rect = widget_container.get_rect()
		var p = rect.pos + rect.size
		if p.x > w: w = p.x
		if p.y > h: h = p.y
	set_size(Vector2(w, h))

func get_selected_widget_container():
	return mSelectedWidgetContainer

func raiselower_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	var pos = mSelectedWidgetContainer.get_position_in_parent()
	if pos != mWidgetContainers.get_child_count() - 1:
		pos = mWidgetContainers.get_child_count() - 1
	else:
		pos = 0
	mWidgetContainers.move_child(mSelectedWidgetContainer, pos)

func rotate_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.rotate()

func configure_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.configure()

func delete_selected_widget():
	if mSelectedWidgetContainer == null:
		return
	mSelectedWidgetContainer.queue_free()
	mSelectedWidgetContainer = null
	update_size()

func enable_overlay_draw(node):
	if mOverlayDrawNodes.has(node):
		return
	if !node.has_method("_overlay_draw"):
		return
	var widget_container = null
	for c in mWidgetContainers.get_children():
		if c.is_a_parent_of(node):
			widget_container = c
			break
	if widget_container == null:
		return
	mOverlayDrawNodes[node] = widget_container

func disable_overlay_draw(node):
	mOverlayDrawNodes.erase(node)

func update_overlay_draw():
	mOverlay.update()

func draw_overlay():
	for node in mOverlayDrawNodes.keys():
		var widget_container = mOverlayDrawNodes[node]
		var canvas = widget_container.get_widget_canvas()
		var canvas_size = canvas.get_rect().size
		var center = widget_container.get_pos() + widget_container.get_size()/2
		var rot = widget_container.get_widget_rotation()
		var pos = center + Vector2(-canvas_size.x/2, -canvas_size.y/2).rotated(rot)
		var scale = Vector2(1, 1)
		mOverlay.draw_set_transform(pos, rot, scale)
		node._overlay_draw(mOverlay)

func get_widget_containers():
	return mWidgetContainers.get_children()

func clear():
	for widget_container in mWidgetContainers.get_children():
		mWidgetContainers.remove_child(widget_container)
		widget_container.queue_free()
	mNextWidgetId = 1

func save_to_file():
	if mWidgetContainers.get_child_count() == 0:
		return
	var dir = Directory.new()
	if !dir.dir_exists("user://etc"):
		dir.make_dir_recursive("user://etc")
	var file = File.new()
	if file.open("user://etc/widget_grid_conf.json", File.WRITE) != OK:
		return
	var config = {
		"version": 0,
		"widget_containers": []
	}
	for widget_container in get_widget_containers():
		var pos = widget_container.get_pos()
		var size = widget_container.get_size()
		var widget_id = widget_container.get_widget_id()
		var widget_product_id = widget_container.get_widget_product_id()
		var widget_orientation = widget_container.get_widget_orientation()
		var widget_config_string = widget_container.get_widget_config_string()
		var container = {
			"x": pos.x,
			"y": pos.y,
			"width": size.x,
			"height": size.y,
			"widget_id": widget_id,
			"widget_product_id": widget_product_id,
			"widget_orientation": widget_orientation,
			"widget_config_string": widget_config_string
		}
		config.widget_containers.push_back(container)
	file.store_buffer(config.to_json().to_utf8())
	file.close()

func load_from_file():
	clear()
	var file = File.new()
	if file.open("user://etc/widget_grid_conf.json", File.READ) != OK:
		return
	var text = file.get_buffer(file.get_len()).get_string_from_utf8()
	file.close()
	var config = {}
	if config.parse_json(text) != OK:
		return
	var tasks = rcos.get_task_list()
	if config.version == 0:
		for c in config.widget_containers:
			var widget_container = add_widget_container()
			widget_container.init(mWidgetHostApi, c.widget_id, c.widget_product_id, c.widget_orientation, c.widget_config_string)
			if c.widget_id >= mNextWidgetId:
				mNextWidgetId = c.widget_id + 1
			for task in tasks:
				if !task.has("type") || !task.has("product_id") || !task.has("create_widget_func"):
					continue
				if task.type == "widget_factory" && task.product_id == c.widget_product_id:
					var widget = task.create_widget_func.call_func()
					if widget == null:
						break
					widget_container.add_widget(widget)
			widget_container.set_pos(Vector2(c.x, c.y))
			widget_container.set_size(Vector2(c.width, c.height))

func _on_task_added(task):
	if !task.has("type") || !task.has("product_id") || !task.has("create_widget_func"):
		return
	if task.type != "widget_factory":
		return
	for widget_container in get_widget_containers():
		if widget_container.get_widget() != null:
			continue
		if task.product_id == widget_container.get_widget_product_id():
			var widget = task.create_widget_func.call_func()
			if widget == null:
				return
			var pos = widget_container.get_pos()
			var size = widget_container.get_size()
			widget_container.add_widget(widget)
			widget_container.set_pos(pos)
			widget_container.set_size(size)
