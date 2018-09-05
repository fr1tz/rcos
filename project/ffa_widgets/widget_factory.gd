# Copyright © 2018 Michael Goldener <mg@wasted.ch>
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

extends Node

var mProductName = ""
var mProductId = ""
var mWidgetPath = ""

var mTaskId = -1

func _exit_tree():
	if mTaskId != -1:
		rcos.remove_task(mTaskId)

func initialize(product_name, product_id, widget_path):
	if mTaskId != -1:
		return
	mProductName = product_name
	mProductId = product_id
	mWidgetPath = widget_path
	mTaskId = rcos.add_task({
			"type": "widget_factory",
			"product_name": mProductName,
			"product_id": mProductId,
			"create_widget_func": funcref(self, "create_widget")
	})

func create_widget():
	return rlib.instance_scene(mWidgetPath)
