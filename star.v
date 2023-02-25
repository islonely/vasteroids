module main

import gg
import rand

// Star is just an image of a star used as a decoration.
[heap]
struct Star {
	img &gg.Image = unsafe { nil }
mut:
	pos   Pos
	angle f32
	scale f32 = 1.0
}

// new_star instantiates a Star
fn new_star(mut g gg.Context, i int) Star {
	img := g.get_cached_image_by_idx(i)
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
