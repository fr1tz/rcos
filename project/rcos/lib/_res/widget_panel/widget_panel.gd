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

var mIOPortsPathPrefix = ""
var mWidgetHostApi = null
var mNextWidgetId = 1
var mOverlayDrawNodes = {}
var mEditMode = false
var mIndexToWidgetContainer = []
var mLoadingFromFile = false

onready var mWidgetContainers = get_node("widget_containers")
onready var mOverlay = get_node("overlay")

func _ready():
	mIOPortsPathPrefix = "rcos/widget_panel_"+str(get_instance_ID())+"/"
	mWidgetHostApi = preload("widget_host_api.gd").new(self)
	for i in range(0, 8):
		mIndexToWidgetContainer.push_back(null)
	rcos.connect("task_added", self, "_on_task_added")
	rcos.enable_canvas_input(self)

func _compute_widget_frame_pos(local_canvas_pos, widget_container):
	var win_rect = widget_container.get_global_rect()
	var win_center = win_rect.pos + win_rect.size/2
	var rot = widget_container.get_widget_rotation()
	var vec = (local_canvas_pos - win_center).rotated(-rot)
	var widget_frame = widget_container.get_widget_frame()
	var widget_frame_pos = widget_frame.get_rect().size/2 + vec
	return widget_frame_pos

func _canvas_input(event):
	var touchscreen = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.SCREEN_DRAG)
	var touch = (event.type == InputEvent.SCREEN_TOUCH || event.type == InputEvent.MOUSE_BUTTON)
	var drag = (event.type == InputEvent.SCREEN_DRAG || event.type == InputEvent.MOUSE_MOTION)
	if !touch && !drag:
		return
	var container = null
	var index = 0
	var down = null
	if touchscreen && event.index < 8:
		index = event.index
	if touch:
		if event.pressed:
			if !get_global_rect().has_point(event.pos):
				return
			var containers = get_widget_containers()
			containers.invert()
			for c in containers:
				if c.get_global_rect().has_point(event.pos):
					mIndexToWidgetContainer[index] = c
					container = c
					down = true
					break
		else:
			if rcos.gui.get_dangling_control(index) != null:
				var containers = get_widget_containers()
				containers.invert()
				for c in containers:
					if c.get_global_rect().has_point(event.pos):
						var fpos = _compute_widget_frame_pos(event.pos, c)
						c.get_widget_frame().update_input(index, fpos, false)
						break
			var widget_container = mIndexToWidgetContainer[index]
			if widget_container == null:
				return
			mIndexToWidgetContainer[index] = null
			container = widget_container
			down = false
	else:
		var widget_container = mIndexToWidgetContainer[index]
		if widget_container == null:
			return
		container = widget_container
		down = null
	if container == null:
		return
	var fpos = _compute_widget_frame_pos(event.pos, container)
	container.get_widget_frame().update_input(index, fpos, down)

func _add_widget_to_container(widget, container):
	var widget_name = container.get_widget_name()
	var io_ports_path_prefix = mIOPortsPathPrefix+widget_name+"/"
	container.add_widget(widget, io_ports_path_prefix)

func _update_widget_margins():
	if mLoadingFromFile:
		return
	for c in mWidgetContainers.get_children():
		c.set_self_opacity(1.0)
		c.set_widget_margin(0)
	for c1 in mWidgetContainers.get_children():
		var current_rect = c1.get_rect()
		current_rect.pos += Vector2(1, 1)
		current_rect.size -= Vector2(2, 2)
		for c2 in mWidgetContainers.get_children():
			if c2 != c1 && c2.get_rect().encloses(current_rect):
				c1.set_self_opacity(0.0)
				c1.set_widget_margin(2)
				break

func set_io_ports_path_prefix(prefix):
	mIOPortsPathPrefix = prefix

func create_widget_container():
	var container = rlib.instance_scene("res://rcos/lib/_res/widget_panel/widget_container.tscn")
	mWidgetContainers.add_child(container)
	container.connect("item_rect_changed", self, "_update_widget_margins")
	return container

