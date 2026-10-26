#!/usr/bin/env python3
"""Synthesizes the calm background loop played during a puzzle.

Writes a seamless 48-second stereo loop (soft pad chords, low bass and a sparse
bell melody with echoes) to PuzzliumFeatures/Resources/calm-loop.m4a.
Every note tail wraps around the end of the buffer, so the loop has no seam.

Usage: python3 scripts/generate_music.py   (needs macOS `afconvert`)
"""

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

RATE = 24000
BEAT = 1.0  # seconds, 60 bpm
BAR = 4 * BEAT
OUT = Path(__file__).resolve().parent.parent / "Packages/PuzzliumKit/Sources/PuzzliumFeatures/Resources/calm-loop.m4a"

# (pad voicing, bass root) in MIDI notes, one chord per bar.
PROGRESSION = [
    ([53, 57, 60, 64], 41),  # Fmaj7
    ([52, 55, 59, 62], 40),  # Em7
    ([50, 53, 57, 60], 38),  # Dm7
    ([48, 52, 55, 59], 36),  # Cmaj7
    ([53, 57, 60, 64], 41),  # Fmaj7
    ([52, 55, 57, 60], 45),  # Am7
    ([50, 53, 57, 60], 38),  # Dm7
    ([50, 55, 57, 60], 43),  # G6sus
    ([53, 57, 60, 64], 41),  # Fmaj7
    ([52, 55, 59, 62], 40),  # Em7
    ([52, 55, 57, 60], 45),  # Am7
    ([48, 52, 55, 59], 36),  # Cmaj7
]
PENTATONIC = [72, 74, 76, 79, 81, 84]  # C major pentatonic, octave 5

LENGTH = int(len(PROGRESSION) * BAR * RATE)
left = [0.0] * LENGTH
right = [0.0] * LENGTH


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def add(start, samples, pan):
    """Mixes mono samples in at `start` seconds, wrapping past the loop end."""
    gain_l = math.cos(pan * math.pi / 2)
    gain_r = math.sin(pan * math.pi / 2)
    offset = int(start * RATE)
    for i, value in enumerate(samples):
        j = (offset + i) % LENGTH
        left[j] += value * gain_l
        right[j] += value * gain_r


def pad(midi, hold, detune):
    f = freq(midi) + detune
    attack, release = 1.8, 2.5
    total = int((hold + release) * RATE)
    out = []
    for i in range(total):
        t = i / RATE
        if t < attack:
            env = math.sin(t / attack * math.pi / 2) ** 2
        elif t < hold:
            env = 1.0
        else:
            env = math.cos((t - hold) / release * math.pi / 2) ** 2
        phase = 2 * math.pi * f * t
        out.append(env * (math.sin(phase) + 0.2 * math.sin(2 * phase)) * 0.045)
    return out


def bass(midi, hold):
    f = freq(midi)
    total = int((hold + 1.5) * RATE)
    out = []
    for i in range(total):
        t = i / RATE
        env = min(1.0, t / 0.4) * (1.0 if t < hold else math.cos((t - hold) / 1.5 * math.pi / 2) ** 2)
        phase = 2 * math.pi * f * t
        out.append(env * (math.sin(phase) + 0.15 * math.sin(2 * phase)) * 0.11)
    return out


def bell(midi):
    f = freq(midi)
    out = []
    for i in range(int(3.5 * RATE)):
        t = i / RATE
        attack = min(1.0, t / 0.01)
        phase = 2 * math.pi * f * t
        value = (math.sin(phase) * math.exp(-t / 1.1)
                 + 0.3 * math.sin(2 * phase) * math.exp(-t / 0.5)
                 + 0.08 * math.sin(3 * phase) * math.exp(-t / 0.25))
        out.append(attack * value * 0.12)
    return out


rng = random.Random(7)
for index, (voicing, root) in enumerate(PROGRESSION):
    start = index * BAR
    for n, midi in enumerate(voicing):
        add(start, pad(midi, BAR, -0.5), 0.3 + 0.1 * n)
        add(start, pad(midi, BAR, 0.5), 0.7 - 0.1 * n)
    add(start, bass(root, BAR), 0.5)

    # Two or three soft bell notes per bar, favouring the chord's own tones.
    chord_classes = {m % 12 for m in voicing}
    beats = sorted(rng.sample([0, 1, 1.5, 2, 2.5, 3], rng.choice([2, 2, 3])))
    for beat in beats:
        options = [m for m in PENTATONIC if m % 12 in chord_classes] or PENTATONIC
        note = bell(rng.choice(options))
        pan = rng.uniform(0.3, 0.7)
        at = start + beat * BEAT
        add(at, note, pan)
        add(at + 0.75, [v * 0.35 for v in note], 1 - pan)  # ping-pong echoes
        add(at + 1.5, [v * 0.12 for v in note], pan)

peak = max(max(abs(v) for v in left), max(abs(v) for v in right))
scale = 0.7 / peak

with tempfile.TemporaryDirectory() as tmp:
    wav_path = Path(tmp) / "calm-loop.wav"
    with wave.open(str(wav_path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        frames = bytearray()
        for l, r in zip(left, right):
            frames += struct.pack("<hh", int(l * scale * 32767), int(r * scale * 32767))
        wav.writeframes(bytes(frames))
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", str(wav_path), str(OUT)], check=True)

print(f"Wrote {OUT} ({LENGTH / RATE:.0f}s loop)")
