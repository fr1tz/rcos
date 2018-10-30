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

onready var mModeButtons = get_node("mode_buttons")
onready var mTabs = get_node("tabs")
onready var mStickConfigGui = get_node("tabs/stick_config_gui")
onready var mDpadConfigGui = get_node("tabs/dpad_config_gui")
onready var mButtonConfigGui = get_node("tabs/button_config_gui")

func _ready():
	mModeButtons.connect("button_selected", self, "_mode_button_selected")

func _mode_button_selected(button_idx):
	if button_idx == 0 && mStickConfigGui.is_hidden():
		set_mode("stick")
	elif button_idx == 1 && mDpadConfigGui.is_hidden():
		set_mode("dpad")
	elif button_idx == 2 && mButtonConfigGui.is_hidden():
		set_mode("button")

func set_mode(mode):
	for c in mTabs.get_children():
		c.set_hidden(true)
	if mode == "stick":
		mModeButtons.set_selected(0)
		mStickConfigGui.set_hidden(false)
	elif mode == "dpad":
		mModeButtons.set_selected(1)
		mDpadConfigGui.set_hidden(false)
	elif mode == "button":
		mModeButtons.set_selected(2)
		mButtonConfigGui.set_hidden(false)
	get_meta("widget_root_node").config_gui.set_dirty()

func get_mode():
	if mModeButtons.get_selected() == 2:
		return "button"
	elif mModeButtons.get_selected() == 1:
		return "dpad"
	else:
		return "stick"

func load_emupad_config(emupad_config):
	if emupad_config == null || typeof(emupad_config) != TYPE_DICTIONARY:
		return false
	if !emupad_config.has("emulate"):
		return false
	if emupad_config.emulate == "stick":
		set_mode("stick")
	elif emupad_config.emulate == "dpad":
		set_mode("dpad")
	elif emupad_config.emulate == "button":
		set_mode("button")
	else:
		return false
	if !mStickConfigGui.load_stick_config(emupad_config.stick_config):
		return false
	if !mDpadConfigGui.load_dpad_config(emupad_config.dpad_config):
		return false
	if !mButtonConfigGui.load_button_config(emupad_config.button_config):
		return false
	return true

func create_emupad_config():
	var emupad_config = {
		"emulate": get_mode(),
		"stick_config": mStickConfigGui.create_stick_config(),
		"dpad_config": mDpadConfigGui.create_dpad_config(),
		"button_config": mButtonConfigGui.create_button_config()
	}
	return emupad_config
