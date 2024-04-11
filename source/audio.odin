package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl2"

AMPLITUDE :: 28000
SAMPLE_RATE :: 44100
FREQUENCY :: 441

@(private="file")
sample_nr:f32= 0
@(private="file")
want: sdl.AudioSpec
@(private="file")
have: sdl.AudioSpec
@(private="file")
device: sdl.AudioDeviceID

audio_init :: proc()
{
    want.freq = SAMPLE_RATE
    want.format = sdl.AUDIO_S16SYS
    want.channels = 1
    want.samples = 256
    want.callback = sdl.AudioCallback(audio_callback)

    device = sdl.OpenAudioDevice(nil, false, &want, &have, false)
    if device == 0 {
        fmt.println("Failed to open audio device")
    }

    if(want.format != have.format) {
        fmt.println("Failed to set audio formats")
    }
}

audio_pause :: proc(play: sdl.bool)
{
    sdl.PauseAudioDevice(device, play)
}

audio_close :: proc()
{
    sdl.PauseAudioDevice(device, true)
    sdl.CloseAudio()
}

audio_callback :: proc(user_data: rawptr, raw_buffer: [^]u8, bytes: i32)
{
    buffer:[^]u16= cast([^]u16)raw_buffer
    length := bytes / 2

    for i:i32= 0; i < length; i+=1 {
        time := sample_nr / SAMPLE_RATE
        sample_nr += 1
        sample := u16(AMPLITUDE * math.sin_f32(2.0 * math.PI * FREQUENCY * time)) // render sine wave
        buffer[i] = sample
    }
}