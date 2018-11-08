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

func _ready():
	connect("resized", self, "reload_widget_config")

func _create_pad(pad_name, verts, emupad_config):
	var io_ports_path_prefix = get_meta("io_ports_path_prefix") + "/" + pad_name
	var pad = load("res://modules/virtual_gamepads/emupad/emupad_control.tscn").instance()
	pad.set_name(pad_name)
	rlib.set_meta_recursive(pad, "widget_host_api", get_meta("widget_host_api"))
	rlib.set_meta_recursive(pad, "io_ports_path_prefix", io_ports_path_prefix)
	mPads.add_child(pad)
	pad.set_size(get_size())
	pad.set_polygon(verts)
	pad.load_emupad_config(emupad_config)
	return pad

func reload_widget_config():
	load_widget_config(mWidgetConfig)

func load_widget_config(widget_config):
	mWidgetConfig = widget_config
	for c in mPads.get_children():
		mPads.remove_child(c)
		c.queue_free()
	var margin = 5
	var center = get_size() / 2
	var verts
	if mWidgetConfig.pad_layout == "4":
		# Pad 1
		verts = Vector2Array()
		verts.append(center)
		verts.append(Vector2(margin, get_size().y-margin))
		verts.append(Vector2(margin, margin))
		_create_pad("pad1", verts, mWidgetConfig.pad_configs[0])
		# Pad 2
		verts = Vector2Array()
		verts.append(center)
		verts.append(Vector2(get_size().x-margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		_create_pad("pad2", verts, mWidgetConfig.pad_configs[1])
		# Pad 3
		verts = Vector2Array()
		verts.append(center)
		verts.append(Vector2(margin, margin))
		verts.append(Vector2(get_size().x-margin, margin))
		_create_pad("pad3", verts, mWidgetConfig.pad_configs[2])
		# Pad 4
		verts = Vector2Array()
		verts.append(center)
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		verts.append(Vector2(margin, get_size().y-margin))
		_create_pad("pad4", verts, mWidgetConfig.pad_configs[3])
	elif mWidgetConfig.pad_layout == "2a":
		# Pad 1
		verts = Vector2Array()
		verts.append(Vector2(margin, get_size().y-margin))
		verts.append(Vector2(margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		_create_pad("pad1", verts, mWidgetConfig.pad_configs[0])
		# Pad 2
		verts = Vector2Array()
		verts.append(Vector2(get_size().x-margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		verts.append(Vector2(margin, margin))
		_create_pad("pad2", verts, mWidgetConfig.pad_configs[1])
	elif mWidgetConfig.pad_layout == "2b":
		# Pad 1
		verts = Vector2Array()
		verts.append(Vector2(margin, margin))
		verts.append(Vector2(get_size().x-margin, margin))
		verts.append(Vector2(margin, get_size().y-margin))
		_create_pad("pad1", verts, mWidgetConfig.pad_configs[0])
		# Pad 2
		verts = Vector2Array()
		verts.append(Vector2(get_size().x-margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		verts.append(Vector2(margin, get_size().y-margin))
		_create_pad("pad2", verts, mWidgetConfig.pad_configs[1])
	else:
		# Pad 1
		verts = Vector2Array()
		verts.append(Vector2(margin, margin))
		verts.append(Vector2(get_size().x-margin, margin))
		verts.append(Vector2(get_size().x-margin, get_size().y-margin))
		verts.append(Vector2(margin, get_size().y-margin))
		_create_pad("pad1", verts, mWidgetConfig.pad_configs[0])
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
