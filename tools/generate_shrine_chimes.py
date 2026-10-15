"""Generate the game's gentle, non-vocal shrine cues."""

from array import array
import math
from pathlib import Path
import random
import wave

SAMPLE_RATE = 32000
ROOT = Path(__file__).resolve().parents[1] / "audio"


def render(name: str, notes: list[tuple[float, float, float]], duration: float) -> None:
    randomizer = random.Random(1949)
    samples = array("h")
    for frame in range(int(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        value = 0.0
        for start, pitch, gain in notes:
            age = time - start
            if age < 0:
                continue
            # Soft bamboo strike, followed by a short warm metal resonance.
            attack = min(1.0, age * 130.0)
            body = math.exp(-age * 3.2)
            partials = (
                math.sin(2.0 * math.pi * pitch * age) * 0.58
                + math.sin(2.0 * math.pi * pitch * 2.01 * age) * 0.20
                + math.sin(2.0 * math.pi * pitch * 3.98 * age) * 0.07
            )
            wood = randomizer.uniform(-1.0, 1.0) * math.exp(-age * 65.0) * 0.035
            value += gain * attack * body * (partials + wood)
        samples.append(int(max(-0.8, min(0.8, value)) * 32767))
    with wave.open(str(ROOT / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(samples.tobytes())


if __name__ == "__main__":
    render("shrine_bell_start.wav", [(0.0, 392.0, 0.55), (0.22, 523.25, 0.34)], 1.35)
    render("shrine_bell_complete.wav", [(0.0, 392.0, 0.48), (0.18, 523.25, 0.40), (0.39, 659.25, 0.38)], 1.8)
