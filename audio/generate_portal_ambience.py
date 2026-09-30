"""Generate the seamless, khaen-inspired ambience heard near a stage portal."""

import math
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 24000
DURATION = 8
TAU = 2.0 * math.pi
OUTPUT = Path(__file__).with_name("portal_ambience.wav")


def sample(time: float) -> float:
    breath = 0.73 + 0.18 * math.sin(TAU * 0.25 * time)
    reed_wobble = 0.13 * math.sin(TAU * 0.375 * time)
    reeds = (
        0.22 * math.sin(TAU * 110.0 * time + reed_wobble)
        + 0.13 * math.sin(TAU * 165.0 * time - reed_wobble)
        + 0.08 * math.sin(TAU * 220.0 * time + 0.18 * math.sin(TAU * 0.5 * time))
    )
    low_swell = 0.055 * math.sin(TAU * 55.0 * time) * (0.5 + 0.5 * math.sin(TAU * 0.5 * time))
    chime_pulse = (0.5 + 0.5 * math.cos(TAU * 0.5 * (time - 0.7))) ** 10
    chimes = chime_pulse * (
        0.047 * math.sin(TAU * 660.0 * time)
        + 0.024 * math.sin(TAU * 990.0 * time)
    )
    airy = 0.012 * (
        math.sin(TAU * 523.5 * time + 1.2)
        + math.sin(TAU * 718.5 * time + 2.4)
        + math.sin(TAU * 971.25 * time + 0.7)
    ) * (0.6 + 0.4 * math.sin(TAU * 0.125 * time))
    return (reeds * breath + low_swell + chimes + airy) * 0.75


with wave.open(str(OUTPUT), "wb") as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(SAMPLE_RATE)
    frames = bytearray()
    for index in range(SAMPLE_RATE * DURATION):
        value = max(-1.0, min(1.0, sample(index / SAMPLE_RATE)))
        frames.extend(struct.pack("<h", round(value * 32767)))
    output.writeframes(frames)

print(OUTPUT)
