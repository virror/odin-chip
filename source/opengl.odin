package main

import sdl "vendor:sdl2"
import gl "vendor:OpenGL"
import "core:strings"
import "core:fmt"

Vector2f :: distinct [2]f32
Vector3f :: distinct [3]f32

@(private="file")
shader_program: u32
@(private="file")
gl_context: sdl.GLContext
@(private="file")
window: ^sdl.Window
@(private="file")
texture: u32

render_init :: proc(window2: ^sdl.Window)
{
    window = window2
    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_MAJOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_MINOR_VERSION, 3)
    sdl.GL_SetAttribute(sdl.GLattr.CONTEXT_PROFILE_MASK, cast(i32)sdl.GLprofile.CORE)

    gl_context = sdl.GL_CreateContext(window)
    assert(gl_context != nil, "Failed to create opengl context")

    gl.load_up_to(3, 3, sdl.gl_set_proc_address)
    sdl.GL_SetSwapInterval(1)
    gl.Viewport(0, 0, WIN_WIDTH, WIN_HEIGHT)

    vert_shader := shader_compile(#load("../shaders/shader.vert"), gl.VERTEX_SHADER)
    frag_shader := shader_compile(#load("../shaders/shader.frag"), gl.FRAGMENT_SHADER)
    shader_program = shader_create(vert_shader, frag_shader)

    gl.UseProgram(shader_program)
    create_quad({1,1}, {1,-1}, {-1, 1}, {-1, -1}, {1,1,1}, {1,1,1}, {1,1,1}, {1,1,1})
}

render_delete :: proc()
{
    gl.DeleteProgram(shader_program)
    sdl.GL_DeleteContext(gl_context)
}

@(private="file")
create_quad :: proc(v1: Vector2f, v2: Vector2f, v3: Vector2f, v4: Vector2f,
                    c1: Vector3f, c2: Vector3f, c3: Vector3f, c4: Vector3f)
{
    vertices := [?]f32 {
        //pos          //colors             //Texture coords
        v1.x, v1.y,    c1.r, c1.g, c1.b,    1, 0,
        v2.x, v2.y,    c2.r, c2.g, c2.b,    1, 1,
        v3.x, v3.y,    c3.r, c3.g, c3.b,    0, 0,
        v4.x, v4.y,    c4.r, c4.g, c4.b,    0, 1,
    }

   indices := [?]i32 {
       2, 3, 1,
       0, 1, 2,
    }

    vao: u32
    vbo: u32
    ebo: u32
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)
    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 7 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 7 * size_of(f32), 2 * size_of(f32))
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 7 * size_of(f32), 5 * size_of(f32))
    gl.EnableVertexAttribArray(2)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
}

@(private="file")
shader_create :: proc(vert_shader: u32, frag_shader:u32) -> u32
{
    shader := gl.CreateProgram()
    gl.AttachShader(shader, vert_shader)
    gl.AttachShader(shader, frag_shader)
    gl.LinkProgram(shader)
    gl.DeleteShader(vert_shader)
    gl.DeleteShader(frag_shader)
    return shader
}

@(private="file")
shader_compile :: proc(shader_src: string, shader_type: u32) -> u32
{
    shader := gl.CreateShader(shader_type)
    csource := strings.clone_to_cstring(shader_src)
    defer delete(csource)
    gl.ShaderSource(shader, 1, &csource, nil)
    gl.CompileShader(shader)
    success: i32
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
    if success == 0 {
        msg_len: i32
        gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, &msg_len)
        info_log := make([]u8, msg_len)
        gl.GetShaderInfoLog(shader, msg_len, &msg_len, raw_data(info_log))
        fmt.println(cstring(raw_data(info_log)))
    }
    return shader
}

render_screen :: proc()
{
    gl.ClearColor(0, 0.5, 0.8, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)

    texture_destroy(texture)
    texture = texture_create(i32(SCREEN_WIDTH), i32(SCREEN_HEIGHT))
    gl.BindTexture(gl.TEXTURE_2D, texture)
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    sdl.GL_SwapWindow(window)
}

@(private="file")
texture_create :: proc(w: i32, h: i32) -> u32
{
    texture: u32
    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.PixelStorei(gl.UNPACK_ROW_LENGTH, w)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, w, h, 0, gl.RGB, gl.UNSIGNED_BYTE_2_3_3_REV, &vram[0])

    return texture
}

texture_destroy :: proc(texture: u32)
{
    texture := texture // Copy needed to take address of
    gl.DeleteTextures(1, &texture)
}
