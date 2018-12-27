package main

import "core:fmt"
import "core:math"

// general purpose stuff
Vec2 :: [2]f32;
Vec4 :: [4]f32;

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
	append(arr, new(T));
	return arr[len(arr)-1];
}


// docks
using Dock_Slot :: enum {
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

	DUMMY,
	SINGLE,
};

Dock :: struct {
	size: Vec2,
	anchor: Vec2,

	name: string,

	active: bool,
	opened: bool,

	slot: Dock_Slot,

	prev_tab, next_tab: ^Dock,
	child1, child2: ^Dock,
	parent: ^Dock,

	time_clicked: f64,
	clicked_at: Vec2,

	widgets: [dynamic]Widget,
};


Button :: struct {
	text: string,
	rect: Rect,
	state: bool,
}

Text :: struct {
	text: string,
	rect: Rect,
}

Checkbox :: struct {
	rect: Rect,
	state: bool
}

Widget :: union {
	Button,
	Text,
	Checkbox,
}



text :: proc(fmt: string, args: ..any) {
	assert(current_dock != nil, "No dock opened.");
	using current_dock;
	
	append(&widgets, Text{});
}

button :: proc(str: string) -> bool {
	assert(current_dock != nil, "No dock opened.");	
	using current_dock;

	append(&widgets, Button{});

	return false;
}

checkbox :: proc(state: ^bool) {
	assert(current_dock != nil, "No dock opened.");
	using current_dock;

	append(&widgets, Checkbox{});
}


// globals
docks: [dynamic]^Dock;
window_size: [2]int;

show_menu := true;
show_toolbar := true;
show_statusbar := true;

hot_dock: ^Dock = nil;
active_dock: ^Dock = nil;

current_dock: ^Dock = nil;
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

