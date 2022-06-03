module main

import gg
import rand

// Asteroid is one of the object the player can collide with or fire
// their projectiles at.
struct Asteroid {
	img  gg.Image
	size AsteroidSize
mut:
	pos   Pos
	vel   Velocity
	angle int
}

// AsteroidSize is the size of the asterdroid drawn. In the original
// game small asteroids move across the screen faster.
pub enum AsteroidSize {
	large = 1
	medium = 2
	small = 3
}

// new_asteroid instantiates a new Asteroid and sets it's velocity
// based on it's size
fn new_asteroid(mut gg gg.Context, size AsteroidSize) Asteroid {
	mut img := gg.create_image_from_byte_array([]byte{})
	mut maxv := f32(0.25)
	mut minv := f32(0.1)
	match size {
		.small {
			img = gg.create_image_from_byte_array(sm_asteroid.to_bytes())
			maxv *= 1.3
			minv *= 1.3
		}
		.medium {
			img = gg.create_image_from_byte_array(md_asteroid.to_bytes())
			maxv *= 1.15
			minv *= 1.15
		}
		.large {
			img = gg.create_image_from_byte_array(lg_asteroid.to_bytes())
		}
	}

	x := rand.u32n(u32(win_width - img.width)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	y := rand.u32n(u32(win_height - img.height)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	mut xv := rand.f32_in_range(minv, maxv) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	xv *= is_odd(rand.int_in_range(0, 2) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	})
	mut yv := rand.f32_in_range(minv, maxv) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	yv *= is_odd(rand.int_in_range(0, 2) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	})
	return Asteroid{
		img: img
		pos: Pos{
			x: x
			y: y
		}
		size: size
		vel: Velocity{
			x: xv + (int(size) * xv / 3)
			y: yv + (int(size) * yv / 3)
			max: maxv
		}
	}
}

// update handles the physics/logic for asteroids
fn (mut a Asteroid) update(gg &gg.Context) {
	wrap_around_screen(mut a, gg)

	a.pos.x += a.vel.x
	a.pos.y += a.vel.y
}
