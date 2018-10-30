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

var mWidgetConfig = null

onready var mLayoutButtons = get_node("layout_buttons")
onready var mEmupadTabs = get_node("emupad_tabs")
onready var mApplyButton = get_node("apply_button")
onready var mCloseButton = get_node("apply_button")

func _ready():
	mLayoutButtons.connect("button_selected", self, "_layout_button_selected")
	mApplyButton.connect("pressed", self, "_apply_widget_config")
	mCloseButton.connect("pressed", self, "_close")

func _layout_button_selected(button_idx):
	set_dirty()

func _apply_widget_config():
	mWidgetConfig = create_widget_config()
	get_meta("widget_root_node").main_gui.load_widget_config(mWidgetConfig)
	mApplyButton.set_disabled(true)

func _close():
	return

func _get_default_widget_config():
	var widget_config = {
		"version": 0,
		"pad_layout": "1",
		"pad_configs": [ null, null, null, null ]
	}
	for i in range(0, 4):
		widget_config.pad_configs[i] = {
			"emulate": "stick",
			"stick_config": {
				"radius": 32,
				"threshold": 0,
				"x_action": "axis_x",
				"y_action": "axis_y",
				
			},
			"dpad_config": {
				"radius": 32,
				"threshold": 10
			},
			"button_config": {
				"mode": 0
			}
		}
	return widget_config

func _config_string_to_widget_config(config_string):
	if config_string == null:
		return _get_default_widget_config()
	var widget_config = null
	if config_string == "Stick":
		widget_config = _get_default_widget_config()
		widget_config.pad_configs[0].emulate = "stick"
	elif config_string == "DPad":
		widget_config = _get_default_widget_config()
		widget_config.pad_configs[0].emulate = "dpad"
	elif config_string == "1 Button":
		widget_config = _get_default_widget_config()
		widget_config.pad_configs[0].emulate = "button"
	elif config_string == "2 Buttons":
		widget_config = _get_default_widget_config()
		widget_config.pad_layout = "2a"
		widget_config.pad_configs[0].emulate = "button"
		widget_config.pad_configs[1].emulate = "button"
	elif config_string == "4 Buttons":
		widget_config = _get_default_widget_config()
		widget_config.pad_layout = "4"
		widget_config.pad_configs[0].emulate = "button"
		widget_config.pad_configs[1].emulate = "button"
		widget_config.pad_configs[2].emulate = "button"
		widget_config.pad_configs[3].emulate = "button"
	else:
		widget_config = Dictionary()
		if widget_config.parse_json(config_string) != OK:
			widget_config = _get_default_widget_config()
	return widget_config

func get_emupad_layout():
	if mLayoutButtons.get_selected() == 3:
		return "4"
	elif mLayoutButtons.get_selected() == 2:
		return "2b"
	elif mLayoutButtons.get_selected() == 1:
		return "2a"
	else:
		return "1"

func load_widget_config(widget_config):
	if !widget_config.has("version") || widget_config.version != 0:
		return false
	if !widget_config.has("pad_layout"):
		return false
	if widget_config.pad_layout == "1":
		mLayoutButtons.set_selected(0)
	elif widget_config.pad_layout == "2a":
		mLayoutButtons.set_selected(1)
	elif widget_config.pad_layout == "2b":
		mLayoutButtons.set_selected(2)
	elif widget_config.pad_layout == "4":
		mLayoutButtons.set_selected(3)
	else:
		return false
	if !widget_config.has("pad_configs"):
		return false
	if typeof(widget_config.pad_configs) != TYPE_ARRAY:
		return false
	if widget_config.pad_configs.size() != 4:
		return false
	for i in range(0, 4):
		var emupad_config = widget_config.pad_configs[i]
		if !mEmupadTabs.get_child(i).load_emupad_config(emupad_config):
			return false
	return true

func create_widget_config():
	var widget_config = {
		"version": 0,
		"pad_layout": get_emupad_layout(),
		"pad_configs": [ null, null, null, null ]
	}
	for i in range(0, 4):
		var emupad_config = mEmupadTabs.get_child(i).create_emupad_config()
		widget_config.pad_configs[i] = emupad_config
	return widget_config

func load_widget_config_string(config_string):
	var widget_config = _config_string_to_widget_config(config_string)
	if !load_widget_config(widget_config):
		return false
	_apply_widget_config()
	return true

func create_widget_config_string():
	if mWidgetConfig != null:
		return mWidgetConfig.to_json()
	return null

func set_dirty():
	# Ignore call while loading initial config.
	if mWidgetConfig == null:
		return
	mApplyButton.set_disabled(false)

func go_back():
	return false
