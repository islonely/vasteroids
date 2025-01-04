module main

import gg
import gx
import math
import rand

// Player is the object which the player controls
struct Player {
	img &gg.Image = unsafe { nil }
mut:
	pos            Pos
	vel            Velocity
	angle          f32
	scale          f32 = 1.0
	rotation_speed f32 = 2.0
	acceleration   f32 = 0.009
	deceleration   f32 = 0.997
}

// draw handles rendering the player to the screen
fn (mut p Player) draw(g &gg.Context) {
	g.draw_image_with_config(
		rotation: int(p.angle)
		img:      p.img
		img_rect: gg.Rect{
			x:      p.pos.x
			y:      p.pos.y
			width:  p.img.width / g.scale
			height: p.img.height / g.scale
		}
	)

	// hitbox and x,y position of player
	$if debug {
		g.draw_rect_empty(p.pos.x, p.pos.y, p.img.width * p.scale, p.img.height * p.scale,
			gx.green)
		g.draw_circle_filled(p.pos.x, p.pos.y, 2, gx.red)
	}
}

// update handles the physics/logic of the player
fn (mut p Player) update(mut app App) {
	wrap_around_screen(mut p, app.gg)

	if p.vel.x != 0 {
		p.vel.x = p.vel.x * f32(math.pow(p.deceleration, app.delta.delta))
	}

	if p.vel.y != 0 {
		p.vel.y = p.vel.y * f32(math.pow(p.deceleration, app.delta.delta))
	}

	p.pos.x += p.vel.x * app.delta.delta
	p.pos.y += p.vel.y * app.delta.delta

	for i, a in app.asteroids {
		if p.pos.x >= (a.pos.x - (p.img.width * p.scale))
			&& p.pos.x <= (a.pos.x + (a.img.width * a.scale))
			&& p.pos.y >= (a.pos.y - (p.img.height * p.scale))
			&& p.pos.y <= (a.pos.y + (a.img.width * a.scale)) {
			app.break_asteroid(i)
			app.state = .game_over
		}
	}
}

// center places the character in the center of the window
fn (mut p Player) center(g &gg.Context) {
	x := (g.width / 2) - (p.img.width / 2)
	y := (g.height / 2) - (p.img.height / 2)
	p.pos.x = x
	p.pos.y = y
}

// teleport moves the player to a random location on the window
fn (mut p Player) teleport(g &gg.Context) {
	mut padding := u32(25)
	p.pos.x = rand.u32_in_range(padding, u32(g.width - p.img.width) - padding) or {
		println('Fatal Error: ${err.msg()}')
		exit(0)
	}
	p.pos.y = rand.u32_in_range(padding, u32(g.height - p.img.height) - padding) or {
		println('Fatal Error: ${err.msg()}')
		exit(0)
	}
	p.vel.x = 0
	p.vel.y = 0
}
