#!/usr/bin/env python3
"""Synthesizes the background loops played during a puzzle.

Each track is a seamless stereo loop (pads, bass and a sparse lead with echoes)
written to PuzzliumFeatures/Resources/<name>.m4a. Every note tail wraps around
the end of the buffer, so the loop has no seam.

Usage: python3 scripts/generate_music.py [track ...]   (needs macOS `afconvert`)
With no arguments every track is rebuilt.
"""

import math
import random
import struct
import subprocess
import sys
import tempfile
import wave
from functools import lru_cache
from pathlib import Path

RATE = 24000
RESOURCES = Path(__file__).resolve().parent.parent / "Packages/PuzzliumKit/Sources/PuzzliumFeatures/Resources"


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


class Mix:
    def __init__(self, seconds):
        self.length = int(seconds * RATE)
        self.left = [0.0] * self.length
        self.right = [0.0] * self.length

    def add(self, start, samples, pan, gain=1.0):
        """Mixes mono samples in at `start` seconds, wrapping past the loop end."""
        gain_l = math.cos(pan * math.pi / 2) * gain
        gain_r = math.sin(pan * math.pi / 2) * gain
        offset = int(start * RATE)
        for i, value in enumerate(samples):
            j = (offset + i) % self.length
            self.left[j] += value * gain_l
            self.right[j] += value * gain_r

    def write(self, name):
        peak = max(max(abs(v) for v in self.left), max(abs(v) for v in self.right))
        scale = 0.7 / peak
        out = RESOURCES / f"{name}.m4a"
        with tempfile.TemporaryDirectory() as tmp:
            wav_path = Path(tmp) / f"{name}.wav"
            with wave.open(str(wav_path), "wb") as wav:
                wav.setnchannels(2)
                wav.setsampwidth(2)
                wav.setframerate(RATE)
                frames = bytearray()
                for l, r in zip(self.left, self.right):
                    frames += struct.pack("<hh", int(l * scale * 32767), int(r * scale * 32767))
                wav.writeframes(bytes(frames))
            subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", str(wav_path), str(out)], check=True)
        print(f"Wrote {out} ({self.length / RATE:.0f}s loop)")


# Voices. Cached because the same note is struck many times per track.

@lru_cache(maxsize=None)
def pad(midi, hold, detune, bright=0.2, level=0.045):
    f = freq(midi) + detune
    attack, release = 1.8, 2.5
    out = []
    for i in range(int((hold + release) * RATE)):
        t = i / RATE
        if t < attack:
            env = math.sin(t / attack * math.pi / 2) ** 2
        elif t < hold:
            env = 1.0
        else:
            env = math.cos((t - hold) / release * math.pi / 2) ** 2
        phase = 2 * math.pi * f * t
        out.append(env * (math.sin(phase) + bright * math.sin(2 * phase)) * level)
    return tuple(out)


@lru_cache(maxsize=None)
def bass(midi, hold, level=0.11):
    f = freq(midi)
    out = []
    for i in range(int((hold + 1.5) * RATE)):
        t = i / RATE
        env = min(1.0, t / 0.4) * (1.0 if t < hold else math.cos((t - hold) / 1.5 * math.pi / 2) ** 2)
        phase = 2 * math.pi * f * t
        out.append(env * (math.sin(phase) + 0.15 * math.sin(2 * phase)) * level)
    return tuple(out)


@lru_cache(maxsize=None)
def bell(midi, decay=1.1, length=3.5):
    f = freq(midi)
    out = []
    for i in range(int(length * RATE)):
        t = i / RATE
        attack = min(1.0, t / 0.01)
        phase = 2 * math.pi * f * t
        value = (math.sin(phase) * math.exp(-t / decay)
                 + 0.3 * math.sin(2 * phase) * math.exp(-t / (decay * 0.45))
                 + 0.08 * math.sin(3 * phase) * math.exp(-t / (decay * 0.23)))
        out.append(attack * value * 0.12)
    return tuple(out)


@lru_cache(maxsize=None)
def tine(midi):
    """Music-box comb: bright, short, with a slightly inharmonic overtone."""
    f = freq(midi)
    out = []
    for i in range(int(2.0 * RATE)):
        t = i / RATE
        attack = min(1.0, t / 0.004)
        phase = 2 * math.pi * f * t
        value = (math.sin(phase) * math.exp(-t / 0.55)
                 + 0.25 * math.sin(2.76 * phase) * math.exp(-t / 0.12)
                 + 0.1 * math.sin(5.4 * phase) * math.exp(-t / 0.05))
        out.append(attack * value * 0.1)
    return tuple(out)


