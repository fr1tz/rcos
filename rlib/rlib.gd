extends Node

const PORT_TYPE_TCP = 0
const PORT_TYPE_UDP = 1

var mNextPort = {
	PORT_TYPE_TCP: 22000,
	PORT_TYPE_UDP: 22000
}

func join_array(array, spacer = ""):
	var ret = ""
	for i in range(0, array.size()):
		ret = ret + str(array[i])
		if i < array.size()-1:
			ret = ret + spacer
	return ret

func join_array_tree(array, fsl, depth = 0):
	var s = ""
	var fs = " "
	if depth < fsl.size():
		fs = " " + fsl[depth] + " "
	for i in range(0, array.size()):
		var e = array[i]
		if typeof(e) == TYPE_ARRAY:
			s += join_array_tree(e, fsl, depth+1)
		elif typeof(e) == TYPE_STRING:
			s += e
		else:
			continue
		if i < array.size()-1:
			s += fs
	return s

func listen(object, port_type):
	if !mNextPort.has(port_type):
		error("[rlib] listen(): Invalid port type: ", port_type)
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
	# *** Returns whether char is whitespace
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

func parse_cmdline(args):
	var cmdline = {
		"raw": args,
		"command": "",
		"attributes": {},
		"arguments": [],
		"arguments_raw": ""
	}
	cmdline.command = hd(args)
	if cmdline.command == "":
		return null
	args = tl(args)
	while(hd(args).begins_with("--")):
		var s = hd(args)
		if s == "--":
			args = tl(args)
			break
		s = s.right(2)
		var idx = s.find("=")
		if idx == -1:
			var name = s
			var value = ""
			cmdline.attributes[name] = value
		else:
			var name = s.left(idx)
			var value = s.right(idx+1)
			cmdline.attributes[name] = value
		args = tl(args)
	cmdline.arguments_raw = args
	var quotes = "\""
	var backslash = "\\"
	while(args != ""):
		if args.begins_with(quotes):
			var opening_quotes_idx = 0
			var closing_quotes_idx = args.find(quotes, opening_quotes_idx+1)
			while closing_quotes_idx != -1:
				if args[closing_quotes_idx-1] != backslash:
					break
				closing_quotes_idx = args.find(quotes, closing_quotes_idx+1)
			if closing_quotes_idx == -1:
				return null
			var arg_start_idx = opening_quotes_idx+1
			var arg_end_idx = closing_quotes_idx-1
			var arg_length = arg_end_idx - arg_start_idx + 1
			var arg = args.substr(arg_start_idx, arg_length)
			arg = arg.replace(backslash+quotes, quotes)
			cmdline.arguments.append(arg)
			args = args.right(closing_quotes_idx+1)
			while args.begins_with(" "):
				args.erase(0, 1)
		else:
			cmdline.arguments.append(hd(args))
			args = tl(args)
	return cmdline
