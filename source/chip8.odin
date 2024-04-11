package main

import "core:fmt"
import "core:os"
import "core:intrinsics"
import "core:strings"
import "core:math/rand"

SCREEN_WIDTH :: 128
SCREEN_HEIGHT :: 64
vram: [SCREEN_WIDTH * SCREEN_HEIGHT]u8

@(private="file")
font:= [?]u8 {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
}
fontXL:= [?]u8 {
    0xFF, 0xFF, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xFF, 0xFF, // 0
    0x0C, 0x0C, 0x3C, 0x3C, 0x0C, 0x0C, 0x0C, 0x0C, 0x3F, 0x3F, // 1
    0xFF, 0xFF, 0x03, 0x03, 0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF, // 2
    0xFF, 0xFF, 0x07, 0x07, 0xFF, 0xFF, 0x07, 0x07, 0xFF, 0xFF, // 3
    0xC3, 0xC3, 0xC3, 0xC3, 0xFF, 0xFF, 0x03, 0x03, 0x03, 0x03, // 4
    0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF, 0x03, 0x03, 0xFF, 0xFF, // 5
    0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF, // 6
    0xFF, 0xFF, 0x03, 0x03, 0x0C, 0x0C, 0x30, 0x30, 0x30, 0x30, // 7
    0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF, // 8
    0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF, 0x03, 0x03, 0xFF, 0xFF, // 9
    0xFF, 0xFF, 0xC3, 0xC3, 0xFF, 0xFF, 0xC3, 0xC3, 0xC3, 0xC3, // A
    0xFC, 0xFC, 0xC3, 0xC3, 0xFC, 0xFC, 0xC3, 0xC3, 0xFC, 0xFC, // B
    0xFF, 0xFF, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xFF, 0xFF, // C
    0xFC, 0xFC, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xFC, 0xFC, // D
    0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF, // E
    0xFF, 0xFF, 0xC0, 0xC0, 0xFF, 0xFF, 0xC0, 0xC0, 0xC0, 0xC0, // F
}
@(private="file")
mem: [0x1000]u8
@(private="file")
pc: u16
@(private="file")
sp: u8
@(private="file")
ireg: u16
@(private="file")
stack: [32]u16
@(private="file")
v: [16]u8
@(private="file")
dtimer: u8
@(private="file")
stimer: u8
@(private="file")
highres: bool
@(private="file")
keyDown: bool

chip8_init :: proc()
{
    file, err := os.open(rom_path, os.O_RDONLY)
    assert(err == 0, "Failed to open rom")
    _, err2 := os.read(file, mem[0x00200:0x1000])
    assert(err2 == 0, "Failed to read rom data")
    os.close(file)
    copy(mem[0x50:0x9F], font[:])
    copy(mem[0xA0:0xFF], fontXL[:])
    pc = 0x200
    sp = 0
    highres = false
}