@lru_cache(maxsize=None)
def epiano(midi):
    """Soft electric-piano pluck with a gentle tremolo."""
    f = freq(midi)
    out = []
    for i in range(int(3.0 * RATE)):
        t = i / RATE
        attack = min(1.0, t / 0.008)
        phase = 2 * math.pi * f * t
        tremolo = 1 - 0.15 * (1 - math.cos(2 * math.pi * 4.5 * t)) / 2
        value = (math.sin(phase) * math.exp(-t / 0.9)
                 + 0.4 * math.sin(2 * phase) * math.exp(-t / 0.18)
                 + 0.15 * math.sin(phase + 1.5 * math.sin(phase)) * math.exp(-t / 0.3))
        out.append(attack * tremolo * value * 0.11)
    return tuple(out)


@lru_cache(maxsize=None)
def flute(midi, hold):
    """Breathy sine lead with delayed vibrato."""
    f = freq(midi)
    attack, release = 0.12, 0.45
    out = []
    phase = 0.0
    for i in range(int((hold + release) * RATE)):
        t = i / RATE
        if t < attack:
            env = t / attack
        elif t < hold:
            env = 1.0
        else:
            env = math.cos((t - hold) / release * math.pi / 2) ** 2
        vibrato = 1 + 0.004 * min(1.0, t / 0.6) * math.sin(2 * math.pi * 5 * t)
        phase += 2 * math.pi * f * vibrato / RATE
        out.append(env * (math.sin(phase) + 0.12 * math.sin(2 * phase) + 0.05 * math.sin(3 * phase)) * 0.085)
    return tuple(out)


def chords(mix, progression, bar, bright=0.2, pad_level=0.045, bass_level=0.11):
    for index, (voicing, root) in enumerate(progression):
        start = index * bar
        for n, midi in enumerate(voicing):
            add_pan = 0.1 * n
            mix.add(start, pad(midi, bar, -0.5, bright, pad_level), 0.3 + add_pan)
            mix.add(start, pad(midi, bar, 0.5, bright, pad_level), 0.7 - add_pan)
        mix.add(start, bass(root, bar, bass_level), 0.5)


def echoed(mix, at, note, pan, beat, feedback=(0.35, 0.12)):
    mix.add(at, note, pan)
    for k, gain in enumerate(feedback, start=1):
        mix.add(at + 0.75 * beat * k, note, pan if k % 2 == 0 else 1 - pan, gain)  # ping-pong


def chord_tones(scale, voicing):
    classes = {m % 12 for m in voicing}
    return [m for m in scale if m % 12 in classes] or scale


# Tracks

