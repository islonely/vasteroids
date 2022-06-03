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
	g.draw_text(-100, -100, '', m.text_conf)
	for key in m.items.keys() {
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
	delta            Delta
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

fn (mut app App) break_asteroid(i int) {
	a := app.asteroids[i]
	if a.size == .small {
		app.asteroids.delete(i)
		return
	}

	mut a2 := new_asteroid(mut app.gg, AsteroidSize(int(a.size) - 1))
	mut a3 := new_asteroid(mut app.gg, AsteroidSize(int(a.size) - 1))
	a2.vel = a.vel
	a2.vel.y = a.vel.x
	a2.vel.x = a.vel.y
	a3.vel = a.vel
	a3.vel.y = -a.vel.x
	a3.vel.x = -a.vel.y

	app.asteroids << a2
	app.asteroids << a3
	app.asteroids.delete(i)
}

// frame controls what happens every frame.
fn frame(mut app App) {
	app.gg.begin()
	match app.state {
		.paused {
			app.draw()
			text := 'Paused'
			size := int(72 * app.gg.scale)
			x := int((app.gg.width * app.gg.scale / 2) - (app.gg.text_width(text) / 2))
			y := int((app.gg.height * app.gg.scale / 2) - (app.gg.text_height(text) / 2))
			app.gg.draw_text(x, y, text,
				size: size
				bold: true
				color: gx.white
			)
		}
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

	app.player.draw(app.gg)
	for mut a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}

	app.gg.draw_text(int(app.gg.width * app.gg.scale - 30), 15, app.score.str(),
		bold: true
		size: 32
		color: gx.white
	)
}

// update controls the physics/logic that happens on each frame.
fn (mut app App) update() {
	app.handle_keydown()
	for mut projectile in app.projectiles {
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
	match app.state {
		.paused {
			match e.typ {
				.key_down {
					if e.key_code == .escape {
						app.state = .in_game
					}
				}
				else {}
			}
		}
		.start_menu {
			match e.typ {
				.key_down {
					if e.key_code == .down {
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
					} else if e.key_code == .up {
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
					} else if e.key_code == .enter {
						// invoke callback function of whatever menu item is selected
						app.menu.items[app.menu.focused](mut app)
					}
				}
				else {}
			}
		}
		.in_game {
			match e.typ {
				.key_down {
					// key presses i.e. doesn't detect when key is held down.
					if e.key_code == .x && !app.keys_down[e.key_code] {
						app.fire_projectile()
					} else if e.key_code == .z && !app.keys_down[e.key_code] {
						app.player.teleport(app.gg)
					} else if e.key_code == .escape && !app.keys_down[e.key_code] {
						app.state = .paused
					} else if e.key_code == .b && !app.keys_down[e.key_code]
						&& gg.Modifier(e.modifiers) == .ctrl {
						app.break_asteroid(0)
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
							app.player.angle -= 1
						}
					}
					.left {
						if key_is_down {
							app.player.angle += 1
						}
					}
					.up {
						if key_is_down {
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
