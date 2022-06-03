module main

import gg
import rand

// Player is the object which the player controls
struct Player {
	img gg.Image
mut:
	pos   Pos
	vel   Velocity
	angle int
}

// draw handles rendering the player to the screen
fn (mut p Player) draw(g &gg.Context) {
	g.draw_image_with_config(
		rotate: int(p.angle)
		img: &p.img
		img_rect: gg.Rect{
			x: p.pos.x
			y: p.pos.y
			width: p.img.width * g.scale
			height: p.img.height * g.scale
		}
	)

	// gg.draw_image(p.pos.x, p.pos.y, p.img.width, p.img.height, p.img)
}

// update handles the physics/logic of the player
fn (mut p Player) update(gg &gg.Context) {
	wrap_around_screen(mut p, gg)

	if p.vel.x != 0 {
		p.vel.x *= 0.993
	}

	if p.vel.y != 0 {
		p.vel.y *= 0.993
	}

	p.pos.x += p.vel.x
	p.pos.y += p.vel.y

	// p.angle = f32(math.sin(time.now().unix_time())) * 50
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
