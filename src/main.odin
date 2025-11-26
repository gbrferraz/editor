package editor

import rl "vendor:raylib"

Vec3 :: [3]f32

Transform :: struct {
	position: Vec3,
	rotation: Vec3,
	size:     Vec3,
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 720, "Level Editor")

	cube := Transform {
		size = 2,
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

	for !rl.WindowShouldClose() {
		if rl.IsCursorHidden() {rl.UpdateCamera(&camera, .FREE)}

		if rl.IsMouseButtonDown(.RIGHT) {
			rl.DisableCursor()
		} else if rl.IsMouseButtonReleased(.RIGHT) {
			rl.EnableCursor()
		}

		if rl.IsMouseButtonPressed(.LEFT) {
			if !collision.hit {
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
			} else {
				collision.hit = false
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
		rl.DrawRectangleRec(right_panel, rl.GRAY)

		rl.DrawText("Transform", i32(right_panel.x), i32(right_panel.y), 20, rl.BLACK)

		rl.EndDrawing()
	}
	rl.CloseWindow()
}