chip8_step:: proc()
{
    opcode: u16 = (u16(mem[pc]) << 8) | u16(mem[pc + 1])
    pc += 2
    code:= opcode >> 12
    switch(code){
        case 0x0:
            sub_code:= opcode & 0x00FF
            switch(sub_code) {
                case 0xE0:  //Clear screen
                    for y :u16= 0; y < SCREEN_HEIGHT; y += 1 {
                        for x :u16= 0; x < SCREEN_WIDTH; x += 1 {
                            vram[y * SCREEN_WIDTH + x] = 0
                        }
                    }
                case 0xEE:  //Return from subroutine
                    sp -= 1
                    pc = stack[sp]
                case 0xFB:  //Scroll right
                    n:u16= 4
                    if mode == Mode.schip_new {
                        n = 8
                    }
                    for y :u16= 0; y < SCREEN_HEIGHT; y += 1 {
                        for x :u16= SCREEN_WIDTH - (n + 1); x > 0; x -= 1 {
                            vram[y * SCREEN_WIDTH + (x + n)] = vram[y * SCREEN_WIDTH + x]
                            vram[y * SCREEN_WIDTH + x] = 0
                        }
                    }
                case 0xFC:  //Scroll left
                    n:u16= 4
                    if mode == Mode.schip_new {
                        n = 8
                    }
                    for y :u16= 0; y < SCREEN_HEIGHT; y += 1 {
                        for x :u16= n + 1; x < SCREEN_WIDTH; x += 1 {
                            vram[y * SCREEN_WIDTH + (x - n)] = vram[y * SCREEN_WIDTH + x]
                            vram[y * SCREEN_WIDTH + x] = 0
                        }
                    }
                case 0xFD:  //Exit emulator
                    exit()
                case 0xFE:  //Disable highres mode
                    highres = false
                case 0xFF:  //Enable highres mode
                    highres = true
                case:
                    if((sub_code & 0xF0) == 0xC0) { //Scroll down
                        n:= (sub_code & 0x0F)
                        if mode == Mode.schip_new && !highres {
                            n *= 2
                        }
                        start:u16= SCREEN_HEIGHT - 1 - n
                        for y :i16= i16(start); y >= 0; y -= 1 {
                            for x :u16= 0; x < SCREEN_WIDTH; x += 1 {
                                vram[(u16(y) + n) * SCREEN_WIDTH + x] = vram[u16(y) * SCREEN_WIDTH + x]
                                vram[u16(y) * SCREEN_WIDTH + x] = 0
                            }
                        }
                    } else {
                        fmt.printf("Unimplemented opcode: 0x%x\n", opcode)
                        panic("")
                    }
            }
        case 0x1:   //Jump
            pc = opcode & 0x0FFF
        case 0x2:   //Call subroutine
            stack[sp] = pc
            sp += 1
            pc = opcode & 0x0FFF
        case 0x3:   //Skip if x == nn
            reg:= (opcode >> 8) & 0xF
            if(v[reg] == u8(opcode & 0x00FF)) {
                pc += 2
            }
        case 0x4:   //Skip if x != nn
            reg:= (opcode >> 8) & 0xF
            if(v[reg] != u8(opcode & 0x00FF)) {
                pc += 2
            }
        case 0x5:   //Skip if x == y
            regx:= (opcode >> 8) & 0xF
            regy:= (opcode >> 4) & 0xF
            if(v[regx] == v[regy]) {
                pc += 2
            }
        case 0x6:   //Set nn to x
            reg:= (opcode >> 8) & 0xF
            v[reg] = u8(opcode & 0x00FF)
        case 0x7:   //Add nn to x
            reg:= (opcode >> 8) & 0xF
            v[reg] += u8(opcode & 0x00FF)
        case 0x8:   //Set x = y
            chip8_alu(opcode)
        case 0x9:   //Skip if x != y
            regx:= (opcode >> 8) & 0xF
            regy:= (opcode >> 4) & 0xF
            if(v[regx] != v[regy]) {
                pc += 2
            }
        case 0xA:   //Set I
            ireg = (opcode & 0x0FFF)
        case 0xB:   //Jump with offset
            reg:u16= 0
            if mode != Mode.chip8 {
                reg= (opcode >> 8) & 0xF
            }
            pc = u16(v[reg]) + (opcode & 0x0FFF)
        case 0xC:   //Random
            reg:= (opcode >> 8) & 0xF
            v[reg] = u8(opcode & 0x00FF) & u8(rand.int31_max(255, nil))
        case 0xD:   //Draw sprite
            chip8_draw(opcode)
        case 0xE:
            sub_code:= opcode & 0x00FF
            reg:= (opcode >> 8) & 0xF
            switch(sub_code) {
                case 0x9E:  //Skip if key
                    if(input[v[reg]] == true) {
                        pc += 2
                    }
                case 0xA1:  //Skip if not key
                    if(input[v[reg]] != true) {
                        pc += 2
                    }
                case:
                    fmt.printf("Unimplemented opcode: 0x%x\n", opcode)
                    panic("")
            }
        case 0xF:
            sub_code:= opcode & 0x00FF
            reg:= (opcode >> 8) & 0xF
            switch(sub_code) {
                case 0x07:  //Delay timer get
                    v[reg] = dtimer
                case 0x0A:  //Get key
                    for i:u8= 0; i < 16; i += 1 {
                        if(input[i] == true && keyDown == false) {
                            keyDown = true
                            return
                        }
                        else if keyDown == true {
                            v[reg] = i
                            keyDown = false
                            return
                        }
                    }
                    pc -= 2
                case 0x15:  //Delay timer set
                    dtimer = v[reg]
                case 0x18:  //Sound timer set
                    stimer = v[reg]
                case 0x1E:  //Add to I
                    ireg += u16(v[reg])
                case 0x29:  //Font
                    ireg = 0x50 + u16(v[reg]) * 5
                case 0x30:  //Large font
                    ireg = 0xA0 + u16(v[reg]) * 10
                case 0x33:  //BCD
                    mem[ireg + 2] = v[reg] % 10
                    mem[ireg + 1] = (v[reg] / 10) % 10
                    mem[ireg + 0] = (v[reg] / 100) % 10
                case 0x55:  //Store memory
                    for i :u16= 0; i <= reg; i += 1 {
                        mem[ireg + i] = v[i]
                    }
                    if mode == Mode.chip8 {
                        ireg = reg + 1
                    }
                case 0x65:  //Load memory
                    for i :u16= 0; i <= reg; i += 1 {
                        v[i] = mem[ireg + i]
                    }
                    if mode == Mode.chip8 {
                        ireg = reg + 1
                    }
                case 0x75:  //Save regs
                    a := [?]string { rom_path, ".sav" }
                    file, err := os.open(strings.concatenate(a[:]), os.O_WRONLY | os.O_CREATE)
                    assert(err == 0, "Failed to open save")
                    _, err2 := os.write(file, v[0:reg+1])
                    assert(err2 == 0, "Failed to write save data")
                    os.close(file)
                case 0x85:  //Load regs
                    a := [?]string { rom_path, ".sav" }
                    file, err := os.open(strings.concatenate(a[:]), os.O_RDONLY)
                    assert(err == 0, "Failed to open save")
                    _, err2 := os.read(file, v[0:reg+1])
                    assert(err2 == 0, "Failed to read save data")
                    os.close(file)
                case:
                    fmt.printf("Unimplemented opcode: 0x%x\n", opcode)
                    panic("")
            }
        case:
            fmt.printf("Unimplemented opcode: 0x%x\n", opcode)
            panic("")
    }
}

