"""Generate calm shrine cues from wooden strikes and small bell resonances.

The modal synthesis is deliberately non-vocal: no recordings, chanting, drones,
or whispered layers. A fixed seed makes the shipped WAV files reproducible.
"""

from array import array
import math
from pathlib import Path
import random
import wave

SAMPLE_RATE = 32000
ROOT = Path(__file__).resolve().parents[1] / "audio"


def add_strike(
    samples: list[float], start: float, pitch: float, gain: float, wooden: bool
) -> None:
    randomizer = random.Random(1949 + round(start * 1000) + round(pitch))
    # Unequal partial spacing gives a struck object its natural character.
    # The softer, shorter high partials avoid a harsh or ominous metal sound.
    modes = (
        [(1.0, 0.68, 0.085), (2.73, 0.23, 0.042), (5.38, 0.06, 0.021)]
        if wooden
        else [
            (1.0, 0.57, 0.63),
            (2.01, 0.20, 0.37),
            (2.76, 0.10, 0.25),
            (4.08, 0.045, 0.15),
            (5.43, 0.018, 0.085),
        ]
    )
    filtered_noise = 0.0
    first = round(start * SAMPLE_RATE)
    for frame in range(first, len(samples)):
        age = (frame - first) / SAMPLE_RATE
        # A padded mallet has a short rounded contact rather than a hard click.
        contact = 1.0 - math.exp(-age / (0.0018 if wooden else 0.0035))
        settling = 0.0007 * (1.0 - math.exp(-age * 65.0))
        value = 0.0
        for ratio, level, decay in modes:
            phase = 2.0 * math.pi * pitch * ratio * (age + settling)
            value += level * math.sin(phase) * math.exp(-age / decay)
        filtered_noise += 0.28 * (randomizer.uniform(-1.0, 1.0) - filtered_noise)
        value += filtered_noise * math.exp(-age / 0.014) * (0.11 if wooden else 0.035)
        samples[frame] += gain * contact * value


def render(
    name: str, strikes: list[tuple[float, float, float, bool]], duration: float
) -> None:
    dry = [0.0] * round(SAMPLE_RATE * duration)
    for strike in strikes:
        add_strike(dry, *strike)

    # Quiet, asymmetrical early reflections suggest a small open wooden sala.
    # There is no long reverb wash, so the cue stays clear over gameplay.
    reflections = [
        [(0.027, 0.085), (0.071, 0.043), (0.113, 0.021)],
        [(0.036, 0.080), (0.059, 0.045), (0.127, 0.020)],
    ]
    channels = []
    for taps in reflections:
        channel = dry.copy()
        for delay, level in taps:
            offset = round(delay * SAMPLE_RATE)
            for frame in range(offset, len(dry)):
                channel[frame] += dry[frame - offset] * level
        channels.append(channel)

    peak = max(abs(value) for channel in channels for value in channel)
    # Consistent, moderate peaks with headroom. Apply an end fade before writing
    # even though the modal tails have mostly decayed by this point.
    gain = 0.62 / max(peak, 0.001)
    samples = array("h")
    sum_squares = 0.0
    output_peak = 0.0
    for frame in range(len(dry)):
        remaining = (len(dry) - frame - 1) / SAMPLE_RATE
        fade = min(1.0, remaining / 0.10)
        for channel in channels:
            value = channel[frame] * gain * fade
            sum_squares += value * value
            output_peak = max(output_peak, abs(value))
            samples.append(round(value * 32767))
    with wave.open(str(ROOT / name), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(samples.tobytes())
    rms = math.sqrt(sum_squares / len(samples))
    print(
        f"{name}: {duration:.2f}s, stereo {SAMPLE_RATE}Hz, "
        f"peak {20.0 * math.log10(output_peak):.1f}dBFS, "
        f"RMS {20.0 * math.log10(rms):.1f}dBFS"
    )


if __name__ == "__main__":
    render(
        "shrine_bell_start.wav",
        [(0.0, 438.0, 0.30, True), (0.075, 566.0, 0.54, False)],
        1.35,
    )
    render(
        "shrine_bell_complete.wav",
        [
            (0.0, 472.0, 0.19, True),
            (0.018, 672.0, 0.43, False),
            (0.245, 898.0, 0.28, False),
        ],
        2.10,
    )
