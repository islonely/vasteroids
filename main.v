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
import rand

// window configuration
const win_title = 'Vasteroids'
const win_width = 1200
const win_height = 800
const win_bgcolor = gx.Color{
	r: 20
	g: 20
	b: 20
}

// sprites
const sm_asteroid_img = $embed_file('img/sm_asteroid.png')
const md_asteroid_img = $embed_file('img/md_asteroid.png')
const lg_asteroid_img = $embed_file('img/lg_asteroid.png')
const star_img = $embed_file('img/star.png')
const projectile_img = $embed_file('img/laser.png')
const player_img = $embed_file('img/player.png')

const hyperspace = $embed_file('fonts/hyperspace/Hyperspace Bold.otf')

// GameState is the state which the game is in.
enum GameState {
	paused
	settings
	in_game
	new_game
	start_menu
	game_over
}

struct App {
mut:
	gg               &gg.Context = unsafe { nil }
	state            GameState   = .start_menu
	menu             Menu
	settings_menu    Menu
	delta            Delta
	show_fps         bool
	level            int
	score            int
	shots_fired      int
	asteroids_hit    int
	splits_per_break int = 2
	ammo             int = -1
	player           Player
	asteroids        []Asteroid
	projectiles      []Projectile
	projectile_index int
	max_projectiles  int = 5
	stars            []Star
	bgcolor          gx.Color = gx.white
	img              map[string]int
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

// break_asteroid splits in asteroid into smaller chunks or destroys it if
// it's already the smallest size.
fn (mut app App) break_asteroid(i int) {
	a := app.asteroids[i]
	if a.size == .small {
		app.asteroids.delete(i)
		return
	}

	mut switch_direction := false
	for _ in 0 .. app.splits_per_break {
		mut newa := new_asteroid(mut app.gg, unsafe { AsteroidSize(int(a.size) + 1) },
			if a.size == .large {
			app.img['md_asteroid']
		} else {
			app.img['sm_asteroid']
		})
		newa.pos = a.pos
		newa.vel = a.vel
		newa.vel.y = rand.f32_in_range(-a.vel.x, a.vel.x) or { a.vel.x }
		newa.vel.x = rand.f32_in_range(-a.vel.y, a.vel.y) or { a.vel.y }
		switch_direction = !switch_direction
		app.asteroids << newa
	}
	app.asteroids.delete(i)
}

// gen_pseudo_random_coords generates random X and Y coordinates in
// the provided range. Generated coordinates are prevent by being close
// to each other by separating the screen into block creating only one
// position per block.
fn (app &App) gen_pseudo_random_coords(rangex int, rangey int) []Pos {
	mut coords := []Pos{}
	mut x, mut y := 0, 0
	mut ypos, mut xpos := 0, 0
	block_size := int(150 / app.gg.scale)
	padding := int(20 / app.gg.scale)
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

// frame controls what happens every frame.
fn frame(mut app App) {
	app.gg.begin()
	app.delta.update()

	// println(app.delta.delta)
	if app.show_fps {
		fps := app.delta.fps()
		app.gg.draw_text(int(app.gg.width / app.gg.scale / 2) - app.gg.text_width(fps.str()),
			15, 'FPS: ${fps}',
			bold:  true
			size:  32
			color: gx.white
		)
	}
	match app.state {
		.paused {
			app.draw()
			app.draw_title_center('Paused')
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
		.game_over {
			app.draw_game_over()
			app.update_game_over()
		}
		.settings {
			app.draw_settings()
			app.update_settings()
		}
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

	// app.player.draw(app.gg)
	draw_renderable_object(app.player, app.gg)
	for mut a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}

	app.gg.draw_text(int(15 / app.gg.scale), int(15 / app.gg.scale), 'Level: ${app.level.str()}',
		bold:  true
		size:  int(32 / app.gg.scale)
		color: gx.white
	)
	app.gg.draw_text(int(app.gg.width / app.gg.scale - app.gg.text_width('Score: ${app.score.str()}') - 15),
		int(15 / app.gg.scale), 'Score: ${app.score.str()}',
		bold:  true
		size:  int(32 / app.gg.scale)
		color: gx.white
	)
}

// update controls the physics/logic that happens on each frame.
fn (mut app App) update() {
	app.handle_keydown()
	for mut projectile in app.projectiles {
		projectile.update(mut app)
	}
	app.player.update(mut app)
	for mut a in app.asteroids {
		a.update(app.gg, app.delta.delta)
	}

	if app.asteroids.len == 0 {
		app.init_level()
	}
}

// draw_start_menu draws the start menu content to the screen.
fn (mut app App) draw_start_menu() {
	for a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}
	for s in app.stars {
		draw_renderable_object(s, app.gg)
	}

	app.draw_title('Vasteroids')
	app.menu.draw(app.gg)
}

// draw_settings draws the settings content to the screen.
fn (mut app App) draw_settings() {
	for a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}
	for s in app.stars {
		draw_renderable_object(s, app.gg)
	}

	app.draw_title('Settings')
	app.settings_menu.draw(app.gg)
}

fn (mut app App) draw_game_over() {
	for s in app.stars {
		draw_renderable_object(s, app.gg)
	}
	for a in app.asteroids {
		draw_renderable_object(a, app.gg)
	}

	game_over_menu := Menu{
		items:       [
			TextMenuItem{'Level: ${app.level}'},
			TextMenuItem{'Score: ${app.score}'},
			TextMenuItem{'Shots Fired: ${app.shots_fired}'},
			TextMenuItem{'Accuracy: ' + ((app.asteroids_hit / f32(app.shots_fired)) * 100).str() +
				'%'},
			menu_line,
			TextMenuItem{'Enter to continue...'},
		]
		width:       int(300)
		height:      int(35 / app.gg.scale)
		text_size:   int(36 / app.gg.scale)
		padding:     int(10 / app.gg.scale)
		center_text: false
		focused:     -1
		color:       gx.white
		pos:         Pos{
			x: int((app.gg.width / app.gg.scale / 2) - (300 / 2))
			y: int(300 / app.gg.scale) // int((app.gg.height / app.gg.scale / 2) - (35 / 2))
		}
	}
	game_over_menu.draw(app.gg)
	app.draw_title('Game Over')
}

// update_start_menu updates the moving background items in the start menu.
fn (mut app App) update_start_menu() {
	for mut a in app.asteroids {
		a.update(app.gg, app.delta.delta)
	}
}

// update_settings updates the moving background items in the settings menu.
fn (mut app App) update_settings() {
	for mut a in app.asteroids {
		a.update(app.gg, app.delta.delta)
	}
}

fn (mut app App) update_game_over() {
	for mut a in app.asteroids {
		a.update(app.gg, app.delta.delta)
	}
}

// draw_title draws big, horizontally centered text onto the screen.
fn (mut app App) draw_title(title string) {
	title_size := int(75 / app.gg.scale)
	titlex := int((app.gg.width / app.gg.scale / 2) - (title.len * title_size / 4) + 12)
	titley := int(170 / app.gg.scale)
	app.gg.draw_text(titlex, titley, title,
		size:  title_size
		bold:  true
		color: gx.white
	)
}

fn (mut app App) draw_title_center(text string) {
	size := 75
	x := int((app.gg.width / 2) - (text.len * size / 4) + 12)
	y := int((app.gg.height / 2) - (app.gg.text_height(text) / 2)) - 10
	app.gg.draw_text(x, y, text,
		size:  size
		bold:  true
		color: gx.white
	)
}

// fire_projectile sets a projectile at the players position
fn (mut app App) fire_projectile() {
	app.shots_fired++
	app.projectiles[app.projectile_index].pos.x = app.player.pos.x + app.player.img.width / 2 - app.projectiles[app.projectile_index].img.width / 2
	app.projectiles[app.projectile_index].pos.y = app.player.pos.y + app.player.img.height / 2 - app.projectiles[app.projectile_index].img.height / 2
	app.projectiles[app.projectile_index].angle = app.player.angle

	x, y := angle_to_velocity(app.player.angle, 7)
	app.projectiles[app.projectile_index].vel.x = x
	app.projectiles[app.projectile_index].vel.y = y
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
						idx := app.menu.focused
						if idx >= 0 {
							if idx == app.menu.items.len - 1 {
								app.menu.focused = 0
							} else {
								app.menu.focused++
							}
						} else {
							println('Error: app.menu.focused (${app.menu.focused}) is not valid index.')
							app.menu.focused = 0
						}
					} else if e.key_code == .up {
						// move up in the list of menu items or loop to the end if we're at the top
						idx := app.menu.focused
						if idx >= 0 {
							if idx == 0 {
								app.menu.focused = app.menu.items.len - 1
							} else {
								app.menu.focused--
							}
						} else {
							println('Error: app.menu.focused (${app.menu.focused}) is not valid index.')
							app.menu.focused = 0
						}
					} else if e.key_code == .enter {
						// invoke callback function of whatever menu item is selected
						selected_item := app.menu.items[app.menu.focused]
						match selected_item {
							ButtonMenuItem {
								selected_item.cb(mut app)
							}
							ToggleMenuItem {
								selected_item.cb(mut app)
							}
							else {}
						}
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
						&& unsafe { gg.Modifier(e.modifiers) } == .ctrl {
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
		.settings {
			match e.typ {
				.key_down {
					if e.key_code == .escape {
						app.state = .start_menu
					} else if e.key_code == .down {
						// move down in the list of menu items or to the top if we're at the end
						idx := app.settings_menu.focused
						if idx >= 0 {
							if idx == app.settings_menu.items.len - 1 {
								app.menu.focused = 0
							} else {
								app.settings_menu.focused++
							}
						} else {
							println('Error: app.menu.focused (${app.settings_menu.focused}) is not valid index.')
							app.settings_menu.focused = 0
						}
					} else if e.key_code == .up {
						// move up in the list of menu items or loop to the end if we're at the top
						idx := app.settings_menu.focused
						if idx >= 0 {
							if idx == 0 {
								app.settings_menu.focused = app.settings_menu.items.len - 1
							} else {
								app.settings_menu.focused--
							}
						} else {
							println('Error: app.menu.focused (${app.settings_menu.focused}) is not valid index.')
							app.menu.focused = 0
						}
					} else if e.key_code == .enter {
						// invoke callback function of whatever menu item is selected
						selected_item := app.settings_menu.items[app.settings_menu.focused]
						match selected_item {
							ButtonMenuItem {
								selected_item.cb(mut app)
							}
							ToggleMenuItem {
								selected_item.cb(mut app)
							}
							else {}
						}
					} else if e.key_code == .left {
						mut selected_item := &app.settings_menu.items[app.settings_menu.focused]
						match mut selected_item {
							NumberMenuItem {
								if selected_item.value > selected_item.min {
									selected_item.value -= selected_item.step
									app.splits_per_break = selected_item.value
								}
							}
							else {}
						}
					} else if e.key_code == .right {
						mut selected_item := &app.settings_menu.items[app.settings_menu.focused]
						match mut selected_item {
							NumberMenuItem {
								if selected_item.value < selected_item.max {
									selected_item.value += selected_item.step
									app.splits_per_break = selected_item.value
								}
							}
							else {}
						}
					}
				}
				else {}
			}
		}
		.game_over {
			if e.key_code == .enter {
				app.state = .start_menu
				app.level = 1
				app.score = 0
				app.init_level()
			}
		}
		else {}
	}
}

// handle_keydown handles the keydown event
fn (mut app App) handle_keydown() {
	match app.state {
		.in_game {
			mut accel := app.player.acceleration * app.delta.delta
			for key, key_is_down in app.keys_down {
				match key {
					.right {
						if key_is_down {
							app.player.angle -= int(app.player.rotation_speed * app.delta.delta)
						}
					}
					.left {
						if key_is_down {
							app.player.angle += int(app.player.rotation_speed * app.delta.delta)
						}
					}
					.up {
						if key_is_down {
							// disallow accellerating while turning
							if app.keys_down[.left] || app.keys_down[.right] {
								return
							}
							x, y := angle_to_velocity(app.player.angle, 1)
							app.player.vel.maxx = x * 0.85
							app.player.vel.maxy = y * 0.85
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
	coords := app.gen_pseudo_random_coords(app.gg.width, app.gg.height)
	for i, mut star in app.stars {
		star.pos = coords[i] or { break }
	}

	app.player.center(app.gg)

	// start menu
	app.menu = Menu{
		items:     [
			ButtonMenuItem{'Start', fn (mut app App) {
				app.state = .in_game
			}},
			ButtonMenuItem{'Settings', fn (mut app App) {
				app.state = .settings
			}},
			ButtonMenuItem{'Exit', fn (mut app App) {
				exit(0)
			}},
		]
		focused:   0
		width:     int(200)
		height:    int(35 / app.gg.scale)
		text_size: int(46 / app.gg.scale)
		padding:   int(10 / app.gg.scale)
		pos:       Pos{
			x: int((app.gg.width / app.gg.scale / 2) - (200 / 2))
			y: int((app.gg.height / app.gg.scale / 2) - (35 / 2))
		}
	}

	// settings menu
	app.settings_menu = Menu{
		width:       int(300)
		height:      int(35 / app.gg.scale)
		text_size:   int(36 / app.gg.scale)
		padding:     int(10 / app.gg.scale)
		center_text: false
		pos:         Pos{
			x: int((app.gg.width / app.gg.scale / 2) - (300 / 2))
			y: int(300 / app.gg.scale) // int((app.gg.height / app.gg.scale / 2) - (35 / 2))
		}
	}

	mut show_fps_tggl := ToggleMenuItem{
		name:  'Show FPS'
		value: 'false'
	}
	show_fps_tggl.cb = fn (mut app App) {
		app.show_fps = !app.show_fps
		mut show_fps := &(app.settings_menu.items[0] as ToggleMenuItem)
		// toggles the value between true and false
		show_fps.value = (!(show_fps.value.bool())).str()
	}
	app.settings_menu.items << show_fps_tggl

	// NOTE: I don't think gg allows you to set fullscreen
	// mut fullscreen_tggl := ToggleMenuItem{
	// 	name: 'Fullscreen'
	// 	value: 'false'
	// }
	// fullscreen_tggl.cb = fn (mut app App) {
	// 	app.gg.fullscreen = !app.gg.fullscreen
	// 	mut fullscreen := &(app.settings_menu.items[1] as ToggleMenuItem)
	// 	fullscreen.value = (!(fullscreen.value.bool())).str()
	// }

	app.settings_menu.items << NumberMenuItem{'Splits', 1, 2, 0, 20}
	// app.settings_menu.items << NumberMenuItem{'Ammo', 100, 0, -1, 10000}

	mut back_bttn := ButtonMenuItem{
		name: 'Back'
		cb:   fn (mut app App) {
			app.state = .start_menu
		}
	}
	app.settings_menu.items << back_bttn
}

// resize resizes the drawing area to fit the window
fn resize(e &gg.Event, mut app App) {
	winsz := app.gg.window_size()
	app.gg.width = winsz.width
	app.gg.height = winsz.height
	coords := app.gen_pseudo_random_coords(int(app.gg.width), int(app.gg.height))
	for i, mut star in app.stars {
		star.pos = coords[i] or { break }
	}
	app.menu.pos = Pos{
		x: int(app.gg.width / app.gg.scale / 2 - 200 / 2)
		y: int(app.gg.height / app.gg.scale / 2 - 35 / 2)
	}
	if app.state == .start_menu {
		app.player.center(app.gg)
	}
}

// init_images caches the images to the gg.Context of the game.
fn (mut app App) init_images() ! {
	app.img['player'] = app.gg.cache_image(app.gg.create_image_from_byte_array(player_img.to_bytes())!)
	app.img['sm_asteroid'] = app.gg.cache_image(app.gg.create_image_from_byte_array(sm_asteroid_img.to_bytes())!)
	app.img['md_asteroid'] = app.gg.cache_image(app.gg.create_image_from_byte_array(md_asteroid_img.to_bytes())!)
	app.img['lg_asteroid'] = app.gg.cache_image(app.gg.create_image_from_byte_array(lg_asteroid_img.to_bytes())!)
	app.img['star'] = app.gg.cache_image(app.gg.create_image_from_byte_array(star_img.to_bytes())!)
	app.img['projectile'] = app.gg.cache_image(app.gg.create_image_from_byte_array(projectile_img.to_bytes())!)
}

// init_level spawns new asteroids and resets player velocity
// and position for the nexe level.
fn (mut app App) init_level() {
	app.asteroids = []Asteroid{}
	for _ in 0 .. (4 + app.level * 2) {
		app.asteroids << new_asteroid(mut app.gg, .large, app.img['lg_asteroid'])
	}
	app.keys_down = {
		gg.KeyCode.right: false
		gg.KeyCode.left:  false
		gg.KeyCode.down:  false
		gg.KeyCode.up:    false
		gg.KeyCode.space: false
		gg.KeyCode.enter: false
		gg.KeyCode.x:     false
		gg.KeyCode.z:     false
	}
	app.player = Player{
		img: app.gg.get_cached_image_by_idx(app.img['player'])
	}
	app.player.center(app.gg)
	app.level++
}

@[console]
fn main() {
	mut app := &App{
		bgcolor: win_bgcolor
	}
	app.gg = gg.new_context(
		bg_color:      app.bgcolor
		width:         win_width
		height:        win_height
		create_window: true
		// these two currently don't do anything
		borderless_window: true
		resizable:         true
		//
		window_title:      win_title
		font_bytes_bold:   hyperspace.to_bytes()
		font_bytes_normal: hyperspace.to_bytes()
		frame_fn:          frame
		user_data:         app
		event_fn:          on_event
		init_fn:           init
		resized_fn:        resize
	)
	app.init_images() or {
		println('Failed to load textures. Exiting...')
		exit(1)
	}
	app.stars = []Star{len: 200, init: new_star(mut app.gg, app.img['star'])}
	app.projectiles = []Projectile{len: app.max_projectiles, init: Projectile{
		img: app.gg.get_cached_image_by_idx(app.img['projectile'])
		pos: Pos{
			x: -100
			y: -100
		}
	}}

	app.init_level()

	app.gg.run()
}
