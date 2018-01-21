import	"core:fmt.odin";
import	"core:math.odin";
import	"core:strings.odin";

import	"shared:odin-glfw/glfw.odin";
import	"shared:odin-gl/gl.odin";

import gui "gui.odin";

main :: proc() {
	//
	resx, resy := 1600, 900;
	window := glfw.init_helper(resx, resy, "odin-gui", 3, 3, 0, true);

	//
	glfw.SetCharCallback(window, char_callback);
	glfw.SetKeyCallback(window, key_callback);
	glfw.SetMouseButtonCallback(window, button_callback);
	glfw.SetCursorPosCallback(window, mouse_callback);
	glfw.SetScrollCallback(window, mousewheel_callback);

	// 
	gl.load_up_to(3, 3, proc(p: rawptr, name: string) do (cast(^rawptr)p)^ = rawptr(glfw.GetProcAddress(&name[0])); );

	// 
	program, shader_success := gl.load_shaders("shaders/shader_main.vs", "shaders/shader_main.fs");
	defer gl.DeleteProgram(program);

	// 
	vao: u32;
	gl.GenVertexArrays(1, &vao);
	defer gl.DeleteVertexArrays(1, &vao);

	//
	uniforms := gl.get_uniforms_from_program(program);
	defer for name, uniform in uniforms do free(uniform.name);

	//
	docks := &gui.docks;
	root := gui.append_return(docks);
	root.size, root.name, root.status = gui.Vec2{f32(resx), f32(resy)}, "Root", gui.Dock_Status.DOCKED;

	gui.split_dock(docks, "Root",  "Menu",     "Temp",        gui.Dock_Split.HORIZONTAL, 0.10);
	gui.split_dock(docks, "Temp",  "Toolbar",  "Temp2",       gui.Dock_Split.HORIZONTAL, 0.05);
	gui.split_dock(docks, "Temp2", "Temp3",    "Statusbar",   gui.Dock_Split.HORIZONTAL, 0.95);
	gui.split_dock(docks, "Temp3", "Temp4",    "Right",       gui.Dock_Split.VERTICAL,   0.5);
	gui.split_dock(docks, "Temp4", "Left_Top", "Left_Bottom", gui.Dock_Split.HORIZONTAL, 0.7);

	//gui.make_menu(docks, "Menu");
	//gui.make_toolbar(docks, "Toolbar");
	//gui.make_statusbar(docks, "Statusbar");



	state_right, state_menu, state_toolbar, state_left_top, state_left_bottom, state_statusbar: bool;

	// 
	gl.ClearColor(0.0, 0.0, 0.0, 1.0);
	for !glfw.WindowShouldClose(window) {
		//
		glfw.PollEvents();
		if glfw.GetKey(window, glfw.KEY_ESCAPE) do glfw.SetWindowShouldClose(window, true);

		//
		gui.newframe();

		/*
		if gui.begin_dock("Right") {
			gui.button("Right 1", &state_right);
			gui.end_dock();
		}

		if gui.begin_dock("Menu") {
			gui.button("1 Menu", &state_menu);
			gui.end_dock();
		}

		if gui.begin_dock("Toolbar") {
			gui.button("Menu Button", &state_toolbar);
			gui.end_dock();
		}

		if gui.begin_dock("Left_Top") {
			gui.button("Left_Top first", &state_left_top);
			gui.end_dock();
		}

		if gui.begin_dock("Left_Bottom") {
			gui.button("Left_Botton 1", &state_left_bottom);
			gui.end_dock();
		}

		if gui.begin_dock("Statusbar") {
			gui.button("Statusbar 1", &state_statusbar);
			gui.end_dock();
		}

		gui.endframe();

		*/

		//
		glfw.SetWindowTitle(window, "docks = %d, hot = %p, active = %p, mouse0 = %v", len(docks), cast(rawptr)gui.hot_ptr, cast(rawptr)gui.active_ptr, gui.input.buttons[0]);

		//
		gl.Clear(gl.COLOR_BUFFER_BIT);

		//
		gl.BindVertexArray(vao);
		gl.UseProgram(program);
		gl.Uniform2f(uniforms["resolution"].location, f32(resx), f32(resy));

		//
		for _, i in gui.drawlists {
			// one "draw list" per dock, in addition to a final one for separators
			using list := gui.drawlists[i];

			for _, j in items {
				// each "draw list" has a clipping rect and a list of "items" to be drawn
				using item := &items[j];
				using gui.Draw_Item_Kind;

				// color
				col: gui.Vec4;
				switch kind {
				case Dock:
					col = gui.Vec4{39/255.0, 40/255.0, 34/255.0, 1.0};
				case Dock_Hot:
					col = gui.Vec4{65/255.0, 66/255.0, 61/255.0, 1.0};
				case Dock_Active:
					col = gui.Vec4{85/255.0, 86/255.0, 81/255.0, 1.0};
				case Button:
					col = gui.Vec4{0.35, 0.35, 0.8, 1.0};
				case Button_Hot:
					col = gui.Vec4{0.55, 0.55, 0.9, 1.0};
				case Button_Active:
					col = gui.Vec4{0.95, 0.55, 0.55, 1.0};
				case Separator:
					col = gui.Vec4{0.1, 0.1, 0.1, 1.0};
				case Separator_Hot:
					col = gui.Vec4{0.4, 0.1, 0.1, 1.0};
				case Separator_Active:
					col = gui.Vec4{0.7, 0.1, 0.1, 1.0};
				case Invalid:
					fallthrough;
				case:
					col = gui.Vec4{1.0, 0.5, 1.0, 1.0};
				}
				gl.Uniform4f(uniforms["in_color"].location, col.x, col.y, col.z, col.w);
				
				// draw
				switch t in data {
				case gui.Rect:
					using rect := data.(gui.Rect);
					gl.Uniform2f(uniforms["anchor"].location, xy.x, xy.y);
					gl.Uniform2f(uniforms["size"].location, wh.x, wh.y);

					gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, 1);
				}
			}
		}
		
		glfw.SwapBuffers(window);
	}
}


