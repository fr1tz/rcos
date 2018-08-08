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

extends Node

var mVrcHost = null
var mVrcHostApi = null
var mStream = null
var mRemoteAddress = ""
var mRemotePort = -1
var mReceiveBuffer = RawArray()
var mSendBuffer = RawArray()
var mCurrentDatablockName = ""
var mVrcDataSize = 0
var mVrcData = null;
var mLastCommandError = ""
var mCommands = {
	"load_vrc": funcref(self, "_cmd_load_vrc"),
	"log_debug": funcref(self, "_cmd_log_debug"),
	"log_notice": funcref(self, "_cmd_log_notice"),
	"log_error": funcref(self, "_cmd_log_error"),
	"remove_vrc": funcref(self, "_cmd_remove_vrc"),
	"set_var": funcref(self, "_cmd_set_var")
}

func _cmd_load_vrc(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: VRC_DATA_SIZE"
	elif cmdline.arguments.size() > 1:
		return "got more than 1 arguments"
# TODO:
#	var from = source.get_remote_address_string()
#	if cmdline.attributes.has("from"):
#		from = cmdline.attributes["from"]
	mVrcDataSize = int(cmdline.arguments[0])
	mVrcData = RawArray();
	return ""
	
func _cmd_log_debug(cmdline):
	var msg = cmdline.arguments_raw
	return mVrcHostApi.log_debug(self, msg)

func _cmd_log_notice(cmdline):
	var msg = cmdline.arguments_raw
	return mVrcHostApi.log_notice(self, msg)

func _cmd_log_error(cmdline):
	var msg = cmdline.arguments_raw
	return mVrcHostApi.log_error(self, msg)

func _cmd_set_var(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: VAR_NAME, VAR_VALUE"
	elif cmdline.arguments.size() == 1:
		return "missing argument: VAR_VALUE"
	elif cmdline.arguments.size() > 2:
		return "got more than 2 arguments"
	var var_name = cmdline.arguments[0]
	var var_value = cmdline.arguments[1]
	return mVrcHostApi.set_var(var_name, var_value)

func _process_network_io():
	_receive_data()
	_process_data()
	_send_data()

func _process_data():
	var n = 10
	while n > 0:
		if mReceiveBuffer.size() == 0:
			return
		n -= 1
		if mVrcData == null: # Reading VHCP messages
			var msg_size = -1
			for i in range(0, mReceiveBuffer.size()):
				if mReceiveBuffer[i] == 10: # Line feed
					msg_size = i
					break
			if msg_size == -1:
				break
			if msg_size > 0:
				var msg_data = RawArray(mReceiveBuffer)
				msg_data.resize(msg_size);
				var msg = msg_data.get_string_from_utf8()
				_process_vhcp_msg(msg)
			mReceiveBuffer.invert()
			mReceiveBuffer.resize(mReceiveBuffer.size()-msg_size-1)
			mReceiveBuffer.invert()
		else: # Reading VRC data
			var remaining_bytes = mVrcDataSize - mVrcData.size()
			if remaining_bytes >= mReceiveBuffer.size():
				mVrcData.append_array(mReceiveBuffer)
				mReceiveBuffer.resize(0)
			else:
				var buf = RawArray(mReceiveBuffer)
				buf.resize(remaining_bytes)
				mVrcData.append_array(buf)
				mReceiveBuffer.invert()
				mReceiveBuffer.resize(mReceiveBuffer.size()-buf.size())
				mReceiveBuffer.invert()
			var progress = float(mVrcData.size()) / float(mVrcDataSize)
			mVrcHostApi.update_vrc_download_progress(progress)
			if mVrcData.size() == mVrcDataSize:
				mVrcHostApi.load_vrc(mVrcData)
				mVrcData = null

func _process_vhcp_msg(msg):
	mVrcHostApi.log_debug(self, ["_process_vhcp_msg()", msg])
	if msg.empty():
		mVrcHostApi.log_debug(self, "	ignoring empty msg")
		return
	var slash_idx = msg.find("/")
	if slash_idx == -1:
		mLastCommandError = "no command specified (missing '/')"
		return
	var cmdline = mVrcHost.parse_cmdline(msg.right(slash_idx+1))
	if cmdline == null:
		mLastCommandError = "error parsing command line"
		return
	mLastCommandError = ""
	if mCommands.has(cmdline.command):
		mLastCommandError = mCommands[cmdline.command].call_func(cmdline)
	else:
		if mVrcHostApi.has_vhcp_extension(cmdline.command):
			mLastCommandError = mVrcHostApi.call_vhcp_extension(cmdline.command, cmdline, self)
		else:
			mLastCommandError = "unknown command: " + cmdline.command
	if mLastCommandError == null:
		mLastCommandError = ""
	if mLastCommandError == "":
		mVrcHostApi.log_debug(self, ["COMMAND_SUCCEEDED", msg])
	else:
		mVrcHostApi.log_error(self, ["COMMAND_FAILED", msg, mLastCommandError])

func _send_data():
	if mSendBuffer.size() == 0:
		return
	var r = mStream.put_partial_data(mSendBuffer)
	var error = r[0]
	var nbytes = r[1]
	if error:
		mVrcHostApi.log_debug(self, ["_send_data() ERROR:", error])
		return
	mSendBuffer.invert()
	mSendBuffer.resize(mSendBuffer.size()-nbytes)
	mSendBuffer.invert()

func _receive_data():
	if mStream.get_available_bytes() == 0:
		return
	#prints("bytes available:", mStream.get_available_bytes())
	var r = mStream.get_partial_data(mStream.get_available_bytes())
	var error = r[0]
	var data = r[1]
	if error:
		mVrcHostApi.log_debug(self, ["_receive_data() ERROR:", error])
		return
	mReceiveBuffer.append_array(data)

func initialize(vrc_host, vrc_host_api, stream):
	mVrcHost = vrc_host
	mVrcHostApi = vrc_host_api
	mStream = stream
	mRemoteAddress = get_remote_address()
	mRemotePort = get_remote_port()
	set_name(get_remote_address_string())

func get_remote_address():
	return mStream.get_connected_host()

func get_remote_port():
	return mStream.get_connected_port()

func get_remote_address_string():
	return "tcp!"+mRemoteAddress+"!"+str(mRemotePort)

func send_data(data):
	mSendBuffer.append_array(data)
