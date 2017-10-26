
func parse_cmdline(args):
	var cmdline = {
		"raw": args,
		"command": "",
		"attributes": {},
		"arguments": [],
		"arguments_raw": ""
	}
	cmdline.command = rlib.hd(args)
	if cmdline.command == "":
		return null
	args = rlib.tl(args)
	while(rlib.hd(args).begins_with("--")):
		var s = rlib.hd(args)
		if s == "--":
			args = rlib.tl(args)
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
		args = rlib.tl(args)
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
			cmdline.arguments.append(rlib.hd(args))
			args = rlib.tl(args)
	return cmdline
