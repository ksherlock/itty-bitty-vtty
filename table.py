

import sys


special = {
}
for x in range(0,0x20): special[chr(x)] = '^' + chr(0x40 + x)

cmap = {
	'\'': '\'',
	'\"': '\"',
	'?': '?',
	'\\': '\\',
	'a': '\a',
	'b': '\b',
	'f': '\f',
	'n': '\n',
	'r': '\r',
	't': '\t',
	'v': '\v',
}



argv = sys.argv[1:]

chars = []
for arg in argv:
	# ^X is a control character
	if len(arg) == 2 and arg[0] == '^':
		c = chr(ord(arg[1]) & 0x1f)
		chars.append(c)
		continue
	# \X is an escaped character
	if len(arg) == 2 and arg[0] == '\\':
		c = arg[1]
		if c in cmap: chars.append(cmap[c])
		continue

	# X-Y is a range of characters.
	if len(arg) == 4 and arg[1] == '-':
		a = arg[0]
		b = arg[2]
		for c in range(ord(a),ord(b)+1):
			chars.append(chr(c))
		continue

	chars.extend(arg)

chars = list(set(chars))
chars.sort()

if not chars: exit(1)

mmin = ord(chars[0])
mmax = ord(chars[-1])

print(":MIN\tequ {}".format(mmin))
print(":MAX\tequ {}".format(mmax))
print()




print(":table")
for x in range(mmin, mmax+1):
	c = chr(x)
	print("\tdw $0\t; {}".format(special.get(c, c)))

# for c in chars:
# 	x = ord(c)
# 	print("\tdw $0\t; {}".format(special.get(c, c)))
