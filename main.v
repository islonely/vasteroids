/*
*	NOTE: Some implementations of things may seem awkward.
 * 		  This is both because I'm dumb and gg.Context has
 *		  no way to implement new images after it is running. (I think)
 *		  Also, this is the first game I've ever made, so feel
 * 		  free to give me pointers on what I should and shouldn't
 * 		  do if you notice anything weird.
*/
import gg
import gx
import math
import rand

// window configuration
const (
	win_title   = 'Vasteroids'
	win_width   = 600
	win_height  = 400
	win_bgcolor = gx.Color{
		r: 20
		g: 20
		b: 20
	}
)

// sprites
const (
	sm_asteroid = $embed_file('img/sm_asteroid.png')
	md_asteroid = $embed_file('img/md_asteroid.png')
	lg_asteroid = $embed_file('img/lg_asteroid.png')
	star        = $embed_file('img/star.png')
	laser       = $embed_file('img/laser.png')
	player_img  = $embed_file('img/player.png')

	hyperspace  = $embed_file('fonts/hyperspace/Hyperspace Bold.otf')
	simvoni     = $embed_file('fonts/Simvoni/Simvoni.ttf')
)

// GameState is the state which the game is in.
enum GameState {
	paused
	in_game
	new_game
	start_menu
	game_over
}

// Menu is list of labels with a callback function that is
// invoked when a label is selected.
struct Menu {
	items         map[string]fn (mut App)
	padding       int        = 10
	width         int        = 125
	height        int        = 20
	radius        int        = 3
	color         gx.Color   = gx.Color{0xcc, 0xcc, 0xcc, 0xdd}
	focused_color gx.Color   = gx.Color{0xaa, 0xcf, 0xff, 0xdd}
	text_conf     gx.TextCfg = gx.TextCfg{
		color: gx.black
		size: 25
		max_width: 125
	}
mut:
	focused string
	pos     Pos
}

// draw draws the menu to the screen
fn (m &Menu) draw(g &gg.Context) {
	mut i := 0
	for key in m.items.keys() {
		_ := g.text_width(key)
		_ := g.text_height(key)
		rectx := m.pos.x
		recty := m.pos.y + (i * (m.height + m.padding))
		textx := int(m.pos.x + (m.width / 2) - (g.text_width(key) / 2))
		texty := int(m.pos.y + (m.height / 2) - (g.text_height(key) / 2) + (i * (m.height +
			m.padding)))
		g.draw_rounded_rect_filled(rectx, recty, m.width, m.height, m.radius, if m.focused == key {
			m.focused_color
		} else {
			m.color
		})
		g.draw_text(textx, texty, key, m.text_conf)
		i++
	}
}

struct App {
mut:
	gg               &gg.Context
	state            GameState = .start_menu
	menu             Menu
	score            int
	player           Player
	asteroids        []Asteroid
	projectiles      []Projectile
	projectile_index int
	max_projectiles  int = 5
	stars            []Star
	bgcolor          gx.Color = gx.white
	keys_down        map[gg.KeyCode]bool = {
		gg.KeyCode.right: false
		gg.KeyCode.left:  false
		gg.KeyCode.down:  false
		gg.KeyCode.up:    false
		gg.KeyCode.space: false
		gg.KeyCode.enter: false
		gg.KeyCode.x:     false
		gg.KeyCode.z:     false
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
	mut maxv := f32(0.25)
	mut minv := f32(0.1)
	match size {
		.small {
			img = gg.create_image_from_byte_array(sm_asteroid.to_bytes())
			maxv *= 1.3
			minv *= 1.3
		}
		.medium {
			img = gg.create_image_from_byte_array(md_asteroid.to_bytes())
			maxv *= 1.15
			minv *= 1.15
		}
		.large {
			img = gg.create_image_from_byte_array(lg_asteroid.to_bytes())
		}
	}

	x := rand.u32n(u32(win_width - img.width)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
	y := rand.u32n(u32(win_height - img.height)) or {
		println('Fatal Error: $err.msg()')
		exit(0)
	}
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
	match app.state {
		.paused {}
		.in_game {
			app.draw()
			app.update()
		}
		.new_game {}
		.start_menu {
			app.draw_start_menu()
			app.update_start_menu()
		}
		.game_over {}
	}
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

fn (mut app App) draw_start_menu() {
	for a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}
	for s in app.stars {
		draw_renderable_object(s, app.gg)
	}

	logo_text := 'Vasteroids'
	logo_size := int(72 * app.gg.scale)
	logox := int((app.gg.width * app.gg.scale / 2) - (logo_text.len * logo_size / 4) + 10)
	logoy := int(150 * app.gg.scale)
	app.gg.draw_text(logox, logoy, logo_text,
		size: logo_size
		bold: true
		color: gx.white
	)
	app.menu.draw(app.gg)
}

fn (mut app App) update_start_menu() {
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
			// key presses i.e. doesn't detect when key is held down.
			if e.key_code == .down && !app.keys_down[e.key_code] && app.state == .start_menu {
				// move down in the list of menu items or to the top if we're at the end
				keys := app.menu.items.keys()
				idx := keys.index(app.menu.focused)
				if idx >= 0 {
					if idx == keys.len - 1 {
						app.menu.focused = keys[0]
					} else {
						app.menu.focused = keys[idx + 1]
					}
				}
			} else if e.key_code == .up && !app.keys_down[e.key_code] && app.state == .start_menu {
				// move up in the list of menu items or loop to the end if we're at the top
				keys := app.menu.items.keys()
				idx := keys.index(app.menu.focused)
				if idx >= 0 {
					if idx == 0 {
						app.menu.focused = keys[keys.len - 1]
					} else {
						app.menu.focused = keys[idx - 1]
					}
				}
			} else if e.key_code == .enter && !app.keys_down[e.key_code] && app.state == .start_menu {
				// invoke callback function of whatever menu item is selected
				app.menu.items[app.menu.focused](mut app)
			} else if e.key_code == .x && !app.keys_down[e.key_code] {
				app.fire_projectile()
			} else if e.key_code == .z && !app.keys_down[e.key_code] {
				app.player.teleport(app.gg)
			} else if e.key_code in app.keys_down {
				app.keys_down[e.key_code] = true
			}
		}
		.key_up {
			if e.key_code in app.keys_down {
				app.keys_down[e.key_code] = false
			}
		}
		else {}
	}
}

