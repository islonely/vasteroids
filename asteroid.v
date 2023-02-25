module main

import gg
import rand

// Asteroid is one of the object the player can collide with or fire
// their projectiles at.
[heap]
struct Asteroid {
	img  &gg.Image = unsafe { nil }
	size AsteroidSize
mut:
	pos   Pos
	vel   Velocity
	angle f32
	rotv  f32 = 2.0
	scale f32 = 1.0
}

// AsteroidSize is the size of the asteroid drawn. In the original
// game small asteroids move across the screen faster.
pub enum AsteroidSize {
	large = 1
	medium = 2
	small = 3
}

// new_asteroid instantiates a new Asteroid and sets it's velocity
// based on it's size
fn new_asteroid(mut g gg.Context, size AsteroidSize, i int) Asteroid {
	mut img := g.get_cached_image_by_idx(i)
	mut maxv := f32(0.5)
	mut minv := f32(-0.5)
	mut scale := f32(1.0)
	angle := rand.f32_in_range(0, 360) or { 0 }
	rotv := rand.f32_in_range(-3, 3) or { 2 }
	match size {
		.small {
			maxv *= 1.3
			minv *= 1.3
			scale = 1.5
		}
		.medium {
			maxv *= 1.15
			minv *= 1.15
			scale = 1.25
		}
		.large {}
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
		angle: angle
		rotv: rotv
		scale: scale
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
fn (mut a Asteroid) update(g &gg.Context, delta f32) {
	wrap_around_screen(mut a, g)

	a.pos.x += a.vel.x * delta
	a.pos.y += a.vel.y * delta
	a.angle += a.rotv * delta
}
