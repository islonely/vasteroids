module main

import math
import rand
import time

// Pos corresponds to a position on the screens.
struct Pos {
mut:
	x f32
	y f32
	// z f32
}

// Velocity is the direction something is move and the max
// speed that it can move.
struct Velocity {
mut:
	x    f32
	y    f32
	max  f32 = 1.2
	maxx f32 = 1.2
	maxy f32 = 1.2
}

// is_odd returns whether or not a given number is odd or even.
[inline]
fn is_odd(x int) int {
	// same as if x % 2 == 0 { -1 } else { 1 } but it's branchless.
	// I just found out about branchless programming
	// so I had to find a way to implement it
	return [-1, 1][x % 2]
}

// angle_to_velocity converts an angle (0-360 degrees) to the
// x, y velocity.
fn angle_to_velocity(angle int, max_speed f32) (f32, f32) {
	radians := f64(angle + 90) * (math.pi / 180.0)
	vel_x := math.cos(radians)
	vel_y := math.sin(radians)
	return f32(max_speed * vel_x), -f32(max_speed * vel_y)
}

// gen_pseudo_random_coords generates random X and Y coordinates in
// the provided range. Generated coordinates are prevent by being close
// to each other by separating the screen into block creating only one
// position per block.
fn gen_pseudo_random_coords(rangex int, rangey int) []Pos {
	mut coords := []Pos{}
	mut x, mut y := 0, 0
	mut ypos, mut xpos := 0, 0
	block_size := 150
	padding := 20
	for y < rangey {
		for x < rangex {
			xpos = rand.int_in_range(x + padding, x + block_size - padding) or {
				println('Failed to generate random int.')
				(-100)
			}
			ypos = rand.int_in_range(y + padding, y + block_size - padding) or {
				println('Failed to generate random int.')
				(-100)
			}
			coords << Pos{
				x: xpos
				y: ypos
			}
			x += block_size
		}
		y += block_size
		x = 0
	}
	return coords
}

// Delta is used to control delta time.
struct Delta {
mut:
	time1 time.Time = time.now()
	time2 time.Time = time.now()
}

// time calculates the delta time.
[inline]
fn (d Delta) time() f32 {
	return f32(d.time2.unix_time_milli() - d.time1.unix_time_milli()) / f32(10000000.0)
}
