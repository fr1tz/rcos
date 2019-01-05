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

export(Color) var grid_color = Color(0, 0, 0)

onready var mWidgetContainers = get_node("widget_containers")
onready var mOverlay = get_node("overlay")

var mPackedWidgetContainer = null
var mIOPortsPathPrefix = ""
var mNumColumns = 2
var mNumRows = 2
var mColumns = []
var mRows = []
var mWidgetHostApi = null
var mEditMode = false
var mIndexToWidgetContainer = []
var mOverlayDrawNodes = {}
var mLoadingFromFile = false

func _init():
	add_user_signal("grid_changed")
	add_user_signal("container_added")
	add_user_signal("container_changed")
	add_user_signal("container_removed")
	mPackedWidgetContainer = load("res://rcos_core/lib/_res/widget_grid/widget_container.tscn")

func _ready():
	connect("resized", self, "_resized")
	mIOPortsPathPrefix = "rcos/widget_panel_"+str(get_instance_ID())+"/"
	mWidgetHostApi = preload("widget_host_api.gd").new(self)
	for i in range(0, 8):
		mIndexToWidgetContainer.push_back(null)
	rcos_tasks.connect("task_added", self, "_on_task_added")
	rcos.enable_canvas_input(self)

func _resized():
	var width = get_size().x
	var height = get_size().y
	var spacing_x = width/mNumColumns
	var spacing_y = height/mNumRows
	mColumns.clear()
	var x = 0
	while x < width:
		mColumns.push_back(x)
		x += spacing_x
	mColumns.push_back(width)
	mRows.clear()
	var y = 0
	while y < height:
		mRows.push_back(y)
		y += spacing_y
	mRows.push_back(height)
	for widget_container in mWidgetContainers.get_children():
		_reshape_container(widget_container)
	emit_signal("grid_changed")

func _draw():
	var color = grid_color
	var width = get_size().x
	var height = get_size().y
	for x in mColumns:
		draw_line(Vector2(x, 0), Vector2(x, height), color)
	for y in mRows:
		draw_line(Vector2(0, y), Vector2(width, y), color)

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
			if rcos_gui.get_dangling_control(index) != null:
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

func _create_widget_container():
	var container = mPackedWidgetContainer.instance()
	mWidgetContainers.add_child(container)
	container.connect("item_rect_changed", self, "_update_widget_margins")
	container.connect("grid_rect_changed", self, "_reshape_container", [container])
	container.connect("exit_tree", self, "_container_removed", [container])
	emit_signal("container_added", container)
	return container

func _add_widget_to_container(widget, container):
	var widget_name = container.get_widget_name()
	var io_ports_path_prefix = mIOPortsPathPrefix+widget_name+"/"
	container.add_widget(widget, io_ports_path_prefix)

func _container_removed(container):
	emit_signal("container_removed", container)

func _reshape_container(widget_container):
	var grid_rect = widget_container.get_grid_rect()
	var column1 = grid_rect[0]
	var column2 = grid_rect[2] + 1
	var row1 = grid_rect[1]
	var row2 = grid_rect[3] + 1
	if column1 > mColumns.size() - 1:
		column1 = mColumns.size() - 2
	if row1 > mRows.size() - 1:
		row1 = mRows.size() - 2
	if column2 > mColumns.size() - 1:
		column2 = mColumns.size() - 1
	if row2 > mRows.size() - 1:
		row2 = mRows.size() - 1
	var x1 = mColumns[column1]
	var y1 = mRows[row1]
	var x2 = mColumns[column2]
	var y2 = mRows[row2]
	var width = x2 - x1
	var height = y2 - y1
	widget_container.set_pos(Vector2(x1, y1))
	widget_container.set_size(Vector2(width, height))
	emit_signal("container_changed", widget_container)

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

func get_num_columns():
	return mNumColumns

func get_num_rows():
	return mNumRows

func get_columns():
	return Array(mColumns)

func get_rows():
	return Array(mRows)

func set_grid(num_columns, num_rows):
	mNumColumns = num_columns
	mNumRows = num_rows
	_resized()
	update()

func set_io_ports_path_prefix(prefix):
	mIOPortsPathPrefix = prefix

func create_widget(widget_product_id, grid_rect, config_string = ""):
	var widgets_service = rcos.get_node("services/widgets_service")
	var widget_factory_tasks = widgets_service.get_widget_factory_tasks()
	var properties = null
	for task_id in widget_factory_tasks:
		var p = rcos_tasks.get_task_properties(task_id)
		if p.has("product_id") && p.product_id == widget_product_id:
			properties = p
			break
	if properties == null:
		return
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
	var widget_container = _create_widget_container()
	widget_container.init(mWidgetHostApi, grid_rect, widget_name, \
		properties.product_id, widget_container.ORIENTATION_N, config_string)
	_add_widget_to_container(widget, widget_container)
	_reshape_container(widget_container)
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
		remove_child(widget_container)
		widget_container.queue_free()

func save_to_file(filename):
	var file = File.new()
	if file.open(filename, File.WRITE) != OK:
		return false
	var config = {
		"version": 0,
		"num_columns": mNumColumns,
		"num_rows": mNumRows,
		"widget_containers": []
	}
	for widget_container in get_widget_containers():
		var grid_rect = widget_container.get_grid_rect()
		var widget_name = widget_container.get_widget_name()
		var widget_product_id = widget_container.get_widget_product_id()
		var widget_orientation = widget_container.get_widget_orientation()
		var widget_config_string = widget_container.get_widget_config_string()
		var container = {
			"grid_rect": grid_rect,
			"widget_name": widget_name,
			"widget_product_id": widget_product_id,
			"widget_orientation": widget_orientation,
			"widget_config_string": widget_config_string
		}
		config.widget_containers.push_back(container)
	file.store_buffer(config.to_json().to_utf8())
	file.close()
	return true

func load_from_file(filename):
	clear()
	var file = File.new()
	if file.open(filename, File.READ) != OK:
		return false
	var text = file.get_buffer(file.get_len()).get_string_from_utf8()
	file.close()
	var config = {}
	if config.parse_json(text) != OK || config.empty():
		return false
	mLoadingFromFile = true
	var tasks_list = rcos_tasks.get_task_list()
	if config.version == 0:
		set_grid(config.num_columns, config.num_rows)
		for c in config.widget_containers:
			var widget_container = _create_widget_container()
			widget_container.init(mWidgetHostApi, c.grid_rect, c.widget_name, \
				c.widget_product_id, c.widget_orientation, c.widget_config_string)
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
	return true

