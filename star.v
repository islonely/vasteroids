module main

import gg
import rand

// Star is just an image of a star used as a decoration.
[heap]
struct Star {
	img &gg.Image
mut:
	pos   Pos
	angle f32
}

// new_star instantiates a Star
fn new_star(mut gg gg.Context, i int) Star {
	img := gg.get_cached_image_by_idx(i)
	x := rand.u32n(u32(win_width - img.width)) or {
		println('Fatal Error: $err.msg()')
		(-100)
	}
	y := rand.u32n(u32(win_height - img.height)) or {
		println('Fatal Error: $err.msg()')
		(-100)
	}
	return Star{
		img: img
		pos: Pos{
			x: x
			y: y
		}
	}
}
