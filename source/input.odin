package main

import "core:fmt"
import sdl "vendor:sdl2"

input: [16]bool

input_process :: proc(event: ^sdl.Event)
{
    #partial switch event.type {
        case sdl.EventType.KEYDOWN:
            #partial switch event.key.keysym.sym {
                case sdl.Keycode.V:     // F
                    input[15] = true
                case sdl.Keycode.F:     // E
                    input[14] = true
                case sdl.Keycode.R:     // D
                    input[13] = true
                case sdl.Keycode.NUM4:  // C
                    input[12] = true
                case sdl.Keycode.C:     // B
                    input[11] = true
                case sdl.Keycode.Z:     // A
                    input[10] = true
                case sdl.Keycode.D:     // 9
                    input[9] = true
                case sdl.Keycode.S:     // 8
                    input[8] = true
                case sdl.Keycode.A:     // 7
                    input[7] = true
                case sdl.Keycode.E:     // 6
                    input[6] = true
                case sdl.Keycode.W:     // 5
                    input[5] = true
                case sdl.Keycode.Q:     // 4
                    input[4] = true
                case sdl.Keycode.NUM3:  // 3
                    input[3] = true
                case sdl.Keycode.NUM2:  // 2
                    input[2] = true
                case sdl.Keycode.NUM1:  // 1
                    input[1] = true
                case sdl.Keycode.X:     // 0
                    input[0] = true
            }
        case sdl.EventType.KEYUP:
            #partial switch event.key.keysym.sym {
                case sdl.Keycode.V:     // F
                    input[15] = false
                case sdl.Keycode.F:     // E
                    input[14] = false
                case sdl.Keycode.R:     // D
                    input[13] = false
                case sdl.Keycode.NUM4:  // C
                    input[12] = false
                case sdl.Keycode.C:     // B
                    input[11] = false
                case sdl.Keycode.Z:     // A
                    input[10] = false
                case sdl.Keycode.D:     // 9
                    input[9] = false
                case sdl.Keycode.S:     // 8
                    input[8] = false
                case sdl.Keycode.A:     // 7
                    input[7] = false
                case sdl.Keycode.E:     // 6
                    input[6] = false
                case sdl.Keycode.W:     // 5
                    input[5] = false
                case sdl.Keycode.Q:     // 4
                    input[4] = false
                case sdl.Keycode.NUM3:  // 3
                    input[3] = false
                case sdl.Keycode.NUM2:  // 2
                    input[2] = false
                case sdl.Keycode.NUM1:  // 1
                    input[1] = false
                case sdl.Keycode.X:     // 0
                    input[0] = false
            }
    }
}
