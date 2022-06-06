module main

import gg

// Projectile is the red laser that is shot when the user presses the fire button.
[heap]
struct Projectile {
	img &gg.Image
mut:
	pos   Pos
	vel   Velocity
	angle f32
}

// update changes the position of a Projectile based on the velocity property.
fn (mut p Projectile) update(delta f32) {
	p.pos.x += p.vel.x * delta
	p.pos.y += p.vel.y * delta
}
