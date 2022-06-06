include "../bootloader/framebuffer.fy"
include "../bootloader/psf.fy"

struct Display {
	framebuffer: Framebuffer,
	font: PSF2_Font,
	x: uint,
	y: uint,
	color: RGBAColor,
}

inline fun(Display) width() this.framebuffer.width
inline fun(Display) height() this.framebuffer.height

fun(*Display) put_char(char: char) {
	if(char == '\n') {
		this.y += this.font.header.height
		this.x = 0
	} else if(char == '\r') {
		this.x = 0
	} else {
		let font_ptr = this.font.glyph(char)
		const glyph_height = this.font.header.height
		const glyph_width = this.font.header.width
		const glyph_byte_width = (glyph_width + 7) / 8
		for(let y = 0; y < glyph_height; y += 1) {
			const glyph_row = glyph_byte_width * y
			for(let x = 0; x < glyph_width; x += 1) {
				const glyph_byte = font_ptr[glyph_row + x / 8]
				const glyph_bit = glyph_byte & (0b10000000 >> (x % 8))
				if(glyph_bit) {
					this.framebuffer.set_pixel(this.x + x, this.y + y, this.color)
				}
			}
		}
		this.x += this.font.header.width
	}
	if(this.x >= this.framebuffer.width) {
		this.x = 0
		this.y += this.font.header.height
	}
	if(this.y >= this.framebuffer.height) {
		this.y = this.framebuffer.height - this.font.header.height
		this.framebuffer.move_up(this.font.header.height)
	}
	null
}

fun(*Display) put_strr(begin: *char, end: *char)
	for(let chr = begin; chr < end; chr += 1)
		this.put_char(*chr)

fun(*Display) put_cstr(begin: *char) {
	let chr = begin
	while(*chr != '\0') {
		this.put_char(*chr)
		chr += 1
	}
	null
}

fun(*Display) put_strl(str: *char, len: uint_ptrsize)
	this.put_strr(str, str + len)

fun uint64tostr(num: uint64, buffer: *char[20]): *char {
	let begin = (buffer as *char) + 20
	let n = num
	while(n != 0) {
		begin -= 1
		begin[0] = (n % 10) + '0'
		n /= 10 null
	} else {
		begin -= 1
		begin[0] = '0' null
	}
	begin
}

fun(*Display) print_uint64(num: uint64) {
	// len(str(2**64)) == 20, allocate max uint64 length
	let buffer: char[20]
	const end = &buffer[20]
	const begin = uint64tostr(num, &buffer)
	this.put_strr(begin, end)
}

inline fun(*Display) print(val: char[generic Len] | *char[generic Len] | uint64 | char | *char)
	if(typeof(val) == char[generic Len]) {
		let p = val
		this.put_strl(&p, Len)
	} else if(typeof(val) == *char[generic Len])
		this.put_strl(val, Len)
	else if(typeof(val) == uint64)
		this.print_uint64(val)
	else if(typeof(val) == *uint8)
		this.put_cstr(val)
	else if(typeof(val) == char)
		this.put_char(val)

fun uint64tohex(num: uint64, buffer: *char[10]) {
	const buf: *char = buffer
	let n: uint64 = num
	buf[0] = '0'
	buf[1] = 'x'
	for (let i = 0; i < 8; i += 1) {
		const c = (n & 0xf) + '0'
		buf[9 - i] = if (c > '9') c - '9' + 'a' - 1 else c
		n = n >> 4
	}
	null
}

fun(*Display) print_hex(num: uint64) {
	let buffer: char[10]
	uint64tohex(num, &buffer)
	this.print(&buffer)
}
