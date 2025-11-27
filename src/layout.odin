package editor

import rl "vendor:raylib"

Layout :: struct {
	rec:    rl.Rectangle,
	cursor: rl.Vector2,
}

layout_start :: proc(rec: rl.Rectangle) -> Layout {
	return Layout{rec = rec, cursor = {rec.x, rec.y}}
}

layout_next :: proc(layout: ^Layout, height: f32) -> rl.Rectangle {
	next_rec := rl.Rectangle{layout.cursor.x, layout.cursor.y, layout.rec.width, height}
	layout.cursor.y += height

	return next_rec
}

ui_label :: proc(layout: ^Layout, text: cstring) {
	label_rect := layout_next(layout, 30)
	rl.DrawText(text, i32(label_rect.x), i32(label_rect.y), 20, rl.BLACK)
}
