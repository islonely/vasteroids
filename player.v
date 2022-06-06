module main

import gg
import math
import rand

// Player is the object which the player controls
struct Player {
	img &gg.Image
mut:
	pos            Pos
	vel            Velocity
	angle          f32
	rotation_speed f32 = 2.0
	acceleration   f32 = 0.0085
	deceleration   f32 = 0.993
}

// draw handles rendering the player to the screen
fn (mut p Player) draw(g &gg.Context) {
	g.draw_image_with_config(
		rotate: int(p.angle)
		img: p.img
		img_rect: gg.Rect{
			x: p.pos.x
			y: p.pos.y
			width: p.img.width / g.scale
			height: p.img.height / g.scale
		}
	)
}

// update handles the physics/logic of the player
fn (mut p Player) update(gg &gg.Context, delta f32) {
	wrap_around_screen(mut p, gg)

	if p.vel.x != 0 {
		p.vel.x = p.vel.x * f32(math.pow(p.deceleration, delta))
	}

	if p.vel.y != 0 {
		p.vel.y = p.vel.y * f32(math.pow(p.deceleration, delta))
	}

	p.pos.x += p.vel.x * delta
	p.pos.y += p.vel.y * delta
}

// center places the character in the center of the window
fn (mut p Player) center(gg &gg.Context) {
	x := (gg.width / 2) - (p.img.width / 2)
	y := (gg.height / 2) - (p.img.height / 2)
	p.pos.x = x
	p.pos.y = y
}

// teleport moves the player to a random location on the window
fn (mut p Player) teleport(gg &gg.Context) {
	mut padding := u32(25)
	p.pos.x = rand.u32_in_range(padding, u32(gg.width - p.img.width) - padding) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	p.pos.y = rand.u32_in_range(padding, u32(gg.height - p.img.height) - padding) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	p.vel.x = 0
	p.vel.y = 0
}
