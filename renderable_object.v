module main

import gg
import gx

// RenderableObject is an object that can be drawn to the screen
interface RenderableObject {
	img &gg.Image
mut:
	pos Pos
	angle f32
	scale f32
}

// this is how you would draw almost any image, so let's create one function
// instead of a draw function for each struct we have
fn draw_renderable_object(ro &RenderableObject, g &gg.Context) {
	// gg.draw_image(ro.pos.x, ro.pos.y, ro.img.width, ro.img.height, ro.img)
	g.draw_image_with_config(
		rotate: int(ro.angle)
		img: ro.img
		img_rect: gg.Rect{
			x: ro.pos.x
			y: ro.pos.y
			width: ro.img.width * ro.scale / g.scale
			height: ro.img.height * ro.scale / g.scale
		}
	)

	// hitbox and x,y position of RenderableObject
	$if debug {
		g.draw_rect_empty(ro.pos.x, ro.pos.y, ro.img.width * ro.scale, ro.img.height * ro.scale,
			gx.green)
		g.draw_circle_filled(ro.pos.x, ro.pos.y, 2, gx.red)
	}
}

// wrap_around_screen allows RenderableObjects to appear as if they loop
// around the screen when it reaches the edges.
fn wrap_around_screen(mut ro RenderableObject, g &gg.Context) {
	if ro.pos.x > g.width {
		ro.pos.x = -ro.img.width * ro.scale
	}
	if ro.pos.x < -ro.img.width * ro.scale {
		ro.pos.x = g.width
	}
	if ro.pos.y > g.height {
		ro.pos.y = -ro.img.height * ro.scale
	}
	if ro.pos.y < -ro.img.height * ro.scale {
		ro.pos.y = g.height
	}
}
