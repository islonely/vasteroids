module main

import gg
import gx

// Menu is list of labels with a callback function that is
// invoked when a label is selected.
struct Menu {
	items         map[string]fn (mut App)
	padding       int      = 10
	width         int      = 125
	height        int      = 20
	focused_color gx.Color = gx.white
	color         gx.Color = gx.Color{0xaa, 0xaa, 0xaa, 0xff}
	text_size     int      = 46
	center_text   bool     = true
mut:
	focused string
	pos     Pos
}

// draw draws the menu to the screen
fn (m &Menu) draw(g &gg.Context) {
	mut i := 0
	g.draw_text(-100, -100, '', size: m.text_size)
	for key in m.items.keys() {
		textx := if m.center_text {
			int((m.pos.x + (m.width / 2)) - g.text_width(key) / 2)
		} else {
			int(m.pos.x)
		}
		texty := int((m.pos.y + (m.height / 2) - (g.text_height(key) / 2) + (i * (m.height +
			m.padding))))
		i++
		g.draw_text(textx, texty, key,
			bold: true
			size: m.text_size
			color: if key == m.focused { m.focused_color } else { m.color }
		)
	}
}
