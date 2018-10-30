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

onready var mRadiusSlider = get_node("radius/slider")
onready var mRadiusValueLabel = get_node("radius/value_label")
onready var mThresholdSlider = get_node("threshold/slider")
onready var mThresholdValueLabel = get_node("threshold/value_label")

func _ready():
	mRadiusSlider.connect("value_changed", self, "_radius_changed")
	mThresholdSlider.connect("value_changed", self, "_threshold_changed")

func _radius_changed(new_value):
	mRadiusValueLabel.set_text(str(new_value))
	get_meta("widget_root_node").config_gui.set_dirty()

func _threshold_changed(new_value):
	mThresholdValueLabel.set_text(str(new_value))
	get_meta("widget_root_node").config_gui.set_dirty()

func load_stick_config(stick_config):
	mRadiusSlider.set_value(stick_config.radius)
	mThresholdSlider.set_value(stick_config.threshold)
	return true

func create_stick_config():
	var stick_config = {
		"radius": mRadiusSlider.get_value(),
		"threshold": mThresholdSlider.get_value()
	}
	return stick_config
