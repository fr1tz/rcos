extends Node

const PORT_TYPE_TCP = 0
const PORT_TYPE_UDP = 1

var mNextPort = {
	PORT_TYPE_TCP: 22000,
	PORT_TYPE_UDP: 22000
}

func listen(object, port_type):
	if !mNextPort.has(port_type):
		error("[rlib. listen(): Invalid port type: ", str(port_type))
		return -1
	var port_begin = mNextPort[port_type]
	var port_end = 49151
	for port in range(port_begin, port_end+1):
		var error = object.listen(port)
		if error == 0:
			mNextPort[port_type] = port+1
			return port
	return -2

func ws(char):
	# *** Returns whether character is whitespace
	if char == " " || char == "\t":
		return true
	return false

func hd(string):
	# *** Return first word in string
	if string == null || string.empty():
		return ""
	var len = string.length()
	var start = 0
	var find_start = true
	for i in range(0, len):
		var c = string[i]
		if find_start:
			if !ws(c):
				start = i
				find_start = false
		elif ws(c):
			return string.substr(start, i-start)
	if find_start == false:
		return string.right(start)
	return ""

func tl(string): 
	# *** Return remains of string starting with 2nd word
	if string == null || string.empty():
		return ""
	var len = string.length()
	var start = 0
	# Find beginning of first word
	if ws(string[start]):
		for i in range(start, len):
			var c = string[i]
			if i == len-1:
				return ""
			elif !ws(c):
				start = i
				break
	# Find end of first word
	for i in range(start, len):
		var c = string[i]
		if i == len-1:
			return ""
		elif ws(c):
			start = i
			break
	# Find beginning of second word
	for i in range(start, len):
		var c = string[i]
		if !ws(c):
			return string.right(i)
		elif i == len-1:
			return ""
	return ""
