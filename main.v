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
import rand

const (
	win_title   = 'Asteroids'
	win_width   = 800
	win_height  = 800
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
	max_projectiles  int = 5
	stars            []Star
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

// RenderableObject is an object that can be drawn to the screen
interface RenderableObject {
	img gg.Image
mut:
	pos Pos
	angle int
}

// Projectile is the red laser that is shot when the user presses the fire button.
struct Projectile {
	img gg.Image
mut:
	pos   Pos
	vel   Velocity
	angle int
}

// new_projectile instantiates Projectile and places it at the players position.
fn new_projectile(mut gg gg.Context, player &Player) Projectile {
	img := gg.create_image_from_byte_array(laser.to_bytes())
	println('x: ' + math.cos(f64(player.angle)).str())
	println('y: ' + math.sin(f64(player.angle)).str())
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
fn (mut p Projectile) update() {
	p.pos.x += p.vel.x
	p.pos.y += p.vel.y
}

// Star is just an image of a star used as a decoration.
struct Star {
	img gg.Image
mut:
	pos   Pos
	angle int
}

// new_star instantiates a Star
fn new_star(mut gg gg.Context) Star {
	img := gg.create_image_from_byte_array(star.to_bytes())
	x := rand.u32n(u32(win_width - img.width)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	y := rand.u32n(u32(win_height - img.height)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	return Star{
		img: img
		pos: Pos{
			x: x
			y: y
		}
	}
}

// Asteroid is one of the object the player can collide with or fire
// their projectiles at.
struct Asteroid {
	img  gg.Image
	size AsteroidSize
mut:
	pos   Pos
	vel   Velocity
	angle int
}

// AsteroidSize is the size of the asterdroid drawn. In the original
// game small asteroids move across the screen faster.
pub enum AsteroidSize {
	large = 1
	medium = 2
	small = 3
}

[inline]
fn is_odd(x int) int {
	// same as if x % 2 == 0 { -1 } else { 1 } but it's branchless.
	// I just found out about branchless programming
	// so I had to find a way to implement it
	return [-1, 1][x % 2]
}

// new_asteroid instantiates a new Asteroid and sets it's velocity
// based on it's size
fn new_asteroid(mut gg gg.Context, size AsteroidSize) Asteroid {
	mut img := gg.create_image_from_byte_array([]byte{})
	match size {
		.small { img = gg.create_image_from_byte_array(sm_asteroid.to_bytes()) }
		.medium { img = gg.create_image_from_byte_array(md_asteroid.to_bytes()) }
		.large { img = gg.create_image_from_byte_array(lg_asteroid.to_bytes()) }
	}

	x := rand.u32n(u32(win_width - img.width)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	y := rand.u32n(u32(win_height - img.height)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	maxv := f32(0.25)
	minv := f32(0.1)
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
fn draw_renderable_object(ro &RenderableObject, g &gg.Context) {
	// gg.draw_image(ro.pos.x, ro.pos.y, ro.img.width, ro.img.height, ro.img)
	g.draw_image_with_config(
		rotate: ro.angle
		img: &ro.img
		img_rect: gg.Rect{
			x: ro.pos.x
			y: ro.pos.y
			width: ro.img.width * g.scale
			height: ro.img.height * g.scale
		}
	)
}

// wrap_around_screen allows RenderableObjects to appear as if they loop
// around the screen when it reaches the edges.
fn wrap_around_screen(mut ro RenderableObject, gg &gg.Context) {
	if ro.pos.x > gg.width {
		ro.pos.x = -ro.img.width * gg.scale
	}
	if ro.pos.x < -ro.img.width * gg.scale {
		ro.pos.x = gg.width
	}
	if ro.pos.y > gg.height {
		ro.pos.y = -ro.img.height * gg.scale
	}
	if ro.pos.y < -ro.img.height * gg.scale {
		ro.pos.y = gg.height
	}
}

// update handles the physics/logic for asteroids
fn (mut a Asteroid) update(gg &gg.Context) {
	wrap_around_screen(mut a, gg)

	a.pos.x += a.vel.x
	a.pos.y += a.vel.y
}

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
		p.vel.x *= 0.992
	}

	if p.vel.y != 0 {
		p.vel.y *= 0.992
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
	x   f32
	y   f32
	max f32 = 1.2
}

// Rot is the rotation of a RenderableObject.
struct Rot {
mut:
	x f32
	y f32
	z f32
}

// frame controls what happens every frame.
fn frame(mut app App) {
	app.gg.begin()
	app.draw()
	app.update()
	app.gg.end()
}

// draw controls what gets drawn to the screen.
fn (mut app App) draw() {
	for star in app.stars {
		draw_renderable_object(star, app.gg)
	}
	for projectile in app.projectiles {
		draw_renderable_object(projectile, app.gg)
	}
	draw_renderable_object(app.player, app.gg)
	// app.player.draw(app.gg)
	for mut a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}
}

// update controls the physics/logic that happens on each frame.
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

fn angle_to_velocity(angle int, max_speed f32) (f32, f32) {
	radians_x := f64(angle + 90) * (math.pi / 180.0)
	radians_y := f64(angle + 90) * (math.pi / 180.0)
	vel_x := math.cos(radians_x)
	vel_y := math.sin(radians_y)
	return f32(max_speed * vel_x), -f32(max_speed * vel_y)
}

// fire_projectile sets a projectile at the players position
fn (mut app App) fire_projectile() {
	app.projectiles[app.projectile_index].pos.x = app.player.pos.x +
		app.player.img.width * app.gg.scale / 2 - app.projectiles[app.projectile_index].img.width * app.gg.scale / 2
	app.projectiles[app.projectile_index].pos.y = app.player.pos.y +
		app.player.img.height * app.gg.scale / 2 - app.projectiles[app.projectile_index].img.height * app.gg.scale / 2
	app.projectiles[app.projectile_index].angle = app.player.angle

	// radians_x := f64(app.player.angle + 90) * (math.pi / 180.0)
	// radians_y := f64(app.player.angle + 90) * (math.pi / 180.0)
	// vel_x := math.cos(radians_x)
	// vel_y := math.sin(radians_y)

	app.projectiles[app.projectile_index].vel.x, app.projectiles[app.projectile_index].vel.y = angle_to_velocity(app.player.angle,
		10)
	if app.projectile_index == app.max_projectiles - 1 {
		app.projectile_index = 0
	} else {
		app.projectile_index++
	}
}

// on_event handles any events
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

// handle_keydown handles the keydown event
fn (mut app App) handle_keydown() {
	mut accel := f32(0.01)
	for key, key_is_down in app.keys_down {
		match key {
			262 {
				if key_is_down {
					// app.player.vel.x += accel
					// if app.player.vel.x > app.player.vel.max {
					// 	app.player.vel.x = app.player.vel.max
					// }
					app.player.angle -= 1
				}
			}
			263 {
				if key_is_down {
					// app.player.vel.x -= accel
					// if app.player.vel.x < -app.player.vel.max {
					// 	app.player.vel.x = -app.player.vel.max
					// }
					app.player.angle += 1
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

// init is invoked once after App.run() is called
fn init(mut app App) {
	// on my high dpi display the drawing area was bigger than the window
	app.gg.width = int(app.gg.width / app.gg.scale)
	app.gg.height = int(app.gg.height / app.gg.scale)
	// app.gg.resize(int(app.gg.width / app.gg.scale), int(app.gg.height / app.gg.scale))
}

// resize resizes the drawing area to fit the window
fn resize(e &gg.Event, mut app App) {
	println(e)
	app.gg.width = int(e.window_width / app.gg.scale)
	app.gg.height = int(e.window_height / app.gg.scale)
}

fn main() {
	mut app := &App{
		gg: 0
		bgcolor: win_bgcolor
	}
	app.gg = gg.new_context(
		bg_color: app.bgcolor
		width: win_width * 2
		height: win_height * 2
		use_ortho: true
		create_window: true
		resizable: false
		window_title: win_title
		frame_fn: frame
		user_data: app
		event_fn: on_event
		init_fn: init
		resized_fn: resize
	)
	app.player = Player{
		img: app.gg.create_image_from_byte_array(player_img.to_bytes())
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

	for _ in 0 .. 10 {
		app.stars << new_star(mut app.gg)
	}

	app.gg.run()
}
