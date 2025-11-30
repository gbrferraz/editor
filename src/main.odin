package editor

import "core:math"
import rl "vendor:raylib"

Vec3 :: [3]f32

Editor :: struct {
	selected_brush: int,
	brushes:        [dynamic]Brush,
	is_dragging:    bool,
	camera:         rl.Camera,
	creating_brush: bool,
	brush_start:    Vec3,
}

Transform :: struct {
	position: Vec3,
	rotation: Vec3,
	size:     Vec3,
}

Brush :: struct {
	using transform: Transform,
}

update_editor :: proc(editor: ^Editor) {
	ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), editor.camera)

	if editor.selected_brush != -1 {
		if rl.IsKeyPressed(.X) {
			unordered_remove(&editor.brushes, editor.selected_brush)
			editor.selected_brush = -1
		}
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		editor.selected_brush = get_brush_under_mouse(ray, editor.brushes[:])
		// It's confusing to only have the is dragging condition true If a brush is selected.
		// It would also be dragging if creating a new brush.
		if editor.selected_brush != -1 {
			editor.is_dragging = true
		} else {
			collision := rl.GetRayCollisionQuad(
				ray,
				{-1000, 0, -1000},
				{-1000, 0, 1000},
				{1000, 0, 1000},
				{1000, 0, -1000},
			)

			if collision.hit {
				editor.creating_brush = true
				editor.brush_start = snap_to_grid(collision.point, 1) // What size should be used?
				append(
					&editor.brushes,
					Brush{transform = Transform{position = editor.brush_start, size = 1}},
				)

				editor.selected_brush = len(editor.brushes) - 1
			}
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		editor.is_dragging = false
		editor.creating_brush = false
	}

	if editor.is_dragging && editor.selected_brush != -1 {
		collision: rl.RayCollision
		brush := &editor.brushes[editor.selected_brush]

		if rl.IsKeyDown(.LEFT_ALT) {
			collision = rl.GetRayCollisionQuad(
				ray,
				{-1000, -1000, brush.position.z},
				{-1000, 1000, brush.position.z},
				{1000, 1000, brush.position.z},
				{1000, -1000, brush.position.z},
			)
			if collision.hit {
				brush.position = {
					brush.position.x,
					snap_to_grid(collision.point, brush.size).y,
					brush.position.z,
				}
			}
		} else {
			collision = rl.GetRayCollisionQuad(
				ray,
				{-1000, brush.position.y, -1000},
				{-1000, brush.position.y, 1000},
				{1000, brush.position.y, 1000},
				{1000, brush.position.y, -1000},
			)
			if collision.hit {
				brush.position = snap_to_grid(
					collision.point,
					editor.brushes[editor.selected_brush].transform.size,
				)
			}
		}

	}
	if editor.creating_brush {
		brush := &editor.brushes[len(editor.brushes) - 1]
		collision := rl.GetRayCollisionQuad(
			ray,
			{-1000, brush.position.y, -1000},
			{-1000, brush.position.y, 1000},
			{1000, brush.position.y, 1000},
			{1000, brush.position.y, -1000},
		)

		current_point := snap_to_grid(collision.point, 1)

		brush^ = {
			transform = {
				position = (editor.brush_start + current_point) / 2,
				size = {
					abs(current_point.x - editor.brush_start.x),
					1,
					abs(current_point.z - editor.brush_start.z),
				},
			},
		}
	}

	if rl.IsCursorHidden() {rl.UpdateCamera(&editor.camera, .FREE)}

	if rl.IsMouseButtonDown(.RIGHT) {
		rl.DisableCursor()
	} else if rl.IsMouseButtonReleased(.RIGHT) {
		rl.EnableCursor()
	}
}

draw_ui :: proc(editor: ^Editor) {
	right_panel := rl.Rectangle{f32(rl.GetScreenWidth()) - 300, 0, 300, 50}
	layout := layout_start(right_panel)

	rl.DrawRectangleRec(right_panel, rl.GRAY)
	ui_label(&layout, "Brushes")
	brush_count_string := rl.TextFormat("Count: %d", len(editor.brushes))
	ui_label(&layout, brush_count_string)
	ui_label(&layout, rl.TextFormat("Selected brush: %i", editor.selected_brush))

	if editor.selected_brush != -1 {
		ui_label(&layout, "Selected Brush")
		transform_string := rl.TextFormat(
			"X: %f, Y: %f, Z: %f",
			editor.brushes[editor.selected_brush].transform.position.x,
			editor.brushes[editor.selected_brush].transform.position.y,
			editor.brushes[editor.selected_brush].transform.position.z,
		)
		ui_label(&layout, transform_string)
	}
}

get_brush_under_mouse :: proc(ray: rl.Ray, brushes: []Brush) -> int {
	closest_distance: f32 = 999999.0
	closest_brush: int = -1

	for brush, i in brushes {
		bounds := rl.BoundingBox {
			min = {
				brush.transform.position.x - brush.transform.size.x / 2,
				brush.transform.position.y - brush.transform.size.y / 2,
				brush.transform.position.z - brush.transform.size.z / 2,
			},
			max = {
				brush.transform.position.x + brush.transform.size.x / 2,
				brush.transform.position.y + brush.transform.size.y / 2,
				brush.transform.position.z + brush.transform.size.z / 2,
			},
		}

		brush_collision := rl.GetRayCollisionBox(ray, bounds)
		if brush_collision.hit && brush_collision.distance < closest_distance {
			closest_distance = brush_collision.distance
			closest_brush = i
		}
	}
	return closest_brush
}

draw_brushes :: proc(selected_brush: int, brushes: []Brush) {
	for brush, i in brushes {
		cube_color := rl.GRAY
		wire_color := rl.DARKGRAY

		if i == selected_brush {
			cube_color = rl.RED
			wire_color = rl.MAROON
		}

		rl.DrawCube(
			brush.transform.position,
			brush.transform.size.x,
			brush.transform.size.y,
			brush.transform.size.z,
			cube_color,
		)
		rl.DrawCubeWires(
			brush.transform.position,
			brush.transform.size.x,
			brush.transform.size.y,
			brush.transform.size.z,
			wire_color,
		)
	}
}

snap_to_grid :: proc(pos: Vec3, size: Vec3) -> Vec3 {
	rounded := pos - (size / 2)
	rounded = {math.round(rounded.x), math.round(rounded.y), math.round(rounded.z)}
	return rounded + size / 2
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.InitWindow(1280, 720, "Level Editor")
	rl.SetTargetFPS(60)

	editor := Editor {
		selected_brush = -1,
		camera = {
			position = {10, 10, 10},
			up = {0, 1, 0},
			target = {0, 0, 0},
			fovy = 45,
			projection = .PERSPECTIVE,
		},
	}

	append(&editor.brushes, Brush{transform = Transform{position = .5, size = 1}})
	append(&editor.brushes, Brush{transform = Transform{size = 3}})

	for !rl.WindowShouldClose() {
		update_editor(&editor)

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		rl.BeginMode3D(editor.camera)

		draw_brushes(editor.selected_brush, editor.brushes[:])
		rl.DrawGrid(10, 1)

		rl.EndMode3D()

		draw_ui(&editor)

		rl.EndDrawing()
	}
	rl.CloseWindow()
}
