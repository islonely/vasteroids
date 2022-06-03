module main

import gg

// RenderableObject is an object that can be drawn to the screen
interface RenderableObject {
	img gg.Image
mut:
	pos Pos
	angle int
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