// callbacks
char_callback :: proc"c"(window: glfw.Window_Handle, c: u32) {
	append(&gui.input.input_runes, rune(c));
}

key_callback :: proc"c"(window: glfw.Window_Handle, key, scancode, action, mods: i32) {
	if action == glfw.REPEAT do return;
	using gui;
	using input;
	using Input_State;
	
	// calc new state based on old state
	old_state := Input_State(keys[key] & DOWN);
	new_state := Input_State(action);
	keys[key] = new_state | ( (old_state != new_state ? 1 : 0) << 1 );

	// double tap
	current_time := f32(glfw.GetTime());
	last_time := keys_clicked_time[key];
	if ((keys[key] & 3) == 3 && current_time - last_time < double_click_time) {
		keys[key] |= Input_State(4);
	} else {
		keys[key] &= ~Input_State(4);
	}

	if ((keys[key]&PRESS) == PRESS) {
		keys_clicked_time[key] = current_time;
	}

	fmt.printf("key = %d = %v\n", key, keys[key]);
}

button_callback :: proc"c"(window: glfw.Window_Handle, button_, action, mods: i32) {
	using gui;
	using input;
	using Input_State;

	old_state := Input_State(buttons[button_] & 1);
	new_state := Input_State(action & 1);
	buttons[button_] = new_state | ( (old_state != new_state ? 1 : 0) << 1 );

	// double tap
	current_time := f32(glfw.GetTime());
	last_time := buttons_clicked_time[button_];
	if ((buttons[button_] & 3) == 3 && current_time - last_time < double_click_time && math.length(mouse_position - mouse_position_click[button_]) < double_click_deadzone) {
		buttons[button_] |= Input_State(4);
		buttons_clicked_time[button_] = -100000.0;
	} else {
		buttons[button_] &= ~Input_State(4);
	}

	if ((buttons[button_]) == PRESS) {
		buttons_clicked_time[button_] = current_time;

		mouse_position_click[button_] = mouse_position;
	}

	fmt.printf("button = %d = %v,  %v %v\n", button_, buttons[button_], old_state, new_state);
}

mouse_callback :: proc"c"(window: glfw.Window_Handle, xpos, ypos: f64) {
	using gui;
	using gui.input;

	mouse_position_prev = mouse_position;
	mouse_position = Vec2{f32(xpos), f32(ypos)};
	mouse_position_delta = mouse_position - mouse_position_prev;
}

mousewheel_callback :: proc"c"(window: glfw.Window_Handle, dx, dy: f64) {
	using gui.input;
	mousewheel_prev = mousewheel;
	mousewheel += f32(dy);
	mousewheel_delta = f32(dy);
}