def calm():
    beat = 1.0  # 60 bpm
    bar = 4 * beat
    progression = [
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
    pentatonic = [72, 74, 76, 79, 81, 84]  # C major
    mix = Mix(len(progression) * bar)
    chords(mix, progression, bar)
    rng = random.Random(7)
    for index, (voicing, _) in enumerate(progression):
        beats = sorted(rng.sample([0, 1, 1.5, 2, 2.5, 3], rng.choice([2, 2, 3])))
        for b in beats:
            echoed(mix, index * bar + b * beat, bell(rng.choice(chord_tones(pentatonic, voicing))), rng.uniform(0.3, 0.7), beat)
    return mix


def rain():
    """A minor, 56 bpm: electric-piano drops over soft rainfall."""
    beat = 60 / 56
    bar = 4 * beat
    progression = [
        ([57, 60, 64, 67], 45),  # Am7
        ([53, 57, 60, 64], 41),  # Fmaj7
        ([48, 52, 55, 59], 36),  # Cmaj7
        ([50, 55, 59, 64], 43),  # G6
        ([57, 60, 64, 67], 45),  # Am7
        ([50, 53, 57, 60], 38),  # Dm7
        ([53, 57, 60, 64], 41),  # Fmaj7
        ([52, 57, 59, 62], 40),  # E7sus4
    ]
    pentatonic = [69, 72, 74, 76, 79, 81]  # A minor
    mix = Mix(len(progression) * bar)
    chords(mix, progression, bar, bright=0.1, pad_level=0.04)
    rng = random.Random(11)
    for index, (voicing, _) in enumerate(progression):
        beats = sorted(rng.sample([0, 0.5, 1.5, 2, 2.5, 3, 3.5], rng.choice([2, 3, 3])))
        for b in beats:
            echoed(mix, index * bar + b * beat, epiano(rng.choice(chord_tones(pentatonic, voicing))), rng.uniform(0.25, 0.75), beat)

    # Rainfall: low-passed noise that swells slowly, period dividing the loop so it stays seamless.
    noise_rng = random.Random(3)
    smooth_l = smooth_r = 0.0
    for i in range(mix.length):
        swell = 0.75 + 0.25 * math.sin(2 * math.pi * 2 * i / mix.length)
        smooth_l += 0.08 * (noise_rng.uniform(-1, 1) - smooth_l)
        smooth_r += 0.08 * (noise_rng.uniform(-1, 1) - smooth_r)
        mix.left[i] += smooth_l * 0.05 * swell
        mix.right[i] += smooth_r * 0.05 * swell
    return mix


def music_box():
    """G major, 72 bpm: a wind-up music box arpeggio."""
    beat = 60 / 72
    bar = 4 * beat
    progression = [
        ([55, 59, 62, 66], 43),  # Gmaj7
        ([52, 55, 59, 62], 40),  # Em7
        ([48, 52, 55, 59], 36),  # Cmaj7
        ([50, 54, 57, 59], 38),  # D6
        ([55, 59, 62, 66], 43),  # Gmaj7
        ([47, 50, 54, 57], 35),  # Bm7
        ([48, 52, 55, 59], 36),  # Cmaj7
        ([50, 55, 57, 62], 38),  # Dsus4
    ] * 2  # same chords twice, the skipped teeth differ
    mix = Mix(len(progression) * bar)
    chords(mix, progression, bar, bright=0.05, pad_level=0.03, bass_level=0.08)
    rng = random.Random(5)
    pattern = [0, 1, 2, 3, 2, 1, 2, 0]  # up-and-down through the chord, eighth notes
    for index, (voicing, _) in enumerate(progression):
        tones = sorted(m + 24 for m in voicing)
        for step, which in enumerate(pattern):
            if step and rng.random() < 0.18:
                continue  # a skipped tooth keeps it from sounding mechanical
            at = index * bar + step * beat / 2 + rng.uniform(0, 0.015)
            mix.add(at, tine(tones[which]), 0.35 + 0.1 * which)
    return mix


def night():
    """D minor, 50 bpm: deep pads and slow, distant bells."""
    beat = 60 / 50
    bar = 4 * beat
    progression = [
        ([50, 53, 57, 64], 38),  # Dm9
        ([46, 50, 53, 57], 34),  # Bbmaj7
        ([50, 53, 55, 58], 43),  # Gm7
        ([48, 52, 55, 57], 45),  # Am7
        ([50, 53, 57, 64], 38),  # Dm9
        ([46, 50, 53, 57], 34),  # Bbmaj7
        ([50, 53, 57, 58], 43),  # Gm9
        ([52, 55, 57, 62], 45),  # A7sus4
    ]
    pentatonic = [74, 77, 79, 81, 84, 86]  # D minor
    mix = Mix(len(progression) * bar)
    chords(mix, progression, bar, bright=0.08, pad_level=0.05, bass_level=0.12)
    rng = random.Random(23)
    for index, (voicing, _) in enumerate(progression):
        beats = sorted(rng.sample([0, 1, 2, 2.5, 3], rng.choice([1, 2, 2])))
        for b in beats:
            note = bell(rng.choice(chord_tones(pentatonic, voicing)) - 12, 2.0, 5.0)
            echoed(mix, index * bar + b * beat, note, rng.uniform(0.25, 0.75), beat, (0.4, 0.2, 0.08))
    return mix


def meadow():
    """D major, 66 bpm: a lazy flute tune over warm chords."""
    beat = 60 / 66
    bar = 4 * beat
    progression = [
        ([50, 54, 57, 61], 38),  # Dmaj7
        ([50, 54, 55, 59], 43),  # Gmaj7
        ([50, 54, 57, 59], 35),  # Bm7
        ([50, 52, 54, 57], 45),  # A6sus
        ([50, 54, 57, 61], 38),  # Dmaj7
        ([50, 52, 55, 59], 40),  # Em7
        ([50, 54, 55, 59], 43),  # Gmaj7
        ([50, 52, 57, 59], 45),  # Asus4
    ] * 2  # same chords twice under a new tune
    pentatonic = [74, 76, 78, 81, 83, 86]  # D major
    mix = Mix(len(progression) * bar)
    chords(mix, progression, bar, bright=0.25, pad_level=0.04)
    rng = random.Random(17)
    for index, (voicing, _) in enumerate(progression):
        if index % 2:  # a phrase every other bar, the next bar breathes
            continue
        at = index * bar + rng.choice([0, 0.5, 1]) * beat
        note = rng.choice(chord_tones(pentatonic, voicing))
        for _ in range(rng.choice([3, 4, 4, 5])):
            length = rng.choice([0.5, 1, 1, 1.5]) * beat
            mix.add(at, flute(note, length * 0.9), 0.55)
            mix.add(at + 0.75 * beat, flute(note, length * 0.9), 0.3, 0.2)
            at += length
            step = pentatonic.index(note) + rng.choice([-2, -1, -1, 1, 1, 2])
            note = pentatonic[max(0, min(len(pentatonic) - 1, step))]
    return mix


TRACKS = {
    "calm-loop": calm,
    "rain-loop": rain,
    "music-box-loop": music_box,
    "night-loop": night,
    "meadow-loop": meadow,
}

for name in sys.argv[1:] or TRACKS:
    TRACKS[name]().write(name)
