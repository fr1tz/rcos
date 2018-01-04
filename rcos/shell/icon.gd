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

extends Sprite

func set_texture(texture):
	.set_texture(texture)
	if texture.has_meta("rotate") && texture.get_meta("rotate") == true:
		set_fixed_process(true)
	else:
		set_fixed_process(false)

func _fixed_process(delta):
	set_rot(get_rot() - delta*5)
