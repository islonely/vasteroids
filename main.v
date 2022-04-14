/*
*	NOTE: Some implementations of things may seem awkward.
 * 		  This is both because I'm dumb and gg.Context has
 *		  no way to implement new images after it is running. (I think)
 *
 *	This will probably be on hold until V0.3 is released. As far as I'm
 * 	aware there is no way to rotate images in
*/
import gg
import gx
import math
import time
import rand

const (
	win_title   = 'Game'
	win_width   = 600
	win_height  = 600
	win_bgcolor = gx.Color{
		r: 20
		g: 20
		b: 20
	}
)

const (
	sm_asteroid = $embed_file('img/sm_asteroid.png')
	md_asteroid = $embed_file('img/md_asteroid.png')
	lg_asteroid = $embed_file('img/lg_asteroid.png')
	star        = $embed_file('img/star.png')
	laser       = $embed_file('img/laser.png')
	player_img  = $embed_file('img/player.png')
)

struct App {
mut:
	gg               &gg.Context
	player           Player
	asteroids        []Asteroid
	projectiles      []Projectile
	projectile_index int
	max_projectiles  int = 10
	stars            []&Star
	bgcolor          gx.Color     = gx.white
	keys_down        map[int]bool = {
		262: false // right
		263: false // left
		264: false // down
		265: false // up
		32:  false // spacebar
		88:  false // x
		90:  false // z
	}
}

interface RenderableObject {
	img gg.Image
mut:
	pos Pos
}

struct Projectile {
	img gg.Image
mut:
	pos Pos
	vel Velocity
}

fn new_projectile(mut gg gg.Context, player &Player) Projectile {
	img := gg.create_image_from_byte_array(laser.to_bytes())
	maxv := f32(6)
	return Projectile{
		img: img
		pos: Pos{
			x: -100
			y: -100
		}
		vel: Velocity{
			max: maxv
		}
	}
}

fn (mut p Projectile) update() {
	p.pos.y -= p.vel.max
}

[heap]
struct Star {
	img gg.Image
mut:
	pos Pos
}

fn new_star(mut gg gg.Context) &Star {
	img := gg.create_image_from_byte_array(star.to_bytes())
	x := rand.u32n(u32(win_width - img.width)) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	y := rand.u32n(u32(win_height - img.height)) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	return &Star{
		img: img
		pos: Pos{
			x: x
			y: y
		}
	}
}

struct Asteroid {
	img  gg.Image
	size AsteroidSize
mut:
	pos Pos
	vel Velocity
}

pub enum AsteroidSize {
	large = 1
	medium = 2
	small = 3
}

[inline]
fn is_odd(x int) int {
	// same as if x % 2 == 0 { -1 } else { 1 } but it's branchless.
	// Probably saves like one instruction per clock.
	// I just found out about branchless programming
	// so I had to find a way to implement it
	return [-1, 1][x % 2]
}

