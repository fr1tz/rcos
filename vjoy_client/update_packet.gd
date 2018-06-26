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

func encode_int7(val):
	var negative = val < 0
	val = int(abs(val)) 
	var byte = val & 127
	if negative:
		byte = byte | 128
	var b2 = val & 0xFF
	return byte

func encode_int15(val):
	var negative = val < 0
	val = int(abs(val)) 
	var b1 = val >> 8
	if negative:
		b1 = b1 | 128
	var b2 = val & 0xFF
	var bytes = RawArray()
	bytes.append(b1)
	bytes.append(b2)
	return bytes

func encode_uint16(val):
	var b1 = val >> 8
	var b2 = val & 0xFF
	var bytes = RawArray()
	bytes.append(b1)
	bytes.append(b2)
	return bytes

func _create_button_segment(state):
	var button_segment_header = 0
	var button_segment_data = RawArray()
	var pressed_buttons = []
	for i in range(0, 128):
		if state.buttons[i] == true:
			pressed_buttons.push_back(i)
	if pressed_buttons.size() < 16:
		for button_idx in pressed_buttons:
			button_segment_data.append(button_idx)
		button_segment_data.append(255) # mark end of buttons list
	else:
		var button_groups = []
		button_groups.resize(16)
		for button_group_idx in range(0, 16):
			button_groups[button_group_idx] = 0
			for button_idx in range(0, 8):
				var pressed = state.buttons[8*button_group_idx+button_idx]
				if pressed:
					button_groups[button_group_idx] |= 1 << button_idx
			if button_groups[button_group_idx] != 0:
				button_segment_header |= 1 << button_group_idx
				button_segment_data.append(button_groups[button_group_idx])
	var button_segment = RawArray()
	button_segment.append_array(encode_uint16(button_segment_header))
	button_segment.append_array(button_segment_data)
	return button_segment

func _create_axis_segment(state):
	var axis_segment_header = 0
	var axis_segment_data = RawArray()
	var axis_states = []
	axis_states.push_back(int((clamp(state.axis_x, -1, 1)*127)))
	axis_states.push_back(int((clamp(state.axis_y, -1, 1)*127)))
	axis_states.push_back(int((clamp(state.axis_z, -1, 1)*127)))
	axis_states.push_back(int((clamp(state.axis_x_rot, -1, 1)*127)))
	axis_states.push_back(int((clamp(state.axis_y_rot, -1, 1)*127)))
	axis_states.push_back(int((clamp(state.axis_z_rot, -1, 1)*127)))
	axis_states.push_back(int((clamp(state.slider1, -1, 1)*127)))
	axis_states.push_back(int((clamp(state.slider2, -1, 1)*127)))
	for i in range(0, 8):
		if axis_states[i] != 0:
			axis_segment_header |= 1 << i
			axis_segment_data.append(encode_int7(axis_states[i]))
	var axis_segment = RawArray()
	axis_segment.append(axis_segment_header)
	axis_segment.append_array(axis_segment_data)
	return axis_segment

func _create_controller_segment(vjoy_ctrl):
	var state = vjoy_ctrl.get_state()
	var axis_segment = _create_axis_segment(state)
	var button_segment = _create_button_segment(state)
	if axis_segment.size() == 1 && button_segment.size() == 3 && button_segment[2] == 255:
		return null
	var controller_segment = RawArray()
	controller_segment.append_array(axis_segment)
	controller_segment.append_array(button_segment)
	return controller_segment

func create_packet(client_id, vjoy_controllers):
	var packet_header = 10 # magic byte
	var controller_segments_header = 0
	var controller_segments = []
	for i in range(0, vjoy_controllers.get_child_count()):
		var vjoy_ctrl = vjoy_controllers.get_child(i)
		var segment = _create_controller_segment(vjoy_ctrl)
		if segment != null:
			controller_segments_header |= 1 << i
			controller_segments.push_back(segment)
	var packet = RawArray()
	packet.append(packet_header)
	packet.append_array(encode_uint16(client_id))
	if controller_segments.size() > 0:
		packet.append_array(encode_uint16(controller_segments_header))
		for segment in controller_segments:
			packet.append_array(segment)
	return packet
