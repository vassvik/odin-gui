import "core:fmt.odin"

// general purpose stuff
Vec2 :: [2]f32;
Vec4 :: [4]f32;

C64_colors := [16]Vec4{
	Vec4{  0.0/255.0,   0.0/255.0,   0.0/255.0, 1.0},
	Vec4{255.0/255.0, 255.0/255.0, 255.0/255.0, 1.0},
	Vec4{136.0/255.0,   0.0/255.0,   0.0/255.0, 1.0},
	Vec4{170.0/255.0, 255.0/255.0, 238.0/255.0, 1.0},
	Vec4{204.0/255.0,  68.0/255.0, 204.0/255.0, 1.0},
	Vec4{  0.0/255.0, 204.0/255.0,  85.0/255.0, 1.0},
	Vec4{  0.0/255.0,   0.0/255.0, 170.0/255.0, 1.0},
	Vec4{238.0/255.0, 238.0/255.0, 119.0/255.0, 1.0},
	Vec4{221.0/255.0, 136.0/255.0,  85.0/255.0, 1.0},
	Vec4{102.0/255.0,  68.0/255.0,   0.0/255.0, 1.0},
	Vec4{255.0/255.0, 119.0/255.0, 119.0/255.0, 1.0},
	Vec4{ 51.0/255.0,  51.0/255.0,  51.0/255.0, 1.0},
	Vec4{119.0/255.0, 119.0/255.0, 119.0/255.0, 1.0},
	Vec4{170.0/255.0, 255.0/255.0, 102.0/255.0, 1.0},
	Vec4{  0.0/255.0, 136.0/255.0, 255.0/255.0, 1.0},
	Vec4{187.0/255.0, 187.0/255.0, 187.0/255.0, 1.0},
};

Rect :: struct {
	xy: Vec2,
	wh: Vec2,
}

inside_rect :: proc(using rect: Rect, p: Vec2, pad := f32(0.0)) -> bool {
	return p.x >= xy.x + pad && p.x < xy.x + wh.x - pad && p.y >= xy.y + pad && p.y < xy.y + wh.y - pad;
}

handle_hover :: proc(anchor, size, position: Vec2) -> int {
	w := f32(50.0);

	mid := anchor + size/2.0;

	if        inside_rect(Rect{mid + w*Vec2{-0.50, -0.50}, w*Vec2{1.0, 1.0}}, position) {
		return 0; // middle
	} else if inside_rect(Rect{mid + w*Vec2{-1.25, -0.50}, w*Vec2{0.5, 1.0}}, position) {
		return 1; // left
	} else if inside_rect(Rect{mid + w*Vec2{+0.75, -0.50}, w*Vec2{0.5, 1.0}}, position) {
		return 2; // right
	} else if inside_rect(Rect{mid + w*Vec2{-0.50, +0.75}, w*Vec2{1.0, 0.5}}, position) {
		return 3; // down
	} else if inside_rect(Rect{mid + w*Vec2{-0.50, -1.25}, w*Vec2{1.0, 0.5}}, position) {
		return 4; // up
	}

	return -1;
}

handle_hover_root :: proc(anchor, size, position: Vec2) -> int {
	w := f32(70.0);

	mid := anchor + size/2.0;

	 if       inside_rect(Rect{anchor + size*Vec2{0.0, 0.5} + w*Vec2{+0.5, -0.5}, w*Vec2{0.5, 1.0}}, position) {
		return 1; // left
	} else if inside_rect(Rect{anchor + size*Vec2{1.0, 0.5} + w*Vec2{-1.0, -0.5}, w*Vec2{0.5, 1.0}}, position) {
		return 2; // right
	} else if inside_rect(Rect{anchor + size*Vec2{0.5, 1.0} + w*Vec2{-0.5, -1.0}, w*Vec2{1.0, 0.5}}, position) {
		return 3; // down
	} else if inside_rect(Rect{anchor + size*Vec2{0.5, 0.0} + w*Vec2{-0.5, +0.5}, w*Vec2{1.0, 0.5}}, position) {
		return 4; // up
	}

	return -1;
}





append_return :: proc(arr: ^[dynamic]^$T) -> ^T {
	l := append(arr, new(T));
	return arr[l-1];
}


// docks
Dock_Slot :: enum #export {
	
	MENU,
	TASKBAR,
	STATUSBAR,
	
	POPUP,

	ROOT,

	LEFT,
	RIGHT,
	TOP,
	BOTTOM,

	TAB,

	FLOAT,
};

Dock_Status :: enum #export {
	DOCKED,
	FLOATING,
	DRAGGED,
};

Dock_Split :: enum #export {
	VERTICAL,
	HORIZONTAL,
};

