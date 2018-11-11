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

extends Panel

const ORIENTATION_N = 0
const ORIENTATION_E = 1
const ORIENTATION_S = 2
const ORIENTATION_W = 3

var mWidgetHostApi = null
var mEditMode = false
var mWidget = null
var mWidgetName = -1
var mWidgetOrientation = ORIENTATION_N
var mWidgetProductId = ""
var mWidgetConfigString = ""
var mConfigTaskId = -1

onready var mContent = get_node("content")
#onready var mWidgetWindow = get_node("widget_window")
onready var mViewportSprite = get_node("viewport_sprite")

func _ready():
	connect("resized", self, "_resized")

func _resized():
	var pos = Vector2(0, 0)
	var size = get_size()
	var rot
	var rot_deg
	if mWidgetOrientation == ORIENTATION_E:
		rot = PI+PI/2
		rot_deg = 270
		pos = Vector2(size.x, 0)
		size = Vector2(size.y, size.x)
	elif mWidgetOrientation == ORIENTATION_S:
		rot = PI
		rot_deg = 180
		pos = Vector2(size.x, size.y)
	elif mWidgetOrientation == ORIENTATION_W:
		rot = PI/2
		rot_deg = 90
		pos = Vector2(0, size.y)
		size = Vector2(size.y, size.x)
	else:
		rot = 0
		rot_deg = 0
		pos = Vector2(0, 0)
#	mWidgetWindow.set_rotation_deg(rot_deg)
#	mWidgetWindow.set_pos(pos)
#	mWidgetWindow.set_size(size)
	mViewportSprite.set_pos(get_size()/2)
	mViewportSprite.set_rot(rot)
	var canvas = get_widget_canvas()
	if canvas == null:
		return
	canvas.resize(size)

func _config_task_go_back():
	if mWidget.has_method("get_config_gui"):
		var config_gui = mWidget.get_config_gui()
		if config_gui != null:
			if config_gui.has_method("go_back"):
				var went_back = config_gui.go_back()
				if went_back:
					return true
	rcos.remove_task(mConfigTaskId)
	mConfigTaskId = -1
	return true

func init(widget_host_api, widget_name, widget_product_id = "", widget_orientation = ORIENTATION_N, widget_config_string = ""):
	mWidgetHostApi = widget_host_api
	mWidgetName = widget_name
	mWidgetProductId = widget_product_id
	mWidgetOrientation = widget_orientation
	mWidgetConfigString = widget_config_string
	set_name(mWidgetName+"_container")
	get_node("widget_product_id_label").set_text(mWidgetProductId)

func add_widget(widget, widget_io_ports_path_prefix):
	if widget == null || !widget.has_node("main_canvas"):
		return
	mWidget = widget
	var main_canvas = null
	#var main_canvas_size = Vector2(40, 40)
	var main_canvas_size = get_size()
	var main_canvas_min_size = Vector2(20, 20)
	var config_canvas = null
	var config_canvas_size = Vector2(40, 40)
	var main_canvas_placeholder = mWidget.get_node("main_canvas")
	#main_canvas_size.x = main_canvas_placeholder.get_margin(MARGIN_RIGHT)
	#main_canvas_size.y = main_canvas_placeholder.get_margin(MARGIN_BOTTOM)
	#main_canvas_min_size = main_canvas_placeholder.get_custom_minimum_size()
	main_canvas = rlib.instance_scene("res://rcos_core/lib/canvas.tscn")
	main_canvas_placeholder.replace_by(main_canvas)
	main_canvas_placeholder.free()
	main_canvas.set_rect(Rect2(Vector2(0, 0), main_canvas_size))
	main_canvas.set_name("main_canvas")
	main_canvas.min_size = main_canvas_min_size
	main_canvas.resizable = true
	if mWidget.has_node("config_canvas"):
		var config_canvas_placeholder = mWidget.get_node("config_canvas")
		config_canvas_size.x = config_canvas_placeholder.get_margin(MARGIN_RIGHT)
		config_canvas_size.y = config_canvas_placeholder.get_margin(MARGIN_BOTTOM)
		config_canvas = rlib.instance_scene("res://rcos_core/lib/canvas.tscn")
		config_canvas_placeholder.replace_by(config_canvas)
		config_canvas_placeholder.free()
		config_canvas.resizable = false
		config_canvas.set_rect(Rect2(Vector2(0, 0), config_canvas_size))
		config_canvas.set_name("config_canvas")
	rlib.set_meta_recursive(mWidget, "widget_io_ports_path_prefix", widget_io_ports_path_prefix)
	rlib.set_meta_recursive(mWidget, "widget_host_api", mWidgetHostApi)
	rlib.set_meta_recursive(mWidget, "widget_root_node", mWidget)
	mContent.add_child(mWidget)
	if mWidgetConfigString != "" && mWidget.has_method("load_widget_config_string"):
		mWidget.load_widget_config_string(mWidgetConfigString)
	if config_canvas:
		config_canvas.set_rect(Rect2(Vector2(0, 0), config_canvas.get_child(0).get_size()))
	var size = get_size()
	#set_size(size)
	main_canvas.resize(size)
#	mWidgetWindow.set_pos(Vector2(0, 0))
#	mWidgetWindow.set_size(size)
#	mWidgetWindow.show_canvas(main_canvas)
#	mWidgetWindow.set_hidden(true)
	main_canvas.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_WHEN_VISIBLE)
	mViewportSprite.set_viewport_path(main_canvas.get_path())
	get_node("widget_product_id_label").set_hidden(true)

func get_widget():
	return mWidget

func get_widget_name():
	return mWidgetName

func get_widget_product_id():
	return mWidgetProductId

func get_widget_config_string():
	if mWidget != null && mWidget.has_method("create_widget_config_string"):
		mWidgetConfigString = mWidget.create_widget_config_string()
	return mWidgetConfigString

func get_widget_orientation():
	return mWidgetOrientation

func get_widget_canvas():
	if mWidget == null:
		return null
	return mWidget.get_node("main_canvas")

func get_config_canvas():
	return mWidget.get_node("config_canvas")

func get_widget_rotation():
	return mViewportSprite.get_rot()

func rotate():
	mWidgetOrientation += 1
	if mWidgetOrientation == 4:
		mWidgetOrientation = 0
	_resized()

func set_widget_margin(margin):
	var canvas = get_widget_canvas()
	if canvas == null: 
		return
	canvas.resize(get_size() - Vector2(margin*2, margin*2))

func configure(config_task_parent_task_id):
	var config_canvas = get_config_canvas()
	if config_canvas == null:
		return
	if mConfigTaskId == -1:
		var task_properties = {
			"name": mWidget.get_name()+" Settings",
			"icon": load("res://modules/widget_grid/graphics/icons/widget_settings.png"),
			"canvas": config_canvas,
			"ops": {
				"go_back": funcref(self, "_config_task_go_back")
			},
			"focus_wanted": true
		}
		mConfigTaskId = rcos.add_task(task_properties, config_task_parent_task_id)
