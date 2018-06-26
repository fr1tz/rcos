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

onready var mConfigurePad1Button = get_node("configure_pad1_button")
onready var mConfigurePad2Button = get_node("configure_pad2_button")
onready var m2PadsButton = get_node("2_pads_button")
onready var mTouchpadConfigGui = get_node("touchpad_config_gui")

func _ready():
	m2PadsButton.connect("pressed", self, "_num_pads_changed")
	mConfigurePad1Button.connect("pressed", self, "configure_pad", [0])
	mConfigurePad2Button.connect("pressed", self, "configure_pad", [1])

func _num_pads_changed():
	if m2PadsButton.is_pressed():
		mWidgetConfig.basic_config.num_pads = 2
	else:
		mWidgetConfig.basic_config.num_pads = 1
	get_meta("widget_root_node").get_main_gui().reload_widget_config()

func configure_pad(pad_idx):
	if pad_idx == 0:
		mConfigurePad1Button.set_pressed(true)
		mConfigurePad2Button.set_pressed(false)
	else:
		mConfigurePad1Button.set_pressed(false)
		mConfigurePad2Button.set_pressed(true)
	var touchpad_config = mWidgetConfig.pad_configs[pad_idx]
	mTouchpadConfigGui.load_touchpad_config(touchpad_config)

func load_widget_config(widget_config):
	mWidgetConfig = widget_config
	if mWidgetConfig.basic_config.num_pads == 1:
		mConfigurePad2Button.set_hidden(true)
		m2PadsButton.set_pressed(true)
	elif mWidgetConfig.basic_config.num_pads == 2:
		mConfigurePad2Button.set_hidden(false)
		m2PadsButton.set_pressed(false)
	configure_pad(0)

func go_back():
	return false