Dock :: struct {
	size: Vec2,
	anchor: Vec2,

	name: string,

	active := true,
	opened := true,

	slot := Dock_Slot.FLOAT,
	status := Dock_Status.FLOATING,

	prev_tab, next_tab: ^Dock,
	child1, child2: ^Dock,
	parent: ^Dock,

	time_clicked := -1.0,

	widgets: [dynamic]Widget,
};

Widget_Kind :: enum {
	CHECKBOX,
	TEXT,
	TEXT_INPUT,
	RADIO,
	SLIDER,
	DRAG,
	BUTTON,
	
	FRAMEBUFFER,

	COMBO,

	MENU_ENTRY,
	MENU_ITEM,

	Tooltip,
}

Widget_Button :: struct {
	text: string,
	rect: Rect,
	state: bool,
}

Widget_Text :: struct {
	text: string,
	rect: Rect,
}

Widget_Checkbox :: struct {
	rect: Rect,
	state: bool
}

Widget_Data :: union {
	Widget_Button,
	Widget_Text,
	Widget_Checkbox,
}

Widget :: struct {
	kind: Widget_Kind,
	data: Widget_Data,
}


widget_text :: proc(fmt: string, args: ...any) {
	assert(current_dock != nil, "No dock opened.");
	using current_dock;
	
	append(&widgets, Widget{Widget_Kind.TEXT, Widget_Text{}});
}

widget_button :: proc(str: string) -> bool {
	assert(current_dock != nil, "No dock opened.");	
	using current_dock;

	append(&widgets, Widget{Widget_Kind.BUTTON, Widget_Button{}});

	return false;
}

widget_checkbox :: proc(state: ^bool) {
	assert(current_dock != nil, "No dock opened.");
	using current_dock;

	append(&widgets, Widget{Widget_Kind.CHECKBOX, Widget_Checkbox{}});
}


Draw_Data :: union {
	Rect,
	string,
	// possibly more
}

Draw_Item_Kind :: enum {
	// usage hint: what kind of widget does it come from
	Invalid,
	Dock,
	Dock_Hot,
	Dock_Active,
	Button,
	Button_Hot,
	Button_Active,
	Separator,
	Separator_Hot,
	Separator_Active,
}

Draw_Item :: struct {
	kind: Draw_Item_Kind,
	data: Draw_Data,
}

Draw_List :: struct {
	items: [dynamic]Draw_Item,
	from_dock: ^Dock,
	clip_rect: Rect,
}

// globals
docks: [dynamic]^Dock;
window_size: [2]int;

show_menu := true;
show_toolbar := true;
show_statusbar := true;


hot_dock: ^Dock = nil;
active_dock: ^Dock = nil;


drawlists: [dynamic]^Draw_List;


current_dock: ^Dock = nil;
current_list: ^Draw_List = nil;
current_position: Vec2;

hot_ptr: uintptr;
active_ptr: uintptr;


sep_width := f32(5.0);



// dock setup stuff
find_dock_in_docks :: proc(docks: ^[dynamic]^Dock, name: string) -> (^Dock) {
	for _, i in docks {
		if docks[i].name == name {
			return docks[i];
		}
	}
	return nil;
}

split_dock :: proc(docks: ^[dynamic]^Dock, name_parent, name_child1, name_child2: string, split_mode: Dock_Split, split_at: f32 = 0.5) {
	using dock := find_dock_in_docks(docks, name_parent); // return ^Dock
	if dock == nil do return;

	c1 := append_return(docks);
	c2 := append_return(docks);

	switch split_mode {
	case Dock_Split.HORIZONTAL:
		c1.size, c1.anchor, c1.slot = size*Vec2{1, split_at},   anchor,                          Dock_Slot.TOP;
		c2.size, c2.anchor, c2.slot = size*Vec2{1, 1-split_at}, anchor + Vec2{0, split_at}*size, Dock_Slot.BOTTOM;
	case Dock_Split.VERTICAL:
		c1.size, c1.anchor, c1.slot = size*Vec2{split_at, 1},    anchor,                          Dock_Slot.LEFT;
		c2.size, c2.anchor, c2.slot = size*Vec2{1-split_at, 1},  anchor + Vec2{split_at, 0}*size, Dock_Slot.RIGHT;
	}
	
	c1.status, c1.name, c1.parent = Dock_Status.DOCKED, name_child1, dock;
	c2.status, c2.name, c2.parent = Dock_Status.DOCKED, name_child2, dock;
	child1, child2 = c1, c2;
	
	active = false;
}

