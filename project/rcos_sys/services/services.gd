# Copyright © 2017-2019 Michael Goldener <mg@wasted.ch>
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

func add_service(service_node):
	var service_name = service_node.get_name()
	if has_node(service_name):
		rcos_log.error(self, "add_service(): Service " + service_name + "already exists")
		return false
	add_child(service_node)
	return true

func get_service(service_name):
	if has_node(service_name):
		return get_node(service_name)
	return null
