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

extends ReferenceFrame

var mWidgetConfig = null
var mOn = true

onready var mPads = get_node("pads")
onready var mIcons = get_node("icons")

func _ready():
	connect("resized", self, "reload_widget_config")

func _create_pad():
	var pad = load("res://lsr_widgets/gamepad_widgets/main_gui/touchpad_control.tscn").instance()
	rlib.set_meta_recursive(pad, "widget_host_api", get_meta("widget_host_api"))
	rlib.set_meta_recursive(pad, "widget_id", get_meta("widget_id"))
	return pad

func reload_widget_config():
	load_widget_config(mWidgetConfig)

func load_widget_config(widget_config):
	mWidgetConfig = widget_config
	for c in mPads.get_children():
		mPads.remove_child(c)
		c.queue_free()
	if mWidgetConfig.basic_config.num_pads == 2:
		var margin = 5
		var verts
		var pad
		verts = Vector2Array()
		verts.append(Vector2(margin, get_size().y-margin))
		verts.append(Vector2(margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		pad = _create_pad()
		mPads.add_child(pad)
		pad.set_name("pad1")
		pad.set_size(get_size())
		pad.set_polygon(verts)
		pad.load_touchpad_config(mWidgetConfig.pad_configs[0])
		verts = Vector2Array()
		verts.append(Vector2(get_size().x-margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		verts.append(Vector2(margin, margin))
		pad = _create_pad()
		mPads.add_child(pad)
		pad.set_name("pad2")
		pad.set_size(get_size())
		pad.set_polygon(verts)
		pad.load_touchpad_config(mWidgetConfig.pad_configs[1])
	else:
		var margin = 5
		var verts = Vector2Array()
		verts.append(Vector2(margin, margin))
		verts.append(Vector2(get_size().x-margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		verts.append(Vector2(margin, get_size().y-margin))
		var pad = _create_pad()
		mPads.add_child(pad)
		pad.set_name("pad1")
		pad.set_size(get_size())
		pad.set_polygon(verts)
		pad.load_touchpad_config(mWidgetConfig.pad_configs[0])
	if mOn:
		turn_on()

func update_joystick_state(state):
	for pad in mPads.get_children():
		pad.update_joystick_state(state)

func turn_on():
	mOn = true
	for pad in mPads.get_children():
		pad.turn_on()

func turn_off():
	mOn = false
	for pad in mPads.get_children():
		pad.turn_off()