func create_widget(widget_factory_task_id, pos, config_string = ""):
	var properties = rcos.get_task_properties(widget_factory_task_id)
	if !properties.has("product_id") || !properties.has("product_name"):
		return
	var widget_product_id = properties.product_id
	var widget = properties.create_widget_func.call_func()
	if widget == null:
		return
	if properties.has("product_icon"):
		widget.set_meta("icon32", properties.product_icon)
	if config_string == null:
		config_string = ""
	var widget_name = widget.get_name()
	var i = 1
	while mWidgetContainers.has_node(widget_name+"_"+str(i)+"_container"):
		i += 1
	widget_name += "_"+str(i)
	var widget_container = create_widget_container()
	widget_container.init(mWidgetHostApi, widget_name, properties.product_id,
		widget_container.ORIENTATION_N, config_string)
	_add_widget_to_container(widget, widget_container)
	widget_container.set_pos(pos)
	return widget_container

func toggle_edit_mode(edit_mode):
	if edit_mode:
		rcos.disable_canvas_input(self)
	else:
		rcos.enable_canvas_input(self)
	mEditMode = edit_mode

func update_size():
	var w = 0
	var h = 0
	for widget_container in mWidgetContainers.get_children():
		var rect = widget_container.get_rect()
		var p = rect.pos + rect.size
		if p.x > w: w = p.x
		if p.y > h: h = p.y
	set_size(Vector2(w, h))

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
		var widget_frame = widget_container.get_widget_frame()
		var widget_frame_size = widget_frame.get_rect().size
		var center = widget_container.get_pos() + widget_container.get_size()/2
		var rot = widget_container.get_widget_rotation()
		var pos = center + Vector2(-widget_frame_size.x/2, -widget_frame_size.y/2).rotated(rot)
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

func save_to_file(filename):
	if mWidgetContainers.get_child_count() == 0:
		return
	var file = File.new()
	if file.open(filename, File.WRITE) != OK:
		return
	var config = {
		"version": 0,
		"widget_containers": []
	}
	for widget_container in get_widget_containers():
		var pos = widget_container.get_pos()
		var size = widget_container.get_size()
		var widget_name = widget_container.get_widget_name()
		var widget_product_id = widget_container.get_widget_product_id()
		var widget_orientation = widget_container.get_widget_orientation()
		var widget_config_string = widget_container.get_widget_config_string()
		var container = {
			"x": pos.x,
			"y": pos.y,
			"width": size.x,
			"height": size.y,
			"widget_name": widget_name,
			"widget_product_id": widget_product_id,
			"widget_orientation": widget_orientation,
			"widget_config_string": widget_config_string
		}
		config.widget_containers.push_back(container)
	file.store_buffer(config.to_json().to_utf8())
	file.close()

func load_from_file(filename):
	clear()
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		return
	var text = file.get_buffer(file.get_len()).get_string_from_utf8()
	file.close()
	var config = {}
	if config.parse_json(text) != OK || config.empty():
		return
	mLoadingFromFile = true
	var tasks_list = rcos.get_task_list()
	if config.version == 0:
		for c in config.widget_containers:
			var widget_container = create_widget_container()
			widget_container.init(mWidgetHostApi, c.widget_name, c.widget_product_id, \
				c.widget_orientation, c.widget_config_string)
			widget_container.set_pos(Vector2(c.x, c.y))
			widget_container.set_size(Vector2(c.width, c.height))
			for task in tasks_list.values():
				if !task.properties.has("type") \
				|| !task.properties.has("product_id") \
				|| !task.properties.has("create_widget_func"):
					continue
				if task.properties.type == "widget_factory" \
				&& task.properties.product_id == c.widget_product_id:
					var widget = task.properties.create_widget_func.call_func()
					if widget == null:
						break
					if task.properties.has("product_icon"):
						widget.set_meta("icon32", task.properties.product_icon)
					_add_widget_to_container(widget, widget_container)
	mLoadingFromFile = false
	_update_widget_margins()

func _on_task_added(task):
	if !task.properties.has("type") \
	|| !task.properties.has("product_id") \
	|| !task.properties.has("create_widget_func"):
		return
	if task.properties.type != "widget_factory":
		return
	for widget_container in get_widget_containers():
		if widget_container.get_widget() != null:
			continue
		if task.properties.product_id == widget_container.get_widget_product_id():
			var widget = task.properties.create_widget_func.call_func()
			if widget == null:
				return
			if task.properties.has("product_icon"):
				widget.set_meta("icon32", task.properties.product_icon)
			var widget_name = widget_container.get_widget_name()
			var pos = widget_container.get_pos()
			var size = widget_container.get_size()
			_add_widget_to_container(widget, widget_container)
			widget_container.set_pos(pos)
			widget_container.set_size(size)
