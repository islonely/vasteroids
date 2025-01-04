module main

import gg

// Projectile is the red laser that is shot when the user presses the fire button.
@[heap]
struct Projectile {
	img &gg.Image = unsafe { nil }
mut:
	pos   Pos
	vel   Velocity
	angle f32
	scale f32 = 1.0
}

// update changes the position of a Projectile based on the velocity property.
fn (mut p Projectile) update(mut app App) {
	p.pos.x += p.vel.x * app.delta.delta
	p.pos.y += p.vel.y * app.delta.delta

	for i, a in app.asteroids {
		if p.pos.x >= a.pos.x && p.pos.x <= (a.pos.x + (a.img.width * a.scale))
			&& p.pos.y >= a.pos.y && p.pos.y <= (a.pos.y + (a.img.width * a.scale)) {
			app.asteroids_hit++
			app.break_asteroid(i)
			p.pos.x = -100
			p.pos.y = -100
			p.vel.x = 0
			p.vel.y = 0
			app.score += match a.size {
				.large { 20 }
				.medium { 50 }
				.small { 100 }
			}
		}
	}
}