resize_proportionally :: proc(using dock: ^Dock, split_at: f32) {
	
	if child1 == nil || child2 == nil do return;
	

	child1_split_at, child2_split_at: f32 = -1.0, -1.0;
	if child1.child1 != nil && child1.child2 != nil {
		if child1.child1.slot == Dock_Slot.TOP {
			child1_split_at = child1.child1.size.y/(child1.child1.size.y+child1.child2.size.y);
		} else {
			child1_split_at = child1.child1.size.x/(child1.child1.size.x+child1.child2.size.x);
		}
	}
	if child2.child1 != nil && child2.child2 != nil {
		if child2.child1.slot == Dock_Slot.TOP {
			child2_split_at = child2.child1.size.y/(child2.child1.size.y+child2.child2.size.y);
		} else {
			child2_split_at = child2.child1.size.x/(child2.child1.size.x+child2.child2.size.x);
		}
	}

	if child1.slot == Dock_Slot.TOP {
		child1.size, child1.anchor = size*Vec2{1, split_at},   anchor;
		child2.size, child2.anchor = size*Vec2{1, 1-split_at}, anchor + Vec2{0, split_at}*size;
	} else {
		child1.size, child1.anchor = size*Vec2{split_at, 1},    anchor;
		child2.size, child2.anchor = size*Vec2{1-split_at, 1},  anchor + Vec2{split_at, 0}*size;
	}
	
	if child1_split_at != -1.0 do resize_proportionally(child1, clamp(child1_split_at, 0.01, 0.99));
	if child2_split_at != -1.0 do resize_proportionally(child2, clamp(child2_split_at, 0.01, 0.99));
}

add_tab :: proc(docks: ^[dynamic]^Dock, name_parent, name_tab: string) {
}

// 
newframe :: proc() {
	using Draw_Item_Kind;

	// check for hot dock
	hot_dock = nil;
	for _, i in docks {
		using dock := docks[i];

		// skip if it's not an active dock, or if it's not a leaf dock
		if !(active && child1 == nil && child2 == nil) do continue;

		// skip if docks is not hovered by mouse
		hit := inside_rect(Rect{anchor, size}, input.mouse_position);
		if !hit do continue;

		// use this dock if no other docks are hot
		if hot_dock == nil  {
			hot_dock = dock;
			continue;
		}

		// skip this non-float dock if there's already a hot non-float dock (guaranteed no overlap)
		if hot_dock.slot != FLOAT && slot != FLOAT do continue;

		// skip this non-float dock if there's already a hot floati dock (float always on top of docked docks)
		if slot != FLOAT && hot_dock.slot == FLOAT do continue;

		// if the previous hot dock was non-float, but this one is float, then swap to this one
		if slot == FLOAT && hot_dock.slot != FLOAT {
			hot_dock = dock;
			continue;
		} 

		// if this float was clicked more recently than the current hot float (it is on top), swap to this one
		if time_clicked > hot_dock.time_clicked {
			hot_dock = dock;
			continue;
		}	

	}

	if (hot_dock != nil && active_dock == nil && input.buttons[0] & Input_State.PRESS == Input_State.PRESS) {
		active_dock = hot_dock;
	}

	if (input.buttons[0]&1 == 0) {
		active_dock = nil;
	}


	for _, i in docks {
		using dock := docks[i];
		opened = false;
		clear(&widgets);
	}

	/*
	hot_ptr = 0;
	if input.buttons[0] & 1 == 0 do active_ptr = 0;

	for _, i in drawlists do free(drawlists[i].items);
	clear(&drawlists);

	current_list = append_return(&drawlists);
	current_list.from_dock = nil;
	for _, i in docks {
		using dock := docks[i];

		if child1 != nil && child2 != nil {
			r: Rect;
			if child1.slot == Dock_Slot.LEFT {
				r = Rect{
					child1.anchor + Vec2{child1.size.x - sep_width/2.0, sep_width/2.0},
					Vec2{sep_width, child1.size.y - sep_width}
				};
			} else {
				r = Rect{
					child1.anchor + Vec2{sep_width/2.0, child1.size.y - sep_width/2.0},
					Vec2{child1.size.x - sep_width, sep_width}
				};
			}

			// input
			inside := inside_rect(r, input.mouse_position);
			if inside {
				if hot_ptr == 0 do hot_ptr = uintptr(child1);

				if active_ptr == 0 && input.buttons[0] & Input_State.PRESS == Input_State.PRESS {
					active_ptr = uintptr(child1);
				}
			}

			if active_ptr == uintptr(child1) {
				dx, dy: f32;
				if child1.slot == Dock_Slot.LEFT {
					dx = cast(f32)input.mouse_position_delta.x;
					r.xy.x += dx;
				} else {
					dy = cast(f32)input.mouse_position_delta.y;
					r.xy.y += dy;
				}
				split_at := child1.slot == Dock_Slot.LEFT ? (child1.size.x + dx)/size.x : (child1.size.y + dy)/size.y;
				resize_proportionally(dock, clamp(split_at, 0.01, 0.99));
			}

			new_state := active_ptr == uintptr(child1) ? Separator_Active : hot_ptr == uintptr(child1) ? Separator_Hot : Separator;
			append(&current_list.items, Draw_Item{new_state, r});
		}
	}
	*/

	current_dock = nil;
	current_list = nil;

}

