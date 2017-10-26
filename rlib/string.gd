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
			if !rlib.ws(c):
				start = i
				find_start = false
		elif rlib.ws(c):
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
	if rlib.ws(string[start]):
		for i in range(start, len):
			var c = string[i]
			if i == len-1:
				return ""
			elif !rlib.ws(c):
				start = i
				break
	# Find end of first word
	for i in range(start, len):
		var c = string[i]
		if i == len-1:
			return ""
		elif rlib.ws(c):
			start = i
			break
	# Find beginning of second word
	for i in range(start, len):
		var c = string[i]
		if !rlib.ws(c):
			return string.right(i)
		elif i == len-1:
			return ""
	return ""