fn new_asteroid(mut gg gg.Context, size AsteroidSize) Asteroid {
	mut img := gg.create_image_from_byte_array([]byte{})
	match size {
		.small { img = gg.create_image_from_byte_array(sm_asteroid.to_bytes()) }
		.medium { img = gg.create_image_from_byte_array(md_asteroid.to_bytes()) }
		.large { img = gg.create_image_from_byte_array(lg_asteroid.to_bytes()) }
	}


	x := rand.u32n(u32(win_width - img.width)) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	y := rand.u32n(u32(win_height - img.height)) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	maxv := f32(0.25)
	minv := f32(0.1)
	mut xv := rand.f32_in_range(minv, maxv) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	xv *= is_odd(rand.int_in_range(0, 2) or {
		println('Fatal Error: $err.msg')
		exit(0)
	})
	mut yv := rand.f32_in_range(minv, maxv) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	yv *= is_odd(rand.int_in_range(0, 2) or {
		println('Fatal Error: $err.msg')
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

// this is how you would draw almost any image, so let's create one function
// instead of a draw function for each struct we have
fn draw_renderable_object(ro &RenderableObject, gg &gg.Context) {
	gg.draw_image(ro.pos.x, ro.pos.y, ro.img.width, ro.img.height, ro.img)
}

[inline]
fn wrap_around_screen(mut ro RenderableObject, gg &gg.Context) {
	if ro.pos.x > gg.width {
		ro.pos.x = -ro.img.width
	}
	if ro.pos.x < -ro.img.width {
		ro.pos.x = gg.width
	}
	if ro.pos.y > gg.height {
		ro.pos.y = -ro.img.height
	}
	if ro.pos.y < -ro.img.height {
		ro.pos.y = gg.height
	}
}

fn (mut a Asteroid) update(gg &gg.Context) {
	wrap_around_screen(mut a, gg)

	a.pos.x += a.vel.x
	a.pos.y += a.vel.y
}

struct Player {
	img gg.Image
mut:
	pos   Pos
	vel   Velocity
	angle f32
}

fn (mut p Player) draw(gg &gg.Context) {
	gg.draw_image(p.pos.x, p.pos.y, p.img.width, p.img.height, p.img)
}

fn (mut p Player) update(gg &gg.Context) {
	wrap_around_screen(mut p, gg)

	if p.vel.x != 0 {
		p.vel.x *= 0.992
	}

	if p.vel.y != 0 {
		p.vel.y *= 0.992
	}

	p.pos.x += p.vel.x
	p.pos.y += p.vel.y

	p.angle = f32(math.sin(time.now().unix_time())) * 50
}

fn (mut p Player) center(gg &gg.Context) {
	x := (gg.width / 2) - (p.img.width / 2)
	y := (gg.height / 2) - (p.img.height / 2)
	p.pos.x = x
	p.pos.y = y
}

fn (mut p Player) teleport(gg &gg.Context) {
	mut padding := u32(25)
	p.pos.x = rand.u32_in_range(padding, u32(gg.width - p.img.width) - padding) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	p.pos.y = rand.u32_in_range(padding, u32(gg.height - p.img.height) - padding) or {
		println('Fatal Error: $err.msg')
		exit(0)
	}
	p.vel.x = 0
	p.vel.y = 0
}

struct Pos {
mut:
	x f32
	y f32
	z f32
}

struct Velocity {
mut:
	x   f32
	y   f32
	max f32 = 1.2
}

struct Rot {
mut:
	x f32
	y f32
	z f32
}

fn frame(mut app App) {
	app.gg.begin()
	app.draw()
	app.update()
	app.gg.end()
}

fn (mut app App) draw() {
	for star in app.stars {
		draw_renderable_object(star, app.gg)
	}
	for projectile in app.projectiles {
		draw_renderable_object(projectile, app.gg)
	}
	draw_renderable_object(app.player, app.gg)
	for mut a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}
}

fn (mut app App) update() {
	app.handle_keydown()
	for mut projectile in app.projectiles {
		// delete projectiles if they go off the screen
		// if projectile.pos.x < -projectile.img.width
		// 	|| projectile.pos.x > app.gg.width
		// 	|| projectile.pos.y < -projectile.img.height
		// 	|| projectile.pos.y > app.gg.height {
		// 	app.projectiles.delete(i)
		// 	continue
		// }
		projectile.update()
	}
	app.player.update(app.gg)
	for mut a in app.asteroids {
		a.update(app.gg)
	}
}

fn (mut app App) fire_projectile() {
	app.projectiles[app.projectile_index].pos.x = app.player.pos.x + app.player.img.width / 2 - app.projectiles[app.projectile_index].img.width / 2
	app.projectiles[app.projectile_index].pos.y = app.player.pos.y + app.player.img.height / 2 - app.projectiles[app.projectile_index].img.height / 2
	if app.projectile_index == 2 {
		app.projectile_index = 0
	} else {
		app.projectile_index++
	}
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			key := int(e.key_code)

			if e.key_code == .x && !app.keys_down[key] {
				app.fire_projectile()
			}

			if e.key_code == .z && !app.keys_down[key] {
				app.player.teleport(app.gg)
			}

			if key in app.keys_down {
				app.keys_down[key] = true
			}
		}
		.key_up {
			key := int(e.key_code)

			if key in app.keys_down {
				app.keys_down[key] = false
			}
		}
		else {}
	}
}

fn (mut app App) handle_keydown() {
	mut accel := f32(0.01)
	for key, key_is_down in app.keys_down {
		match key {
			262 {
				if key_is_down {
					app.player.vel.x += accel
					if app.player.vel.x > app.player.vel.max {
						app.player.vel.x = app.player.vel.max
					}
				}
			}
			263 {
				if key_is_down {
					app.player.vel.x -= accel
					if app.player.vel.x < -app.player.vel.max {
						app.player.vel.x = -app.player.vel.max
					}
				}
			}
			264 {
				if key_is_down {
					app.player.vel.y += accel
					if app.player.vel.y > app.player.vel.max {
						app.player.vel.y = app.player.vel.max
					}
				}
			}
			265 {
				if key_is_down {
					app.player.vel.y -= accel
					if app.player.vel.y < -app.player.vel.max {
						app.player.vel.y = -app.player.vel.max
					}
				}
			}
			else {}
		}
	}
}

fn main() {
	mut app := &App{
		gg: 0
		bgcolor: win_bgcolor
	}
	app.gg = gg.new_context(
		bg_color: app.bgcolor
		width: win_width
		height: win_height
		use_ortho: true // This is needed for 2D drawing
		create_window: true
		resizable: false
		window_title: win_title
		frame_fn: frame
		user_data: app
		// init_fn: init_images
		event_fn: on_event
	)
	app.player = Player{
		img: app.gg.create_image_from_byte_array(player_img.to_bytes()) //(os.resource_abs_path('arrow.png'))
		pos: Pos{}
	}
	app.projectiles = []Projectile{len: app.max_projectiles, init: new_projectile(mut app.gg,
		app.player)}
	app.player.center(app.gg)
	app.asteroids << new_asteroid(mut app.gg, .small)
	app.asteroids << new_asteroid(mut app.gg, .small)
	app.asteroids << new_asteroid(mut app.gg, .small)
	app.asteroids << new_asteroid(mut app.gg, .small)
	app.asteroids << new_asteroid(mut app.gg, .medium)
	app.asteroids << new_asteroid(mut app.gg, .medium)
	app.asteroids << new_asteroid(mut app.gg, .medium)
	app.asteroids << new_asteroid(mut app.gg, .large)
	app.asteroids << new_asteroid(mut app.gg, .large)

	for i := 0; i < 10; i++ {
		app.stars << new_star(mut app.gg)
	}

	app.gg.run()
}