chip8_timers :: proc()
{
    if dtimer > 0 {
        dtimer -= 1
    }
    if stimer > 0 {
        stimer -= 1
        audio_pause(false)
    } else {
        audio_pause(true)
    }
}

@(private="file")
chip8_alu :: proc(opcode: u16)
{
    sub_code:= opcode & 0x000F
    regx:= (opcode >> 8) & 0xF
    regy:= (opcode >> 4) & 0xF
    switch(sub_code) {
        case 0x0:   //Set
            v[regx] = v[regy]
        case 0x1:   //Or
            v[regx] |= v[regy]
            if mode == Mode.chip8 {
                v[15] = 0
            }
        case 0x2:   //And
            v[regx] &= v[regy]
            if mode == Mode.chip8 {
                v[15] = 0
            }
        case 0x3:   //Xor
            v[regx] ~= v[regy]
            if mode == Mode.chip8 {
                v[15] = 0
            }
        case 0x4:   //Add
            val, owf := intrinsics.overflow_add(v[regx], v[regy])
            v[regx] = val
            v[15] = u8(owf)
        case 0x5:   //Sub x, y
            val, owf := intrinsics.overflow_sub(v[regx], v[regy])
            v[regx] = val
            v[15] = u8(!owf)
        case 0x6:   //Shift right
            if mode == Mode.chip8 {
                v[regx] = v[regy]
            }
            flag:= v[regx] & 1
            v[regx] = v[regx] >> 1
            v[15] = flag
        case 0x7:   //Sub y, x
            val, owf := intrinsics.overflow_sub(v[regy], v[regx])
            v[regx] = val
            v[15] = u8(!owf)
        case 0xE:   //Shift left
            if mode == Mode.chip8 {
                v[regx] = v[regy]
            }
            flag:= (v[regx] >> 7)
            v[regx] = v[regx] << 1
            v[15] = flag
        case:
            fmt.printf("Unimplemented opcode: 0x%x\n", opcode)
            panic("")
    }
}

@(private="file")
chip8_draw :: proc(opcode: u16)
{
    data: u16
    p:= u16(8)
    resolution:= (u16(!highres) + 1)
    width: = SCREEN_WIDTH / resolution
    height := SCREEN_HEIGHT / resolution
    x:= u16(v[(opcode >> 8) & 0xF]) & (width - 1)
    y:= u16(v[(opcode >> 4) & 0xF]) & (height - 1)
    n:= opcode & 0x000F
    v[15] = 0

    if n == 0 {
        n = 16
        p = 16
    }

    for k :u16= 0; k < n; k += 1 {
        if n != 16 {
            data= u16(mem[ireg + u16(k)])
        } else {
            data= u16(mem[ireg + (k * 2) + 1]) | (u16(mem[ireg + (k * 2)]) << 8)
        }
        if(y + k >= height) {
            return
        }
        for j :u16= 0; j < p; j += 1 {
            if(x + j < width) {
                value:= u8((data >> (p - 1 - j)) & 1)
                if value == 1 {
                    coord:= ((y + k) * SCREEN_WIDTH + x + j) * resolution
                    pixel:= vram[coord]
                    vram[coord] = value ~ pixel
                    if highres == false {
                        vram[coord + 1] = value ~ pixel
                        vram[coord + SCREEN_WIDTH] = value ~ pixel
                        vram[coord + SCREEN_WIDTH + 1] = value ~ pixel
                    }
                    if pixel == 1 {
                        v[15] = 1
                    }
                }
            }
        }
    }
    if mode != Mode.schip_new {
        draw_screen = true
    }
}