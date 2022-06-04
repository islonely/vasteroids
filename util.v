module main

import arrays
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
fn angle_to_velocity(angle f32, max_speed f32) (f32, f32) {
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
	sw        time.StopWatch = time.new_stopwatch()
	last_time i64
	last_fps  []int = []int{len: 100}
	delta     f32
}

// update calculates the delta time and ads the current fps to a buffer.
fn (mut d Delta) update() {
	// time.sleep(time.millisecond * 30)
	elapsed := d.sw.elapsed().microseconds()
	d.delta = f32(elapsed - d.last_time) / 10000.0
	fps := 1000000.0 / f64(elapsed - d.last_time)
	d.last_fps.delete(0)
	d.last_fps << int(math.round(fps))
	d.last_time = elapsed
}

// fps returns the average of the fps buffer
[inline]
fn (d Delta) fps() int {
	return (arrays.sum(d.last_fps) or { 0 }) / d.last_fps.len
}
