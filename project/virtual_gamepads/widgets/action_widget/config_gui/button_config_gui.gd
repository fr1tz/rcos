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

var mButtonConfig = null

onready var mButtonNumSlider = get_node("button_num/slider")
onready var mButtonNumValueLabel = get_node("button_num/value_label")

func _ready():
	mButtonNumSlider.connect("value_changed", self, "_button_num_changed")

func _button_num_changed(new_value):
	mButtonNumValueLabel.set_text(str(new_value))
	mButtonConfig["button_num"] = new_value
	get_meta("widget_root_node").get_main_gui().reload_widget_config()

func load_button_config(button_config):
	mButtonConfig = button_config
	mButtonNumSlider.set_value(mButtonConfig.button_num)