insert :: proc(docks: ^[dynamic]^Dock, current_dock: ^Dock, insert_dock: ^Dock, insert_slot: Dock_Slot) {
	insert_dock.active = true;
	current_dock.active = false;

	insert_dock.slot = insert_slot;

	if current_dock.slot == ROOT {
		assert(insert_slot != TAB);

		if current_dock.child1 == nil {
			// no children
			assert(current_dock.child2 == nil);
			
			current_dock.child1 = insert_dock;

			insert_dock.parent = current_dock;
			insert_dock.anchor = current_dock.anchor;
			insert_dock.size = current_dock.size;
			insert_dock.slot = SINGLE;


		} else if current_dock.child2 == nil {
			// one child
			insert_dock.parent = current_dock;

			switch insert_slot {
			case LEFT:
				current_dock.child1, current_dock.child2 = insert_dock, current_dock.child1;
				current_dock.child2.slot = RIGHT;
			case RIGHT:
				current_dock.child1, current_dock.child2 = current_dock.child1, insert_dock;
				current_dock.child1.slot = LEFT;
			case TOP:
				current_dock.child1, current_dock.child2 = insert_dock, current_dock.child1;
				current_dock.child2.slot = BOTTOM;
			case BOTTOM:
				current_dock.child1, current_dock.child2 = current_dock.child1, insert_dock;
				current_dock.child1.slot = TOP;
			case:
				assert(false);
			}

			resize_proportionally(current_dock, insert_slot == LEFT || insert_slot == TOP ? 0.33 : 0.66);
		} else {
			// two children
			new_dock := append_return(docks);
			new_dock.active, new_dock.opened, new_dock.slot, new_dock.time_clicked, new_dock.clicked_at = true, true, Dock_Slot.FLOAT, -1.0, Vec2{};

			new_dock.parent = current_dock;
			new_dock.active = false;
			insert_dock.parent = current_dock;

			new_dock.child1, new_dock.child2 = current_dock.child1, current_dock.child2;
			
			current_dock.child1.parent, current_dock.child2.parent = new_dock, new_dock;

			switch insert_slot {
			case LEFT:
				current_dock.child1, current_dock.child2 = insert_dock, new_dock;
				current_dock.child2.slot = RIGHT;
			case RIGHT:
				current_dock.child1, current_dock.child2 = new_dock, insert_dock;
				current_dock.child1.slot = LEFT;
			case TOP:
				current_dock.child1, current_dock.child2 = insert_dock, new_dock;
				current_dock.child2.slot = BOTTOM;
			case BOTTOM:
				current_dock.child1, current_dock.child2 = new_dock, insert_dock;
				current_dock.child1.slot = TOP;
			case:
				assert(false);
			}

			resize_proportionally(current_dock, insert_slot == LEFT || insert_slot == TOP ? 0.33 : 0.66);
		}
	} else {
		assert(current_dock.child1 == nil && current_dock.child2 == nil);
		
		if insert_slot == TAB {
			if current_dock.next_tab != nil {
				insert_dock.next_tab = current_dock.next_tab;
				current_dock.next_tab.prev_tab = insert_dock;
			} 
			current_dock.next_tab = insert_dock;
			insert_dock.prev_tab = current_dock;
			
			insert_dock.active = true;
			current_dock.active = false;
			insert_dock.anchor = current_dock.anchor;
			insert_dock.size = current_dock.size;
		} else {

			if current_dock.slot == TAB {
				current_dock.active = true;
				for current_dock.prev_tab != nil {
					current_dock = current_dock.prev_tab;
				}
			} else {
				current_dock.active = true;
			}
			new_dock := append_return(docks);
			new_dock.active, new_dock.opened, new_dock.slot, new_dock.time_clicked, new_dock.clicked_at = true, true, Dock_Slot.FLOAT, -1.0, Vec2{};

			new_dock.parent = current_dock.parent;
			new_dock.slot = current_dock.slot;
			new_dock.anchor = current_dock.anchor;
			new_dock.size = current_dock.size;
			new_dock.active = false;

			if current_dock.parent.slot == ROOT && current_dock.parent.child2 == nil && current_dock.parent.child1 != nil {
				current_dock.parent.child1 = new_dock;
				if insert_slot == LEFT || insert_slot == TOP {
					current_dock.slot = insert_slot == LEFT ? RIGHT : BOTTOM;
				} else {
					current_dock.slot = insert_slot == RIGHT ? LEFT : TOP;
				}
			} else {
				if current_dock.slot == LEFT || current_dock.slot == TOP {
					current_dock.parent.child1 = new_dock;
				} else {
					current_dock.parent.child2 = new_dock;
				}
			}

			current_dock.parent = new_dock;
			insert_dock.parent = new_dock;

			switch insert_slot {
			case LEFT:
				new_dock.child1, new_dock.child2 = insert_dock, current_dock;
				new_dock.child2.slot = RIGHT;
			case RIGHT:
				new_dock.child1, new_dock.child2 = current_dock, insert_dock;
				new_dock.child1.slot = LEFT;
			case TOP:
				new_dock.child1, new_dock.child2 = insert_dock, current_dock;
				new_dock.child2.slot = BOTTOM;
			case BOTTOM:
				new_dock.child1, new_dock.child2 = current_dock, insert_dock;
				new_dock.child1.slot = TOP;
			case:
				assert(false);
			}

			resize_proportionally(new_dock, insert_slot == LEFT || insert_slot == TOP ? 0.5 : 0.5);
		}
	}
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


// 
newframe :: proc() {

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

	append_to_log(&temp_log, "hot_dock %v, active_dock %v, input.buttons[0] %v, input.modifiers[2] %v", hot_dock, active_dock, input.buttons[0], input.modifiers[2]);
	if hot_dock != nil && active_dock == nil && input.buttons[0] & Input_State.PRESS == Input_State.PRESS && input.modifiers[2] {
		active_dock = hot_dock;
	}

	// pull out floating docks, and sort by click time
	dynamic_docks: [dynamic]^Dock;
	defer delete(dynamic_docks);

	for _, i in docks {
		using dock := docks[i];

		if dock.slot == FLOAT {
			append(&dynamic_docks, dock);
		}
	}
	
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

	// when a floating dock is active and the mouse is release, check to see if it should split or add itself to the tabs of a docked
	if active_dock != nil && active_dock.slot == FLOAT && input.buttons[0] == Input_State.RELEASE {
		// handle split hover overlay for the current hovered dock
		hit_dock: ^Dock;
		hit_which: int;

		for _, i in docks {	
			using dock := docks[i];

			if !active || !opened || slot == FLOAT do continue;

			if !inside_rect(Rect{anchor, size}, input.mouse_position) do continue;

			if which := handle_hover(anchor, size, input.mouse_position); which != -1 {
				hit_which = which;
				hit_dock = dock;
			}

			break;
		}

		// handle split hover for the root dock
		using dock := docks[0];

		if which := handle_hover_root(anchor, size, input.mouse_position); which != -1 {
			hit_which = which;
			hit_dock = dock;
		}

		// 
		if hit_dock != nil {
			switch (hit_which) {
			case 1:
				insert(&docks, hit_dock, active_dock, LEFT);
			case 2:
				insert(&docks, hit_dock, active_dock, RIGHT);
			case 3:
				insert(&docks, hit_dock, active_dock, BOTTOM);
			case 4:
				insert(&docks, hit_dock, active_dock, TOP);
			case 0:
				insert(&docks, hit_dock, active_dock, TAB);
			}

			active_dock = nil;
		}
	}

	if (input.buttons[0]&Input_State(1) == Input_State(0)) {
		active_dock = nil;
	}

	if hot_dock != nil && hot_dock.slot != FLOAT {
		using hot_dock;

		start_tab := hot_dock;
		for start_tab.prev_tab != nil do start_tab = start_tab.prev_tab;

		i := 0;
		at_x := f32(5.0);
		for start_tab != nil {
			if input.buttons[0] == Input_State.PRESS && inside_rect(Rect{anchor + Vec2{at_x, 5.0}, Vec2{50.0, 25.0}}, input.mouse_position){
				start_tab2 := hot_dock;
				for start_tab2.prev_tab != nil { start_tab2 = start_tab2.prev_tab; } 

				for start_tab2 != nil {
					start_tab2.active = false;
					start_tab2 = start_tab2.next_tab;
				}
				start_tab.active = true;
				break;
			}

			at_x += 55.0;
			start_tab = start_tab.next_tab;
			i += 1;
		}
	}

	if active_dock != nil && active_dock.slot != FLOAT {
		using active_dock;

		start_tab := active_dock;
		for start_tab.prev_tab != nil do start_tab = start_tab.prev_tab;

		i := 0;
		at_x := f32(5.0);
		for start_tab != nil {
			if inside_rect(Rect{Vec2{at_x, 5.0}, Vec2{50.0, 25.0}}, start_tab.clicked_at) {
				if math.length(start_tab.clicked_at + start_tab.anchor - input.mouse_position) > 20.0 {
					fmt.println("should detach", start_tab.name);
					//detach(&docks, start_tab)
				}
				break;
			}
			at_x += 55.0;
			start_tab = start_tab.next_tab;
			i += 1;
		}
	}


	for _, i in docks {
		using dock := docks[i];
		
		clear(&widgets);
		opened = false;

		if child1 == nil && child2 == nil && prev_tab == nil && next_tab != nil {
			current_dock := dock;
			for current_dock != nil {
				current_dock.anchor, current_dock.size = anchor, size;
				current_dock = current_dock.next_tab;
			}
		}
	}

	current_dock = nil;
}

current_iteration := 0;

endframe :: proc() {

	// move floating dock
	if active_dock != nil /*&& active_dock.slot == FLOAT*/ /*&& active_ptr == 0*/ {
		if (input.buttons[0] == Input_State.PRESS) {
			active_dock.time_clicked = f64(current_iteration);
			active_dock.clicked_at = input.mouse_position - active_dock.anchor;
		}

		if active_dock.slot == FLOAT && input.buttons[0] & Input_State(1) == Input_State(1) {
			active_dock.anchor = input.mouse_position - active_dock.clicked_at;
		}
	}

	// if clicked on hot dock, change click time
	if hot_dock != nil {
		if (input.buttons[0] == Input_State.PRESS) {
			hot_dock.time_clicked = f64(current_iteration);
		}
	}


	current_iteration += 1;

	clear(&input.input_runes);

	for _, i in input.buttons {
		input.buttons[i] = input.buttons[i] & Input_State(1);
	}

	input.mousewheel_delta = 0.0;
	input.mouse_position_delta = Vec2{};
}

reset :: proc() {
	for _ in docks[1:] {
		dock := pop(&docks);
		free(dock);
	}
	docks[0].child1 = nil;
	docks[0].child2 = nil;
}

begin_dock :: proc(search_name: string) -> bool {

	assert(current_dock == nil, "Expected `current_dock == nil`. Did you match a `begin_dock` with a `close_dock`?");
	
	using dock := find_dock_in_docks(&docks, search_name);
	if dock == nil {
		// unknown dock, make a new floating one
		dock = append_return(&docks);
		dock.active, dock.opened, dock.slot, dock.time_clicked, dock.clicked_at = true, true, Dock_Slot.FLOAT, -1.0, Vec2{};


		size = Vec2{f32(window_size[0]), f32(window_size[1])}/2.0;
		anchor = size - size/2.0;
		name = search_name;
		return false;
	}

	opened = true;
	if !active do return false;

	assert(child1 == nil || child2 == nil, "Expected leaf dock");
	
	current_dock = dock;

	return true;
}

end_dock :: proc() {
	current_dock = nil;
}



// Input

Input_State :: enum u8 {
	UP          = 0b000,
	DOWN        = 0b001,
	RELEASE     = 0b010,
	PRESS       = 0b011,
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

	modifiers:                [8]bool,

};


double_click_time := f32(0.5);
double_click_deadzone := f32(5.0);
