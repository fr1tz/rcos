# Copyright © 2017, 2018 Michael Goldener <mg@wasted.ch>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#-------------------------------------------------------------------------------
# VRC Host API
#-------------------------------------------------------------------------------

var mVrcHost = null
var mApiExtensions = {}
var mVhcpExtensions = {}

func _init(vrc_host):
	mVrcHost = vrc_host
	add_user_signal("new_log_entry3")
	add_user_signal("vrc_displayed")
	add_user_signal("vrc_concealed")
	add_user_signal("var_changed1")
	add_user_signal("var_changed2")
	add_user_signal("var_changed3")
	mVrcHost.connect("new_log_entry3", self, "_emit_new_log_entry3")
	mVrcHost.connect("vrc_displayed", self, "_emit_vrc_displayed")
	mVrcHost.connect("vrc_concealed", self, "_emit_vrc_concealed")
	mVrcHost.connect("var_changed1", self, "_emit_var_changed1")
	mVrcHost.connect("var_changed2", self, "_emit_var_changed2")
	mVrcHost.connect("var_changed3", self, "_emit_var_changed3")

func _emit_new_log_entry3(source_node, level, content):
	emit_signal("new_log_entry3", source_node, level, content)

func _emit_vrc_displayed(vrc):
	emit_signal("vrc_displayed", vrc)

func _emit_vrc_concealed(vrc):
	emit_signal("vrc_concealed", vrc)

func _emit_var_changed1(var_name):
	emit_signal("var_changed1", var_name)

func _emit_var_changed2(var_name, new_value):
	emit_signal("var_changed2", var_name, new_value)

func _emit_var_changed3(var_name, new_value, old_value):
	emit_signal("var_changed3", var_name, new_value, old_value)

#-------------------------------------------------------------------------------
# Core API
#-------------------------------------------------------------------------------

func load_vrc(vrc_data):
	return mVrcHost.load_vrc(vrc_data)

func add_vrc(datablock_name, instance_name):
	return mVrcHost.add_vrc(datablock_name, instance_name)

func call(method_name, arg0=null, arg1=null, arg2=null, arg3=null, arg4=null, arg5=null, arg6=null, arg7=null, arg8=null, arg9=null):
	mVrcHost.call(method_name, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)

func disable_canvas_input(node):
	rcos.disable_canvas_input(node)

func enable_canvas_input(node):
	rcos.enable_canvas_input(node)

func get_module(module_name):
	return mVrcHost.get_module(module_name)

func get_node_from_path(path_string):
	return mVrcHost.get_node_from_path(path_string)

func get_path_from_node(node):
	return mVrcHost.get_path_from_node(node)

func get_var(var_name):
	return mVrcHost.get_variable(var_name)

func get_var_list():
	return mVrcHost.get_variables()

func log_debug(source_node, content):
	return mVrcHost.add_log_entry(source_node, "debug", content)

func log_notice(source_node, content):
	return mVrcHost.add_log_entry(source_node, "notice", content)

func log_error(source_node, content):
	return mVrcHost.add_log_entry(source_node, "error", content)

func send(data, to, from = null):
	return mVrcHost.send(data, to, from)

func set_icon(image):
	return mVrcHost.set_icon(image)

func set_var(var_name, var_value):
	return mVrcHost.set_variable(var_name, var_value)

func show_region(rect, fullscreen = false):
	return mVrcHost.show_region(rect, fullscreen)

func update_vrc_download_progress(value):
	return mVrcHost.update_vrc_download_progress(value)

func add_widget_factory(product_id, product_name, object, create_widget_method):
	return mVrcHost.add_widget_factory(product_id, product_name, object, create_widget_method)

func remove_widget_factory(product_id):
	return mVrcHost.add_widget_factory(product_id)

#-------------------------------------------------------------------------------
# VHCP (VRC Host Control Protocol) Extensions
#-------------------------------------------------------------------------------

func add_vhcp_extension(command_name, object, method):
	if mVhcpExtensions.has(command_name):
		return "VHCP extension " + command_name + " already exists"
	mVhcpExtensions[command_name] = funcref(object, method)
	return ""

func has_vhcp_extension(command_name):
	return mVhcpExtensions.has(command_name)

func remove_vhcp_extension(command_name):
	if !mVhcpExtensions.has(command_name):
		return "VHCP extension " + command_name + " does not exist"
	mVhcpExtensions.erase(command_name)
	return ""

func call_vhcp_extension(command_name, cmdline, source):
	if !mVhcpExtensions.has(command_name):
		return "VHCP extension " + command_name + " does not exist"
	mVhcpExtensions[command_name].call_func(cmdline, source) 

func get_vhcp_extensions():
	var extensions = []
	for command_name in mVhcpExtensions:
		extensions.append(command_name)
	return extensions
