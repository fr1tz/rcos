#
# Base64 encoding / decoding 
#
# Adapted from http://web.mit.edu/freebsd/head/contrib/wpa/src/utils/base64.c
#
# Original copyright notice:
#
#   /*
#    * Base64 encoding/decoding (RFC1341)
#    * Copyright (c) 2005-2011, Jouni Malinen <j@w1.fi>
#    *
#    * This software may be distributed under the terms of the BSD license.
#    * See README for more details.
#    */
#

const base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

func base64_decode(input_string):
	var base64_table = base64_chars.to_ascii()
	var src = input_string.to_ascii()
	var len = src.size()
	var out = RawArray()
	var block = RawArray()
	var dtable = RawArray()
	var olen
	var pos
	var pad
	dtable.resize(256)
	for i in range(0, 256):
		dtable[i] = 0x80
	for i in range(0, base64_table.size()):
		dtable[base64_table[i]] = i
	dtable["=".to_ascii()[0]] = 0
	var count = 0
	for i in range(0, len):
		if dtable[src[i]] != 0x80:
			count += 1
	if count == 0 || count % 4 != 0:
		return RawArray([""])
	olen = count / 4 * 3
	out.resize(olen)
	block.resize(4)
	pos = 0
	pad = 0
	count = 0
	for i in range(0, len):
		var tmp = dtable[src[i]]
		if tmp == 0x80:
			continue
		if input_string[i] == "=":
			pad += 1
		block[count] = tmp
		count += 1
		if count == 4:
			out[pos] = (block[0] << 2) | (block[1] >> 4); pos += 1
			out[pos] = (block[1] << 4) | (block[2] >> 2); pos += 1
			out[pos] = (block[2] << 6) | block[3]; pos += 1
			count = 0
			if pad > 0:
				if pad == 1:
					pos -= 1
				elif pad == 2:
					pos -= 2
				else:
					# Invalid padding
					return null
				break
	return out
