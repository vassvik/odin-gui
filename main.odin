import (
	"fmt.odin";
	"strings.odin";
	"external/odin-glfw/glfw.odin";
	"external/odin-gl/gl.odin";
)

main :: proc() {
	// setup glfw
    error_callback :: proc(error: i32, desc: ^u8) #cc_c {
		fmt.printf("Error code %d:\n    %s\n", error, strings.to_odin_string(desc));
	}
	glfw.SetErrorCallback(error_callback);

	if glfw.Init() == 0 do return;
	defer glfw.Terminate();

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3);
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3);
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);

	resx, resy := 1600.0, 900.0;
	window := glfw.CreateWindow(i32(resx), i32(resy), "Odin Shadertoy Lite Example, No Buffers", nil, nil);
	if window == nil do return;

	glfw.MakeContextCurrent(window);
	glfw.SwapInterval(1);

	// setup opengl
	set_proc_address :: proc(p: rawptr, name: string) { 
		(cast(^rawptr)p)^ = rawptr(glfw.GetProcAddress(&name[0]));
	}
	gl.load_up_to(3, 3, set_proc_address);

	// load shaders
	program, shader_success := gl.load_shaders("shaders/shader_main.vs", "shaders/shader_main.fs");
	defer gl.DeleteProgram(program);

	// setup vao
	vao: u32;
	gl.GenVertexArrays(1, &vao);
	defer gl.DeleteVertexArrays(1, &vao);

	Vec2 :: [vector 2]f32;
	Vec3 :: [vector 3]f32;
	Vec4 :: [vector 4]f32;

	Dock :: struct {
		size: Vec2;
		anchor: Vec2;
		color: Vec4;
	};

	docks := [...]Dock {
		{size = Vec2{1600, 200}, anchor = Vec2{0, 700}, color = Vec4{1.0, 0.0, 0.0, 1.0}},
		{size = Vec2{300, 700}, anchor = Vec2{0, 0}, color = Vec4{0.0, 1.0, 0.0, 1.0}},
		{size = Vec2{1000, 700}, anchor = Vec2{300, 0}, color = Vec4{1.0, 0.0, 1.0, 1.0}},
		{size = Vec2{300, 700}, anchor = Vec2{1300, 0}, color = Vec4{0.0, 0.0, 1.0, 1.0}},
	};

	uniforms := gl.get_uniforms_from_program(program);
    defer for uniform, name in uniforms do free(uniform.name);

    for uniform, name in uniforms {
        fmt.println(name, uniform, uniform.location);
    }

    fmt.println(uniforms["resolution"].location);
	fmt.println(uniforms["size"].location);
	fmt.println(uniforms["anchor"].location);
	fmt.println(uniforms["in_color"].location);

	// main loop
	gl.ClearColor(1.0, 1.0, 1.0, 1.0);
	for glfw.WindowShouldClose(window) == glfw.FALSE {
		// show fps in window title
		glfw.calculate_frame_timings(window);
		
		// listen to inut
		glfw.PollEvents();

		// clear screen
		gl.Clear(gl.COLOR_BUFFER_BIT);

		// setup shader program and uniforms
		gl.UseProgram(program);
		gl.Uniform2f(get_uniform_location(program, "resolution\x00"), f32(resx), f32(resy));
		gl.Uniform2f(get_uniform_location(program, "size\x00"),       f32(10),   f32(20));
		gl.Uniform2f(get_uniform_location(program, "anchor\x00"),     f32(0.0),  f32(0.0));
		gl.Uniform4f(get_uniform_location(program, "in_color\x00"),   1.0, 0.0, 0.0, 1.0);
		
		// draw stuff
		gl.BindVertexArray(vao);
		gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, 1);
		
		glfw.SwapBuffers(window);
	}
}

get_uniform_location :: proc(program: u32, str: string) -> i32 {
	return gl.GetUniformLocation(program, &str[0]);;
}
