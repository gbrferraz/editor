package editor

import "core:math"
import rl "vendor:raylib"

Vec3 :: [3]f32

Transform :: struct {
	position: Vec3,
	rotation: Vec3,
	size:     Vec3,
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 720, "Level Editor")

	cube := Transform {
		position = {1, 0, 1},
		size     = 2,
	}

	camera := rl.Camera {
		position   = {10, 10, 10},
		up         = {0, 1, 0},
		target     = {0, 0, 0},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}

	ray: rl.Ray
	collision: rl.RayCollision

	is_dragging: bool

	for !rl.WindowShouldClose() {
		if rl.IsCursorHidden() {rl.UpdateCamera(&camera, .FREE)}

		if rl.IsMouseButtonDown(.RIGHT) {
			rl.DisableCursor()
		} else if rl.IsMouseButtonReleased(.RIGHT) {
			rl.EnableCursor()
		}

		if rl.IsMouseButtonDown(.LEFT) {
			ray = rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
			collision = rl.GetRayCollisionBox(
				ray,
				{
					{
						cube.position.x - cube.size.x / 2,
						cube.position.y - cube.size.y / 2,
						cube.position.z - cube.size.z / 2,
					},
					{
						cube.position.x + cube.size.x / 2,
						cube.position.y + cube.size.y / 2,
						cube.position.z + cube.size.z / 2,
					},
				},
			)
			if collision.hit {
				is_dragging = true
			}
		}

		if rl.IsMouseButtonReleased(.LEFT) && is_dragging {
			is_dragging = false
		}

		if is_dragging {
			ray = rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
			collision: rl.RayCollision
			if rl.IsKeyDown(.LEFT_ALT) {
				collision = rl.GetRayCollisionQuad(
					ray,
					{-1000, -1000, cube.position.z},
					{-1000, 1000, cube.position.z},
					{1000, 1000, cube.position.z},
					{1000, -1000, cube.position.z},
				)
				if collision.hit {
					cube.position = {
						cube.position.x,
						math.round(collision.point.y),
						cube.position.z,
					}
				}
			} else {
				collision = rl.GetRayCollisionQuad(
					ray,
					{-1000, cube.position.y, -1000},
					{-1000, cube.position.y, 1000},
					{1000, cube.position.y, 1000},
					{1000, cube.position.y, -1000},
				)
				if collision.hit {
					cube.position = {
						math.round(collision.point.x),
						math.round(collision.point.y),
						math.round(collision.point.z),
					}
				}
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		rl.BeginMode3D(camera)

		if collision.hit {
			rl.DrawCube(cube.position, cube.size.x, cube.size.y, cube.size.z, rl.RED)
			rl.DrawCubeWires(cube.position, cube.size.x, cube.size.y, cube.size.z, rl.MAROON)

			rl.DrawCubeWires(
				cube.position,
				cube.size.x + 0.2,
				cube.size.y + 0.2,
				cube.size.z + 0.2,
				rl.MAROON,
			)
		} else {
			rl.DrawCube(cube.position, cube.size.x, cube.size.y, cube.size.z, rl.GRAY)
			rl.DrawCubeWires(cube.position, cube.size.x, cube.size.y, cube.size.z, rl.DARKGRAY)
		}

		rl.DrawGrid(10, 1)

		rl.EndMode3D()

		right_panel := rl.Rectangle{f32(rl.GetScreenWidth()) - 300, 0, 300, 50}
		layout := layout_start(right_panel)

		rl.DrawRectangleRec(right_panel, rl.GRAY)
		ui_label(&layout, "Transform")
		transform_string := rl.TextFormat(
			"X: %f, Y: %f, Z: %f",
			cube.position.x,
			cube.position.y,
			cube.position.z,
		)

		ui_label(&layout, transform_string)

		rl.EndDrawing()
	}
	rl.CloseWindow()
}
