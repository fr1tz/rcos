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

extends Button

var mWidgetFactoryTaskId = -1
var mProductId = null
var mProductName = null
var mConfigPreset = null

func initialize(widget_factory_task_id, config_preset = null):
	var properties = rcos_tasks.get_task_properties(widget_factory_task_id)
	mWidgetFactoryTaskId = widget_factory_task_id
	mProductId = properties.product_id
	mProductName = properties.product_name
	mConfigPreset = config_preset
	set_text(mProductName)
	if typeof(mConfigPreset) == TYPE_STRING:
		set_text(get_text() + " (" + mConfigPreset + ")")
	if properties.has("product_icon"):
		set_button_icon(properties.product_icon)

func get_widget_factory_task_id():
	return mWidgetFactoryTaskId

func get_product_id():
	return mProductId

func get_product_name():
	return mProductName

func get_config_preset():
	return mConfigPreset
