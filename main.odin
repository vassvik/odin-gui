package main

import	"core:fmt";
import	"core:math";
import	"core:strings";

import	"shared:odin-glfw";
import	"shared:odin-gl";
import font_gl "shared:odin-gl_font";

//using import "shared:random"


pcg32_random_t :: struct {
	state, inc: u64,
};

pcg32_random_r :: proc(rng: ^pcg32_random_t) -> u32 {
    oldstate := rng.state;
    rng.state = oldstate * 6364136223846793005 + (rng.inc|1);
    xorshifted := u32(((oldstate >> 18) ~ oldstate) >> 27);
    rot := u32(oldstate >> 59);
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}

pcg32_srandom_r :: proc(rng: ^pcg32_random_t, initstate, initseq: u64) {
    rng.state = u64(0);
    rng.inc = u64(initseq << 1 | 1); // makes it odd
    pcg32_random_r(rng);
    rng.state += initstate;
    pcg32_random_r(rng);
}

rngf :: proc(rng: ^pcg32_random_t) -> f64 {
    r := pcg32_random_r(rng);
    return f64(r)/f64(0x1_0000_0000);
}


color_passive := Vec4{1.0, 0.0, 0.0, 1.0};
color_active := Vec4{1.0, 0.5, 0.5, 1.0};


append_to_log :: proc(log: ^[dynamic]string, fmt_string: string, vals: ..any) {
	a := fmt.aprintf(fmt_string, ..vals);
	append(log, a);
}
temp_log: [dynamic]string;

