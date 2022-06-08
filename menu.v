module main

import gg
import gx

const menu_line = TextMenuItem{''}

// Menu is list of labels with a callback function that is
// invoked when a label is selected.
struct Menu {
	padding       int      = 10
	width         int      = 125
	height        int      = 20
	focused_color gx.Color = gx.white
	color         gx.Color = gx.Color{0xaa, 0xaa, 0xaa, 0xff}
	text_size     int      = 46
	center_text   bool     = true
mut:
	items   []MenuItem
	focused int
	pos     Pos
}

// draw draws the menu to the screen
fn (m &Menu) draw(g &gg.Context) {
	g.draw_text(-100, -100, '', size: m.text_size)
	for i, item in m.items {
		textx := if m.center_text {
			int((m.pos.x + (m.width / 2)) - g.text_width(item.name) / 2)
		} else {
			int(m.pos.x)
		}
		texty := int((m.pos.y + (m.height / 2) - (g.text_height(item.name) / 2) + (i * (m.height +
			m.padding))))

		match item {
			ButtonMenuItem {
				g.draw_text(textx, texty, item.name,
					bold: true
					size: m.text_size
					color: if i == m.focused { m.focused_color } else { m.color }
				)
			}
			ToggleMenuItem {
				g.draw_text(textx, texty, '$item.name: $item.value',
					bold: true
					size: m.text_size
					color: if i == m.focused { m.focused_color } else { m.color }
				)
			}
			NumberMenuItem {
				g.draw_text(textx, texty, '$item.name: < $item.value >',
					bold: true
					size: m.text_size
					color: if i == m.focused { m.focused_color } else { m.color }
				)
			}
			TextMenuItem {
				g.draw_text(textx, texty, '$item.name',
					bold: true
					size: m.text_size
					color: if i == m.focused { m.focused_color } else { m.color }
				)
			}
		}
	}
}

// MenuItem is a selectable item in a menu.
type MenuItem = ButtonMenuItem | TextMenuItem | NumberMenuItem | ToggleMenuItem

// ButtonMenuItem is a MenuItem which you can press.
struct ButtonMenuItem {
	name string
mut:
	cb fn (mut App)
}

// ToggleMenuItem is a MenuItem which you can toggle.
struct ToggleMenuItem {
	name string
mut:
	value string
	cb    fn (mut App) = fn (mut app App) {}
}

// NumberMenuItem is a MenuItem which you can set a number.
struct NumberMenuItem {
	name string
	step int = 1
mut:
	value int
	min int
	max int
}

// TextMenuItem is a MenuItem in which text is displayed.
struct TextMenuItem {
	name string
}
