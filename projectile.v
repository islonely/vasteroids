module main

import gg

// Projectile is the red laser that is shot when the user presses the fire button.
[heap]
struct Projectile {
	img gg.Image
mut:
	pos   Pos
	vel   Velocity
	angle f32
}

// new_projectile instantiates Projectile and places it at the players position.
fn new_projectile(mut gg gg.Context, player &Player) Projectile {
	img := gg.create_image_from_byte_array(laser.to_bytes())
	return Projectile{
		img: img
		pos: Pos{
			x: -100
			y: -100
		}
		vel: Velocity{
			max: 6
		}
	}
}

// update changes the position of a Projectile based on the velocity property.
fn (mut p Projectile) update(delta f32) {
	p.pos.x += p.vel.x * delta
	p.pos.y += p.vel.y * delta
}
