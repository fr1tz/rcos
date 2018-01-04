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
var mCurrentDatablockSize = 0
var mCurrentDatablockData = null;
var mOpenVariables = {}
var mLastCommandError = ""
var mCommands = {
	"add_module": funcref(self, "_cmd_add_module"),
	"add_vrc": funcref(self, "_cmd_add_vrc"),
	"log_debug": funcref(self, "_cmd_log_debug"),
	"log_notice": funcref(self, "_cmd_log_notice"),
	"log_error": funcref(self, "_cmd_log_error"),
	"receive_datablock": funcref(self, "_cmd_receive_datablock"),
	"remove_vrc": funcref(self, "_cmd_remove_vrc"),
	"set_var": funcref(self, "_cmd_set_var"),
	"show_vrc": funcref(self, "_cmd_show_vrc"),
	"vclose": funcref(self, "_cmd_vclose"),
	"vopen": funcref(self, "_cmd_vopen"),
	"vwrite": funcref(self, "_cmd_vwrite")
}

func _cmd_add_module(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: VAR_NAME"
	elif cmdline.arguments.size() > 1:
		return "got more than 1 arguments"
	var var_name = cmdline.arguments[0]
	return mVrcHostApi.add_module(var_name)

func _cmd_add_vrc(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: VAR_NAME, VRC_VALUE"
	elif cmdline.arguments.size() == 1:
		return "missing argument: VRC_NAME"
	elif cmdline.arguments.size() > 2:
		return "got more than 2 arguments"
	var var_name = cmdline.arguments[0]
	var vrc_name = cmdline.arguments[1]
	return mVrcHostApi.add_vrc(var_name, vrc_name)

func _cmd_log_debug(cmdline):
	var msg = cmdline.arguments_raw
	return mVrcHostApi.log_debug(self, msg)

func _cmd_log_notice(cmdline):
	var msg = cmdline.arguments_raw
	return mVrcHostApi.log_notice(self, msg)

func _cmd_log_error(cmdline):
	var msg = cmdline.arguments_raw
	return mVrcHostApi.log_error(self, msg)

func _cmd_receive_datablock(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: DATABLOCK_NAME, DATABLOCK_SIZE"
	elif cmdline.arguments.size() == 1:
		return "missing argument: DATABLOCK_SIZE"
	elif cmdline.arguments.size() > 2:
		return "got more than 2 arguments"
# TODO:
#	var from = source.get_remote_address_string()
#	if cmdline.attributes.has("from"):
#		from = cmdline.attributes["from"]
	var datablock_name = cmdline.arguments[0]
	var datablock_size = int(cmdline.arguments[1])
	mCurrentDatablockName = datablock_name;
	mCurrentDatablockSize = datablock_size;
	mCurrentDatablockData = RawArray();
	return ""

func _cmd_remove_vrc(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing argument: VRC_NAME"
	elif cmdline.arguments.size() > 1:
		return "got more than 1 argument"
	var vrc_name = cmdline.arguments[0]
	return mVrcHostApi.remove_vrc(vrc_name)

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

func _cmd_show_vrc(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing argument: VRC_NAME"
	elif cmdline.arguments.size() > 1:
		return "got more than 1 argument"
	var fullscreen = false
	if cmdline.attributes.has("fullscreen"):
		fullscreen = true
	var name = cmdline.arguments[0]
	return mVrcHostApi.show_vrc(name, fullscreen)

func _cmd_vclose(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: VAR_NAME"
	elif cmdline.arguments.size() > 1:
		return "got more than 1 argument"
	var var_name = cmdline.arguments[0]
	if !mOpenVariables.has(var_name):
		return "no such open variable"
	var var_value = mOpenVariables[var_name]
	mOpenVariables.erase(var_name)
	return mVrcHostApi.set_var(var_name, var_value)

func _cmd_vopen(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: VAR_NAME"
	elif cmdline.arguments.size() > 1:
		return "got more than 1 argument"
	var var_name = cmdline.arguments[0]
	mOpenVariables[var_name] = ""
	return ""
	
func _cmd_vwrite(cmdline):
	if cmdline.arguments.size() == 0:
		return "missing arguments: VAR_NAME, DATA"
	elif cmdline.arguments.size() == 1:
		return "missing argument: DATA"
	elif cmdline.arguments.size() > 2:
		return "got more than 2 arguments"
	var var_name = cmdline.arguments[0]
	var data = cmdline.arguments[1]
	if !mOpenVariables.has(var_name):
		return "no such open variable"
	mOpenVariables[var_name] += data
	return ""

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
		if mCurrentDatablockSize == 0: # Reading VHCP messages
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
		else: # Reading datablock data
			if mCurrentDatablockSize >= mReceiveBuffer.size():
				mCurrentDatablockData.append_array(mReceiveBuffer)
				mCurrentDatablockSize -= mReceiveBuffer.size()
				mReceiveBuffer.resize(0)
			else:
				var nbytes = mCurrentDatablockSize
				var datablock_data = RawArray(mReceiveBuffer)
				datablock_data.resize(mCurrentDatablockSize)
				mCurrentDatablockData.append_array(datablock_data)
				mReceiveBuffer.invert()
				mReceiveBuffer.resize(mReceiveBuffer.size()-mCurrentDatablockSize)
				mReceiveBuffer.invert()
				mCurrentDatablockSize = 0
			if mCurrentDatablockSize == 0:
				mVrcHostApi.set_datablock(mCurrentDatablockName, mCurrentDatablockData)

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
