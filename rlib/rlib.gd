extends Node

var _array = preload("array.gd").new()
var _net = preload("net.gd").new()
var _string = preload("string.gd").new()
var _base64 = preload("base64.gd").new()
var _cmdline = preload("cmdline.gd").new()

func join_array(array, spacer = ""):
	return _array.join_array(array, spacer)

func join_array_tree(array, fsl, depth = 0):
	return _array.join_array_tree(array, fsl, depth)

func ws(char):
	# *** Returns whether char is whitespace
	return _string.ws(char)

func hd(string):
	# *** Return first word in string
	return _string.hd(string)

func tl(string): 
	# *** Return remains of string starting with 2nd word
	return _string.tl(string)
	
func parse_cmdline(string):
	return _cmdline.parse_cmdline(string)
	
func base64_decode(input_string):
	return _base64.base64_decode(input_string)
