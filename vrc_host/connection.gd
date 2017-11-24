extends Node

var mVrcHost = null
var mVrcHostApi = null
var mStream = null
var mRemoteAddress = ""
var mRemotePort = -1
var mReceiveBuffer = ""
var mSendBuffer = RawArray()
var mOpenVariables = {}
var mLastCommandError = ""
var mCommands = {
	"add_module": funcref(self, "_cmd_add_module"),
	"add_vrc": funcref(self, "_cmd_add_vrc"),
	"log_debug": funcref(self, "_cmd_log_debug"),
	"log_notice": funcref(self, "_cmd_log_notice"),
	"log_error": funcref(self, "_cmd_log_error"),
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
	if mReceiveBuffer.length() == 0:
		return
	var max_messages = 10
	for i in range(0, max_messages):
		var nlpos = mReceiveBuffer.find("\n")
		if nlpos >= 0:
			var msg = mReceiveBuffer.left(nlpos).strip_edges()
			mReceiveBuffer = mReceiveBuffer.right(nlpos+1)
			_process_vhcp_msg(msg)
		else:
			break

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
	mReceiveBuffer += data.get_string_from_utf8()

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