// handle_keydown handles the keydown event
fn (mut app App) handle_keydown() {
	match app.state {
		.in_game {
			mut accel := f32(0.0035)
			for key, key_is_down in app.keys_down {
				match key {
					.right {
						if key_is_down {
							// app.player.vel.x += accel
							// if app.player.vel.x > app.player.vel.max {
							// 	app.player.vel.x = app.player.vel.max
							// }
							app.player.angle -= 1
						}
					}
					.left {
						if key_is_down {
							// app.player.vel.x -= accel
							// if app.player.vel.x < -app.player.vel.max {
							// 	app.player.vel.x = -app.player.vel.max
							// }
							app.player.angle += 1
						}
					}
					// 264 {
					// 	if key_is_down {
					// 		app.player.vel.y += accel
					// 		if app.player.vel.y > app.player.vel.max {
					// 			app.player.vel.y = app.player.vel.max
					// 		}
					// 	}
					// }
					.up {
						if key_is_down {
							// app.player.vel.y -= accel
							// if app.player.vel.y < -app.player.vel.max {
							// 	app.player.vel.y = -app.player.vel.max
							// }
							// disallow accellerating while turning
							if app.keys_down[.left] || app.keys_down[.right] {
								return
							}
							app.player.vel.maxx, app.player.vel.maxy = angle_to_velocity(app.player.angle,
								1)
							if app.player.vel.maxx > 0 {
								if app.player.vel.x > app.player.vel.maxx {
									app.player.vel.x -= accel
								} else {
									app.player.vel.x += accel
								}
							} else {
								if app.player.vel.x < app.player.vel.maxx {
									app.player.vel.x += accel
								} else {
									app.player.vel.x -= accel
								}
							}
							if app.player.vel.maxy > 0 {
								if app.player.vel.y > app.player.vel.maxy {
									app.player.vel.y -= accel
								} else {
									app.player.vel.y += accel
								}
							} else {
								if app.player.vel.y < app.player.vel.maxy {
									app.player.vel.y += accel
								} else {
									app.player.vel.y -= accel
								}
							}
						}
					}
					else {}
				}
			}
		}
		else {}
	}
}

// init is invoked once after App.run() is called
fn init(mut app App) {
	// on my high dpi display the drawing area was bigger than the window
	app.gg.width = int(app.gg.width / app.gg.scale)
	app.gg.height = int(app.gg.height / app.gg.scale)

	coords := gen_pseudo_random_coords(app.gg.width, app.gg.height)
	for i, mut star in app.stars {
		star.pos = coords[i] or { break }
	}

	app.menu = Menu{
		items: {
			'Start': fn (mut app App) {
				app.state = .in_game
			}
			'Quit':  fn (mut app App) {
				exit(0)
			}
		}
		focused: 'Start'
		width: int(200 * app.gg.scale)
		height: int(35 * app.gg.scale)
		pos: Pos{
			x: int(app.gg.width * app.gg.scale / 2 - 200 * app.gg.scale / 2)
			y: int(app.gg.height * app.gg.scale / 2 - 35 * app.gg.scale / 2)
		}
	}
}

// resize resizes the drawing area to fit the window
fn resize(e &gg.Event, mut app App) {
	app.gg.width = int(e.window_width / app.gg.scale)
	app.gg.height = int(e.window_height / app.gg.scale)
	app.menu.pos = Pos{
		x: int(app.gg.width * app.gg.scale / 2 - 200 * app.gg.scale / 2)
		y: int(app.gg.height * app.gg.scale / 2 - 35 * app.gg.scale / 2)
	}
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

[console]
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
		font_bytes_bold: hyperspace.to_bytes()
		font_bytes_normal: simvoni.to_bytes()
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
	app.player.center(app.gg)
	// app.asteroids = []Asteroid{len: 10, init: new_asteroid(mut app.gg, .large)}
	for _ in 0 .. 10 {
		app.asteroids << new_asteroid(mut app.gg, .large)
	}
	app.stars = []Star{len: 100, init: new_star(mut app.gg)}
	app.projectiles = []Projectile{len: app.max_projectiles, init: new_projectile(mut app.gg,
		app.player)}

	app.gg.run()
}
