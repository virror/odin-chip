package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import sdl "vendor:sdl2"

Mode :: enum {
    chip8,
    schip_old,
    schip_new,
}

WIN_WIDTH :: 1024
WIN_HEIGHT :: 512

@(private="file")
exit := false
@(private="file")
window: ^sdl.Window
rom_path := "roms/RACE.ch8"
draw_screen: bool
mode: Mode

main :: proc()
{
    a: u32
    b: u32
    sdl.Init(sdl.INIT_VIDEO | sdl.INIT_AUDIO)
    defer sdl.Quit()

    window = sdl.CreateWindow("odin-chip", 100, 100, WIN_WIDTH, WIN_HEIGHT,
        sdl.WINDOW_OPENGL)
    assert(window != nil, "Failed to create main window")
    defer sdl.DestroyWindow(window)

    render_init(window)
    update_window_title(rom_path)

    mode = Mode.schip_old

    switch len(os.args) {
        case 3:
            mode = Mode(strconv.atoi(os.args[2]))
            fallthrough
        case 2:
            rom_path = os.args[1]
    }

    //Emu stuff
    chip8_init()
    audio_init()

    for !exit {
        a = sdl.GetTicks()
        delta := a - b

        if (delta > u32(17)) //1000 / 60 ish
        {
            b = a
            for i:= 0; i < 15; i += 1 {
                chip8_step()
                if draw_screen {
                    draw_screen = false
                    break
                }
            }
            chip8_timers()
            update()
        }
    }
    render_delete()
    audio_close()
}

@(private="file")
update :: proc()
{
    render_screen()
    handle_events()
}

@(private="file")
update_window_title :: proc(title: string)
{
    strs := [?]string {"odin-chip - ", title}
    str := strings.clone_to_cstring(strings.concatenate(strs[:]))
    sdl.SetWindowTitle(window, str)
}

@(private="file")
handle_events :: proc()
{
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case sdl.EventType.QUIT:
                exit = true
            case sdl.EventType.WINDOWEVENT:
                if event.window.event == sdl.WindowEventID.CLOSE {
                    exit = true
                }
            case:
                input_process(&event)
        }
    }
}

exit :: proc()
{
    exit = true
}