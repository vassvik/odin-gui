import	"core:fmt.odin";
import	"core:math.odin";
import	"core:strings.odin";

import	"shared:odin-glfw/glfw.odin";
import	"shared:odin-gl/gl.odin";
import font_gl "shared:odin-gl_font/font_opengl.odin";

using import "shared:random.odin"

import gui "gui.odin";


Vec2 :: #type_alias gui.Vec2;
Vec4 :: #type_alias gui.Vec4;

color_passive := gui.Vec4{1.0, 0.0, 0.0, 1.0};
color_active := gui.Vec4{1.0, 0.5, 0.5, 1.0};


append_to_log :: proc(log: ^[dynamic]string, fmt_string: string, vals: ...any) {
	a := fmt.aprintf(fmt_string, ...vals);
	append(log, a);
}
temp_log: [dynamic]string;

main :: proc() {
	//
	gui.window_size = [2]int{1700, 900};
	window := glfw.init_helper(gui.window_size[0], gui.window_size[1], "odin-gui", 4, 5, 0, true);
	defer glfw.Terminate();

	a := 3.14;
	fmt.println("3.14 as int:", (cast(^int)&a)^);

	//
	glfw.SetWindowSizeCallback(window, windowsize_callback);
	glfw.SetCharCallback(window, char_callback);
	glfw.SetKeyCallback(window, key_callback);
	glfw.SetMouseButtonCallback(window, button_callback);
	glfw.SetCursorPosCallback(window, mouse_callback);
	glfw.SetScrollCallback(window, mousewheel_callback);

	// 
	gl.load_up_to(4, 5, proc(p: rawptr, name: string) do (cast(^rawptr)p)^ = glfw.GetProcAddress(&name[0]); );

	//
	sizes := [...]int{72, 68, 64, 60, 56, 52, 48, 44, 40, 36, 32, 28, 24, 20, 16, 12};
	codepoints: [95]rune;
	for i in 0..95 do codepoints[i] = rune(32+i);
	
	font, success_font := font_gl.init_from_ttf_gl("C:/windows/fonts/consola.ttf", "Consola", false, sizes[...], codepoints[...]);
	if !success_font {
		return;
	}
	defer font_gl.destroy_gl(font);

	// 
	program, shader_success := gl.load_shaders("shaders/shader_main.vs", "shaders/shader_main.fs");
	defer gl.DeleteProgram(program);

	//
	uniforms := gl.get_uniforms_from_program(program);
	defer for name, uniform in uniforms do free(uniform.name);

	// 
	vao: u32;
	gl.GenVertexArrays(1, &vao);
	defer gl.DeleteVertexArrays(1, &vao);

	//
	{
		using gui;
		using root := append_return(&docks);
		size, name, slot  = Vec2{f32(window_size[0]), f32(window_size[1])}, "Root", ROOT;

		//split_dock(&docks, "Root", "Temp", "Foo", VERTICAL, 0.50);
		//split_dock(&docks, "Temp", "Bar",  "Baz", HORIZONTAL,   0.6);
	}

	checkbox_state1, checkbox_state2: bool;

    rng: pcg32_random_t;

	font_gl.colors[0] = font_gl.Vec4{0, 0, 0, 1}; // black
	font_gl.colors[1] = font_gl.Vec4{1, 1, 1, 1}; // white
	font_gl.colors[2] = font_gl.Vec4{1, 0, 0, 1}; // blue/function names
	font_gl.colors[3] = font_gl.Vec4{0, 1, 0, 1}; // purple/numbers
	font_gl.colors[4] = font_gl.Vec4{0, 0, 1, 1}; // yellow/strings
	font_gl.update_colors(0, 5);

	// 
	gl.ClearColor(1.0, 1.0, 1.0, 1.0);
	for !glfw.WindowShouldClose(window) {
		// 
		for _, i in temp_log do free(temp_log[i]);
		clear(&temp_log);

		//
		glfw.PollEvents();
		if glfw.GetKey(window, glfw.KEY_ESCAPE) do glfw.SetWindowShouldClose(window, true);

		if gui.input.keys[glfw.KEY_SPACE] == gui.Input_State.PRESS do gui.reset();

		//
		gui.newframe();

		if gui.begin_dock("Test") {
			gui.text("blah");
			gui.checkbox(&checkbox_state1);
			gui.text("bleh");
			gui.end_dock();
		}

		if gui.begin_dock("Test2") {
			gui.text("blah");
			gui.checkbox(&checkbox_state2);
			gui.text("bleh");
			gui.end_dock();
		}

		if gui.begin_dock("Test3") {
			gui.text("blah");
			gui.checkbox(&checkbox_state2);
			gui.text("bleh");
			gui.end_dock();
		}

		if gui.begin_dock("Test4") {
			gui.text("blah");
			gui.checkbox(&checkbox_state2);
			gui.text("bleh");
			gui.end_dock();
		}

		if gui.begin_dock("Foo") { 
			gui.button("bleh");
			gui.text("bleh");
			gui.text("bleh");
			gui.text("bleh");
			gui.end_dock();
		}

		if gui.begin_dock("Bar") {
			gui.text("bleh");
			gui.button("blarh");
			gui.end_dock();
		}

		if gui.begin_dock("Baz") {
			gui.button("blarh");
			gui.end_dock();
		}

		gui.endframe();

		//
		gl.Clear(gl.COLOR_BUFFER_BIT);
		gl.Viewport(0, 0, cast(i32)gui.window_size[0], cast(i32)gui.window_size[1]);

		//
		gl.BindVertexArray(vao);
		gl.UseProgram(program);
		gl.Uniform2f(uniforms["resolution"].location, f32(gui.window_size[0]), f32(gui.window_size[1]));

		// print debug info to log
		append_to_log(&temp_log, "window size = %v", gui.window_size);
		append_to_log(&temp_log, "");

		append_to_log(&temp_log, "hot dock = %s, active dock = %s", gui.hot_dock != nil ? gui.hot_dock.name : "nil", gui.active_dock != nil ? gui.active_dock.name : "nil");
		//append_to_log(&temp_log, "show menu = %v", gui.show_menu);
		//append_to_log(&temp_log, "show toolbar = %v", gui.show_toolbar);
		//append_to_log(&temp_log, "show statusbar = %v", gui.show_statusbar);
		//append_to_log(&temp_log, "%d docks", len(gui.docks));
		append_to_log(&temp_log, "");

		for _, i in gui.docks {
			using dock := gui.docks[i];
			append_to_log(&temp_log, "dock[%d] = Dock { name = \"%s\", size = %v, anchor = %v, active = %v, opened = %v, slot = %v, parent = '%s', child1 = '%s', child2 = '%s', prev_tab = '%s', next_tab = '%s', num widgets = %d }", i, name, size, anchor, active, opened, slot, parent == nil ? "nil" : parent.name, child1 == nil ? "nil" : child1.name, child2 == nil ? "nil" : child2.name, prev_tab == nil ? "nil" : prev_tab.name, next_tab == nil ? "nil" : next_tab.name, len(widgets));
		}

		// draw each dock
		dynamic_docks: [dynamic]^gui.Dock;
		defer free(dynamic_docks);

		pcg32_srandom_r(&rng, 42, 42);
		for _, i in gui.docks {
			using dock := gui.docks[i];

			// save floating docks for sorting
			if dock.slot == gui.FLOAT {
				append(&dynamic_docks, dock);
				continue;
			}

			if child1 != nil || child2 != nil do continue;
			if name == "Root" do continue;
			if !active do continue;

			col := gui.Vec4{cast(f32)rngf(&rng), cast(f32)rngf(&rng), cast(f32)rngf(&rng), 1.0};
			//col = gui.C64_colors[(i%14)+2];
			if dock == gui.hot_dock do col.x, col.y, col.z = 0 - col.x, 1.0 - col.y, 1.0 - col.z;
			draw_quad(&uniforms, anchor, size, col);

			// draw tabs
			start_tab := dock;
			for start_tab.prev_tab != nil do start_tab = start_tab.prev_tab;
			
			at_x := f32(5.0);
			for start_tab != nil {
				col := !gui.inside_rect(gui.Rect{anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}}, gui.input.mouse_position) ? Vec4{1.0, 0.7, 0.4, 1.0} : Vec4{0.4, 0.7, 1.0, 1.0};
				if start_tab.active do col = Vec4{0.4, 1.0, 0.7, 1.0};
				draw_quad(&uniforms, anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}, col);
				at_x += 55.0;
				start_tab = start_tab.next_tab;
			}
		}

		// sort by clicked time
		for i := 0; i < len(dynamic_docks)-1; i += 1 {
			max_time := dynamic_docks[i].time_clicked;
			max_at := i;
			for j := i+1; j < len(dynamic_docks); j += 1 {
				if dynamic_docks[j].time_clicked < max_time {
					max_time = dynamic_docks[j].time_clicked;
					max_at = j;
				}
			}

			if max_at != i {
				dynamic_docks[i], dynamic_docks[max_at] = dynamic_docks[max_at], dynamic_docks[i]; 
			}
		}

		// draw floating docks
		for _, i in dynamic_docks {
			using dock := dynamic_docks[i];

			col := gui.Vec4{cast(f32)rngf(&rng), cast(f32)rngf(&rng), cast(f32)rngf(&rng), 1.0};
			//col = gui.C64_colors[(i%14)+2];
			if dock == gui.hot_dock do col.x, col.y, col.z = 0 - col.x, 1.0 - col.y, 1.0 - col.z;
				
			draw_quad(&uniforms, anchor, size, col);

			// draw tabs
			start_tab := dock;
			for start_tab.prev_tab != nil do start_tab = start_tab.prev_tab;
			
			at_x := f32(5.0);
			for start_tab != nil {
				col := !gui.inside_rect(gui.Rect{anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}}, gui.input.mouse_position) ? Vec4{1.0, 0.7, 0.4, 1.0} : Vec4{0.4, 0.7, 1.0, 1.0};
				draw_quad(&uniforms, anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}, col);
				at_x += 55.0;
				start_tab = start_tab.next_tab;
			}
		}


		if gui.active_dock != nil && gui.active_dock.slot == gui.FLOAT {
			// handle and draw hover overlay for the current hovered dock by the active floating dock
			for _, i in gui.docks {	
				using dock := gui.docks[i];

				if !active || !opened || slot == gui.FLOAT do continue;
				if !gui.inside_rect(gui.Rect{anchor, size}, gui.input.mouse_position) do continue;

				which := gui.handle_hover(anchor, size, gui.input.mouse_position);

				w := f32(50.0);
				mid := anchor + size/2.0;
				draw_quad(&uniforms, mid + w*Vec2{-0.50, -0.50}, w*Vec2{1.0, 1.0}, which == 0 ? color_active : color_passive);
				draw_quad(&uniforms, mid + w*Vec2{-1.25, -0.50}, w*Vec2{0.5, 1.0}, which == 1 ? color_active : color_passive);
				draw_quad(&uniforms, mid + w*Vec2{+0.75, -0.50}, w*Vec2{0.5, 1.0}, which == 2 ? color_active : color_passive);
				draw_quad(&uniforms, mid + w*Vec2{-0.50, +0.75}, w*Vec2{1.0, 0.5}, which == 3 ? color_active : color_passive);
				draw_quad(&uniforms, mid + w*Vec2{-0.50, -1.25}, w*Vec2{1.0, 0.5}, which == 4 ? color_active : color_passive);

				break;
			}

			// handle and draw hover overlay for the root dock
			using dock := gui.docks[0];

			which := gui.handle_hover_root(anchor, size, gui.input.mouse_position);

			w := f32(70.0);
			draw_quad(&uniforms, anchor + size*Vec2{0.0, 0.5} + w*Vec2{+0.5, -0.5}, w*Vec2{0.5, 1.0}, which == 1 ? color_active : color_passive);
			draw_quad(&uniforms, anchor + size*Vec2{1.0, 0.5} + w*Vec2{-1.0, -0.5}, w*Vec2{0.5, 1.0}, which == 2 ? color_active : color_passive);
			draw_quad(&uniforms, anchor + size*Vec2{0.5, 1.0} + w*Vec2{-0.5, -1.0}, w*Vec2{1.0, 0.5}, which == 3 ? color_active : color_passive);
			draw_quad(&uniforms, anchor + size*Vec2{0.5, 0.0} + w*Vec2{-0.5, +0.5}, w*Vec2{1.0, 0.5}, which == 4 ? color_active : color_passive);
		}

		//
		font_gl.set_state();
		at := [2]f32{0.0, 1.0};
		for s in temp_log {
			num, dx, dy := font_gl.draw_string(&font, 12, at, 0, s);
			at.y += (s == "" ? 10.0 : dy);
		}

		//
		glfw.SwapBuffers(window);
	}
}