main :: proc() {
	//
	window_size = [2]int{1900, 1000};
	window := glfw.init_helper(window_size[0], window_size[1], "odin-gui", 4, 3, 0, true);
	defer glfw.terminate();

	//
	glfw.set_window_size_callback(window, windowsize_callback);
	glfw.set_char_callback(window, char_callback);
	glfw.set_key_callback(window, key_callback);
	glfw.set_mouse_button_callback(window, button_callback);
	glfw.set_cursor_pos_callback(window, mouse_callback);
	glfw.set_scroll_callback(window, mousewheel_callback);

	// 
	gl.load_up_to(4, 3, glfw.set_proc_address);

	//
	sizes := [?]int{72, 68, 64, 60, 56, 52, 48, 44, 40, 36, 32, 28, 24, 20, 16, 12};
	codepoints: [95]rune;
	for i in 0..95-1 do codepoints[i] = rune(32+i);
	
	//font, success_font := font_gl.init_from_ttf_gl("C:/windows/fonts/consola.ttf", "Consola", false, sizes[:], codepoints[:]);
	font, success_font := font_gl.init_from_ttf_gl("consola.ttf", "Consola", false, sizes[:], codepoints[:]);
	if !success_font {
		return;
	}
	defer font_gl.destroy_gl(font);

	// 
	program, shader_success := gl.load_shaders("shaders/shader_main.vs", "shaders/shader_main.fs");
	defer gl.DeleteProgram(program);

	//
	uniforms := gl.get_uniforms_from_program(program);
	defer for name, uniform in uniforms do delete(uniform.name);

	// 
	vao: u32;
	gl.GenVertexArrays(1, &vao);
	defer gl.DeleteVertexArrays(1, &vao);


	//
	{
		using root := append_return(&docks);
		active, opened, slot, time_clicked, clicked_at = true, true, Dock_Slot.FLOAT, -1.0, Vec2{};
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
	for !glfw.window_should_close(window) {
		// 
		for _, i in temp_log do delete(temp_log[i]);
		clear(&temp_log);

		//
		glfw.poll_events();
		if glfw.get_key(window, glfw.KEY_ESCAPE) do glfw.set_window_should_close(window, true);

		if input.keys[glfw.KEY_SPACE] == Input_State.PRESS do reset();

		//
		newframe();

		if begin_dock("Test") {
			text("blah");
			checkbox(&checkbox_state1);
			text("bleh");
			end_dock();
		}

		if begin_dock("Test2") {
			text("blah");
			checkbox(&checkbox_state2);
			text("bleh");
			end_dock();
		}

		if begin_dock("Test3") {
			text("blah");
			checkbox(&checkbox_state2);
			text("bleh");
			end_dock();
		}

		if begin_dock("Test4") {
			text("blah");
			checkbox(&checkbox_state2);
			text("bleh");
			end_dock();
		}

		if begin_dock("Test5") {
			text("blah");
			checkbox(&checkbox_state2);
			text("bleh");
			end_dock();
		}

		if begin_dock("Foo") { 
			button("bleh");
			text("bleh");
			text("bleh");
			text("bleh");
			end_dock();
		}

		if begin_dock("Bar") {
			text("bleh");
			button("blarh");
			end_dock();
		}

		if begin_dock("Baz") {
			button("blarh");
			end_dock();
		}

		endframe();

		//
		gl.Clear(gl.COLOR_BUFFER_BIT);
		gl.Viewport(0, 0, cast(i32)window_size[0], cast(i32)window_size[1]);

		//
		gl.BindVertexArray(vao);
		gl.UseProgram(program);
		gl.Uniform2f(uniforms["resolution"].location, f32(window_size[0]), f32(window_size[1]));

		// print debug info to log
		append_to_log(&temp_log, "window size = %v", window_size);
		append_to_log(&temp_log, "");

		append_to_log(&temp_log, "hot dock = %s, active dock = %s", hot_dock != nil ? hot_dock.name : "nil", active_dock != nil ? active_dock.name : "nil");
		//append_to_log(&temp_log, "show menu = %v", show_menu);
		//append_to_log(&temp_log, "show toolbar = %v", show_toolbar);
		//append_to_log(&temp_log, "show statusbar = %v", show_statusbar);
		//append_to_log(&temp_log, "%d docks", len(docks));
		append_to_log(&temp_log, "");

		for _, i in docks {
			using dock := docks[i];
			append_to_log(&temp_log, "dock[%d] = Dock { name = \"%s\", size = %v, anchor = %v, active = %v, opened = %v, slot = %v, parent = '%s', child1 = '%s', child2 = '%s', prev_tab = '%s', next_tab = '%s', num widgets = %d, clicked_at = %v }", i, name, size, anchor, active, opened, slot, parent == nil ? "nil" : parent.name, child1 == nil ? "nil" : child1.name, child2 == nil ? "nil" : child2.name, prev_tab == nil ? "nil" : prev_tab.name, next_tab == nil ? "nil" : next_tab.name, len(widgets), clicked_at);
		}

		// draw each dock
		dynamic_docks: [dynamic]^Dock;
		defer delete(dynamic_docks);

		pcg32_srandom_r(&rng, 42, 42);
		for _, i in docks {
			using dock := docks[i];

			// save floating docks for sorting
			if dock.slot == FLOAT {
				append(&dynamic_docks, dock);
				continue;
			}

			if child1 != nil || child2 != nil do continue;
			if name == "Root" do continue;
			if !active do continue;

			col := Vec4{cast(f32)rngf(&rng), cast(f32)rngf(&rng), cast(f32)rngf(&rng), 1.0};
			//col = C64_colors[(i%14)+2];
			if dock == hot_dock do col.x, col.y, col.z = 0 - col.x, 1.0 - col.y, 1.0 - col.z;
			draw_quad(&uniforms, anchor, size, col);

			// draw tabs
			start_tab := dock;
			for start_tab.prev_tab != nil do start_tab = start_tab.prev_tab;
			
			at_x := f32(5.0);
			for start_tab != nil {
				col := !inside_rect(Rect{anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}}, input.mouse_position) ? Vec4{1.0, 0.7, 0.4, 1.0} : Vec4{0.4, 0.7, 1.0, 1.0};
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

			col := Vec4{cast(f32)rngf(&rng), cast(f32)rngf(&rng), cast(f32)rngf(&rng), 1.0};
			//col = C64_colors[(i%14)+2];
			if dock == hot_dock do col.x, col.y, col.z = 0 - col.x, 1.0 - col.y, 1.0 - col.z;
				
			draw_quad(&uniforms, anchor, size, col);

			// draw tabs
			start_tab := dock;
			for start_tab.prev_tab != nil do start_tab = start_tab.prev_tab;
			
			at_x := f32(5.0);
			for start_tab != nil {
				col := !inside_rect(Rect{anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}}, input.mouse_position) ? Vec4{1.0, 0.7, 0.4, 1.0} : Vec4{0.4, 0.7, 1.0, 1.0};
				draw_quad(&uniforms, anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}, col);
				at_x += 55.0;
				start_tab = start_tab.next_tab;
			}
		}


		if active_dock != nil && active_dock.slot == FLOAT {
			// handle and draw hover overlay for the current hovered dock by the active floating dock
			for _, i in docks {	
				using dock := docks[i];

				if !active || !opened || slot == FLOAT do continue;
				if !inside_rect(Rect{anchor, size}, input.mouse_position) do continue;

				which := handle_hover(anchor, size, input.mouse_position);

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
			using dock := docks[0];

			which := handle_hover_root(anchor, size, input.mouse_position);

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
		glfw.swap_buffers(window);
	}
}


draw_quad :: proc(uniforms: ^gl.Uniforms, anchor, size: Vec2, color: Vec4) {
	gl.Uniform4fv(uniforms["in_color"].location, 1, &color[0]);
	gl.Uniform2fv(uniforms["anchor"].location, 1, &anchor.x);
	gl.Uniform2fv(uniforms["size"].location, 1, &size.x);
	gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, 1);
}

