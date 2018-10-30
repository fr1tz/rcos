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

onready var mButtonNumSlider = get_node("button_num/slider")
onready var mButtonNumValueLabel = get_node("button_num/value_label")
onready var mButtonNumDecButton = get_node("button_num/dec_button")
onready var mButtonNumIncButton = get_node("button_num/inc_button")
onready var mModeButtons = get_node("mode/mode_buttons")

func _ready():
	mButtonNumSlider.connect("value_changed", self, "_button_num_changed")
	mButtonNumDecButton.connect("pressed", self, "_decrease_button_num")
	mButtonNumIncButton.connect("pressed", self, "_increase_button_num")
	mModeButtons.connect("button_selected", self, "_mode_button_selected")

func _button_num_changed(new_value):
	mButtonNumValueLabel.set_text(str(new_value))
	get_meta("widget_root_node").config_gui.set_dirty()

func _decrease_button_num():
	mButtonNumSlider.set_value(mButtonNumSlider.get_value()-1)

func _increase_button_num():
	mButtonNumSlider.set_value(mButtonNumSlider.get_value()+1)

func _mode_button_selected(button_idx):
	get_meta("widget_root_node").config_gui.set_dirty()

func load_button_config(button_config):
	if !button_config.has("mode"):
		return false
	if button_config.mode < 0 || button_config.mode > 1:
		return false
	mModeButtons.set_selected(button_config.mode)
	return true

func create_button_config():
	var button_config = {
		"mode": mModeButtons.get_selected()
	}
	return button_config