draw_quad :: proc(uniforms: ^map[string]gl.Uniform_Info, anchor, size: gui.Vec2, color: gui.Vec4) {
	gl.Uniform4fv(uniforms["in_color"].location, 1, &color[0]);
	gl.Uniform2fv(uniforms["anchor"].location, 1, &anchor.x);
	gl.Uniform2fv(uniforms["size"].location, 1, &size.x);
	gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, 1);
}

// callbacks
windowsize_callback :: proc"c"(window: glfw.Window_Handle, width, height: i32) {
	fmt.println(width, height);
	gui.window_size = [2]int{int(width), int(height)};
}

char_callback :: proc"c"(window: glfw.Window_Handle, c: u32) {
	append(&gui.input.input_runes, rune(c));
}

key_callback :: proc"c"(window: glfw.Window_Handle, key, scancode, action, mods: i32) {
	if key < 0 || key >= 512 do return;
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
		keys_clicked_time[key] = -100000.0;
	} else {
		keys[key] &= ~Input_State(4);
	}

	if (keys[key] == PRESS) {
		keys_clicked_time[key] = current_time;
	}

	if key >= glfw.KEY_LEFT_SHIFT && key <= glfw.KEY_RIGHT_SUPER do modifiers[key - glfw.KEY_LEFT_SHIFT] = bool(new_state);

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

	if (buttons[button_] == PRESS) {
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