// callbacks
windowsize_callback :: proc"c"(window: glfw.Window_Handle, width, height: i32) {
	fmt.println(width, height);
	window_size = [2]int{int(width), int(height)};
}

char_callback :: proc"c"(window: glfw.Window_Handle, c: u32) {
	append(&input.input_runes, rune(c));
}

key_callback :: proc"c"(window: glfw.Window_Handle, key, scancode, action, mods: i32) {
	if key < 0 || key >= 512 do return;
	if action == cast(i32)glfw.REPEAT do return;
	using input;
	using Input_State;
	
	// calc new state based on old state
	old_state := Input_State(keys[key] & DOWN);
	new_state := Input_State(action);
	keys[key] = new_state | Input_State( (old_state != new_state ? 1 : 0) << 1 );

	// double tap
	current_time := f32(glfw.get_time());
	last_time := keys_clicked_time[key];
	if ((keys[key] & Input_State(3)) == Input_State(3) && current_time - last_time < double_click_time) {
		keys[key] |= Input_State(4);
		keys_clicked_time[key] = -100000.0;
	} else {
		keys[key] = Input_State(u8(keys[key]) & ~u8(4));
	}

	if (keys[key] == PRESS) {
		keys_clicked_time[key] = current_time;
	}

	if key >= cast(i32)glfw.KEY_LEFT_SHIFT && key <= cast(i32)glfw.KEY_RIGHT_SUPER {
	 	modifiers[key - cast(i32)glfw.KEY_LEFT_SHIFT] = bool(new_state);
	}

	fmt.printf("key = %d = %v\n", key, keys[key]);
}

button_callback :: proc"c"(window: glfw.Window_Handle, button_, action, mods: i32) {
    using input;
    using Input_State;

    old_state := Input_State(u8(buttons[button_]) & 1);
    new_state := Input_State(action & 1);
    buttons[button_] = Input_State(u8(new_state) | ( (old_state != new_state ? 1 : 0) << 1 ));

    // double tap
    current_time := f32(glfw.get_time());
    last_time := buttons_clicked_time[button_];
    if ((u8(buttons[button_]) & 3) == 3 && current_time - last_time < double_click_time && math.length(mouse_position - mouse_position_click[button_]) < double_click_deadzone) {
        buttons[button_] = Input_State(int(buttons[button_]) | int(Input_State(4)));
        buttons_clicked_time[button_] = -100000.0;
    } else {
        buttons[button_] = Input_State(u8(buttons[button_]) & ~u8(Input_State(4)));
    }

    if (buttons[button_] == PRESS) {
        buttons_clicked_time[button_] = current_time;

        mouse_position_click[button_] = mouse_position;
    }

    //fmt.printf("button = %d = %v,  %v %v\n", button_, buttons[button_], old_state, new_state);
}

mouse_callback :: proc"c"(window: glfw.Window_Handle, xpos, ypos: f64) {
	using input;
	mouse_position_prev = mouse_position;
	mouse_position = Vec2{f32(xpos), f32(ypos)};
	mouse_position_delta = mouse_position - mouse_position_prev;
}

mousewheel_callback :: proc"c"(window: glfw.Window_Handle, dx, dy: f64) {
	using input;
	mousewheel_prev = mousewheel;
	mousewheel += f32(dy);
	mousewheel_delta = f32(dy);
}
