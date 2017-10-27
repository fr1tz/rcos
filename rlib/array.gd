
func join_array(array, spacer = ""):
	var ret = ""
	for i in range(0, array.size()):
		ret = ret + str(array[i])
		if i < array.size()-1:
			ret = ret + spacer
	return ret

func join_array_tree(array, fsl, ef = false, depth = 0):
	var s = ""
	var fs
	if depth < fsl.size():
		fs = fsl[depth]
	else:
		fs = fsl.back()
	for i in range(0, array.size()):
		var e = array[i]
		if typeof(e) == TYPE_ARRAY:
			s += join_array_tree(e, fsl, ef, depth+1)
		elif typeof(e) == TYPE_STRING:
			if ef:
				e = e.xml_escape()
			s += e
		else:
			continue
		if i < array.size()-1:
			s += fs
	return s
