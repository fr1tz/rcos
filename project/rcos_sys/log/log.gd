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

func _init():
	add_user_signal("new_log_entry3")

func _add_log_entry(source_node, level, content):
	emit_signal("new_log_entry3", source_node, level, content)

func debug(source_node, content):
	#prints("debug", source_node, content)
	_add_log_entry(source_node, "debug", content)

func notice(source_node, content):
	#prints("notice", source_node, content)
	_add_log_entry(source_node, "notice", content)

func error(source_node, content):
	#prints("error", source_node, content)
	_add_log_entry(source_node, "error", content)