current_iteration := 0;

endframe :: proc() {
	/*
	first := drawlists[0];
	for _, i in drawlists[1..] {
		drawlists[i] = drawlists[i+1];
	}
	drawlists[len(drawlists)-1] = first;

	*/


	if active_dock != nil && active_dock.slot == FLOAT && active_ptr == 0 {
		if input.buttons[0] & 1 == 1 {
			active_dock.anchor += input.mouse_position_delta;
		}
	}

	if hot_dock != nil {
		if (input.buttons[0] == Input_State.PRESS) {
			hot_dock.time_clicked = f64(current_iteration);
		}
	}


	current_iteration += 1;

	clear(&input.input_runes);

	for _, i in input.buttons {
		input.buttons[i] = Input_State(input.buttons[i] & 1);
	}

	input.mousewheel_delta = 0.0;
	input.mouse_position_delta = Vec2{};
}

import "core:strings.odin"

begin_dock :: proc(search_name: string) -> bool {
	using Draw_Item_Kind;

	assert(current_dock == nil && current_list == nil, "Expected `current_dock == nil` and `current_list == nil`. Did you match a `begin_dock` with a `close_dock`?");
	
	using dock := find_dock_in_docks(&docks, search_name);
	if dock == nil {
		// unknown dock, make a new floating one
		dock = append_return(&docks);

		size = Vec2{f32(window_size[0]), f32(window_size[1])}/2.0;
		anchor = size - size/2.0;
		name = search_name;
		return false;
	}

	if !active do return false;
	opened = true;

	assert(child1 == nil || child2 == nil, "Expected leaf dock");
	
	current_dock = dock;
	
	/*


	current_list = append_return(&drawlists);
	current_list.clip_rect, current_list.from_dock = Rect{dock.anchor, dock.size}, dock;

	current_position = anchor + Vec2{10, 10};

	if inside_rect(Rect{anchor, size}, input.mouse_position, sep_width/2.0) {
		if hot_ptr == 0 do hot_ptr = uintptr(dock);
		if active_ptr == 0 && input.buttons[0] & Input_State.PRESS == Input_State.PRESS {
			active_ptr = uintptr(dock);
		}
	}

	new_state := active_ptr == uintptr(dock) ? Dock_Active : hot_ptr == uintptr(dock) ? Dock_Hot : Dock;
	append(&current_list.items, Draw_Item{new_state, Rect{anchor, size}});
	*/
	return true;
}

end_dock :: proc() {
	current_dock = nil;
	current_list = nil;
}

// widgets
button :: proc(str: string, state: ^bool) {
	using Draw_Item_Kind;
	using input;

	if current_dock == nil || current_list == nil do return;
	using current_list;

	box_size := Vec2{20*f32(len(str)), 20};

	if inside_rect(Rect{current_position, box_size}, mouse_position) {
		hot_ptr = uintptr(state);
		if input.buttons[0] & Input_State.PRESS == Input_State.PRESS {
			active_ptr = uintptr(state);
		}
	}

	new_state := active_ptr == uintptr(state) ? Button_Active : hot_ptr == uintptr(state) ? Button_Hot : Button;
	append(&items, Draw_Item{new_state, Rect{current_position, box_size}});
	current_position += Vec2{0, box_size.y + 5};

	state^ = false;
}




// Input

Input_State :: enum u8 {
	UP = 0b000,
	DOWN = 0b001,
	RELEASE = 0b010,
	PRESS = 0b011,
	DOUBLEPRESS = 0b111,
}

input: struct {
	buttons:                  [5]Input_State,
	buttons_clicked_time:     [5]f32,

	keys:                     [512]Input_State,	
	input_runes:              [dynamic]rune,
	keys_clicked_time:        [512]f32,

	mouse_position:           Vec2,
	mouse_position_prev:      Vec2,
	mouse_position_delta:     Vec2,
	mouse_position_click:     [5]Vec2,

	mousewheel:               f32,
	mousewheel_prev:          f32,
	mousewheel_delta:         f32,

};


double_click_time := f32(0.5);
double_click_deadzone := f32(5.0);
