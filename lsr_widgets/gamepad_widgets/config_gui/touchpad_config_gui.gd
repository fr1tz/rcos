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

extends Control

var mTouchpadConfig = null

onready var mModeButtons = get_node("mode_buttons")
onready var mTabs = get_node("tabs")

func _ready():
	mModeButtons.connect("button_selected", self, "_mode_button_selected")

func _mode_button_selected(button_idx):
	if button_idx == 0:
		set_mode("stick")
	elif button_idx == 1:
		set_mode("dpad")
	elif button_idx == 2:
		set_mode("button")

func load_touchpad_config(touchpad_config):
	mTouchpadConfig = touchpad_config
	get_node("tabs/stick_config_gui").load_stick_config(touchpad_config.stick_config)
	get_node("tabs/dpad_config_gui").load_dpad_config(touchpad_config.dpad_config)
	get_node("tabs/button_config_gui").load_button_config(touchpad_config.button_config)
	set_mode(mTouchpadConfig.mode)

func set_mode(mode):
	mTouchpadConfig.mode = mode
	if mTouchpadConfig.mode == "stick":
		mModeButtons.set_selected(0)
		mTabs.set_current_tab(0)
	elif mTouchpadConfig.mode == "dpad":
		mModeButtons.set_selected(1)
		mTabs.set_current_tab(1)
	elif mTouchpadConfig.mode == "button":
		mModeButtons.set_selected(2)
		mTabs.set_current_tab(2)
	get_meta("widget_root_node").get_main_gui().reload_widget_config()
