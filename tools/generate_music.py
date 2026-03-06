#!/usr/bin/env python3
"""
Generate 8-bit style looping music tracks for Tetris
Creates 9 WAV files (3 packs x 3 tiers) using only Python stdlib (wave, struct, math, os)
Stardew Valley chiptune style.
"""

import wave
import struct
import math
import os

# Audio settings
SAMPLE_RATE = 44100
MAX_AMPLITUDE = 32767
MASTER_GAIN = 0.32
WARM_PITCH_FACTOR = 0.96
WARM_LOWPASS_HZ = 3200.0

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "music")

# Note frequencies based on A4 = 440 Hz
NOTES = {
    "C": -9,
    "C#": -8,
    "D": -7,
    "D#": -6,
    "E": -5,
    "F": -4,
    "F#": -3,
    "G": -2,
    "G#": -1,
    "A": 0,
    "A#": 1,
    "B": 2,
}


def get_freq(note_name, octave):
    """Calculate frequency for a given note and octave."""
    semitones = NOTES[note_name] + (octave - 4) * 12
    return 440.0 * (2.0 ** (semitones / 12.0))


def _osc_sample_float(freq, t, waveform):
    """Generate a single sample float value [-1.0, 1.0] for the given waveform."""
    if freq <= 0:
        return 0.0

    tuned_freq = freq * WARM_PITCH_FACTOR
    omega = 2 * math.pi * tuned_freq * t

    if waveform == "square":
        v1 = math.sin(omega)
        v3 = 0.24 * math.sin(omega * 3.0)
        v5 = 0.12 * math.sin(omega * 5.0)
        v7 = 0.06 * math.sin(omega * 7.0)
        value = (v1 + v3 + v5 + v7) / 1.42
        return value
    if waveform == "sine":
        return math.sin(omega)
    if waveform == "triangle":
        # Triangle wave from Fourier series: sin harmonics, alternating signs, 1/n^2 amplitude falloff
        v1 = math.sin(omega)
        v3 = -math.sin(omega * 3.0) / 9.0
        v5 = math.sin(omega * 5.0) / 25.0
        v7 = -math.sin(omega * 7.0) / 49.0
        v9 = math.sin(omega * 9.0) / 81.0
        # Normalization factor to keep peak near 1.0 (8 / pi^2 ~= 0.81056)
        value = (v1 + v3 + v5 + v7 + v9) * 0.81056
        return value
    return 0.0


def generate_note(freq, duration_s, waveform="square", decay_fraction=0.15):
    """Generate samples for a single note, returning a list of floats."""
    num_samples = int(SAMPLE_RATE * duration_s)
    samples = []

    if freq <= 0:
        return [0.0] * num_samples

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        value = _osc_sample_float(freq, t, waveform)

        # Envelope to prevent pops
        attack_samples = min(int(SAMPLE_RATE * 0.005), num_samples // 4)
        if i < attack_samples:
            env = i / attack_samples
        else:
            decay_samples = int(num_samples * decay_fraction)
            if i > num_samples - decay_samples:
                env = max(
                    0.0, 1.0 - (i - (num_samples - decay_samples)) / decay_samples
                )
            else:
                env = 1.0

        samples.append(value * env)
    return samples


def generate_track(sequence, bpm, waveform="square", decay_fraction=0.15):
    """Generate a full track from a sequence of (freq, beats) tuples."""
    beat_duration_s = 60.0 / bpm
    samples = []
    for freq, beats in sequence:
        duration_s = beats * beat_duration_s
        samples.extend(generate_note(freq, duration_s, waveform, decay_fraction))
    return samples


def _apply_lowpass(samples, cutoff_hz):
    """Apply lowpass filter to the mixed samples."""
    if not samples:
        return samples
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    dt = 1.0 / SAMPLE_RATE
    alpha = dt / (rc + dt)
    filtered = []
    y = float(samples[0])
    filtered.append(int(y))
    for x in samples[1:]:
        y += alpha * (x - y)
        filtered.append(int(y))
    return filtered


def mix_tracks(tracks_samples):
    """Mix multiple float tracks together, normalize, and apply lowpass."""
    max_len = max(len(t) for t in tracks_samples)
    mixed_floats = []

    for i in range(max_len):
        val = sum(t[i] if i < len(t) else 0.0 for t in tracks_samples)
        mixed_floats.append(val)

    peak = max(abs(v) for v in mixed_floats) if mixed_floats else 1.0
    target_peak = 0.7
    scale_factor = target_peak / peak if peak > 0 else 1.0

    mixed_ints = []
    for v in mixed_floats:
        scaled_v = v * scale_factor * MAX_AMPLITUDE * MASTER_GAIN
        mixed_ints.append(int(scaled_v))

    return _apply_lowpass(mixed_ints, WARM_LOWPASS_HZ)


def save_wav(filename, samples):
    """Save samples as a WAV file."""
    with wave.open(filename, "w") as f:
        f.setnchannels(1)  # mono
        f.setsampwidth(2)  # 16-bit
        f.setframerate(SAMPLE_RATE)
        for s in samples:
            f.writeframes(struct.pack("<h", max(-32768, min(32767, int(s)))))


# --- Pack 1: Spring Morning (C Major) ---
# Bright, cheerful, lilting melody, gentle bass
def get_p1_melody(octave_shift=0):
    o = 4 + octave_shift
    return [
        (get_freq("C", o), 1.5),
        (get_freq("D", o), 0.5),
        (get_freq("E", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("A", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("C", o + 1), 2.0),
        (get_freq("A", o), 1.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 1.0),
        (get_freq("C", o), 1.0),
        (get_freq("D", o), 2.0),
        (0, 2.0),
        (get_freq("C", o), 1.5),
        (get_freq("D", o), 0.5),
        (get_freq("E", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("A", o), 1.0),
        (get_freq("C", o + 1), 1.0),
        (get_freq("E", o + 1), 2.0),
        (get_freq("D", o + 1), 1.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("A", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("C", o), 4.0),
    ]


def get_p1_bass():
    o = 2
    return [
        (get_freq("C", o), 2.0),
        (get_freq("C", o), 2.0),
        (get_freq("F", o), 2.0),
        (get_freq("C", o), 2.0),
        (get_freq("F", o), 2.0),
        (get_freq("C", o), 2.0),
        (get_freq("G", o), 2.0),
        (get_freq("G", o - 1), 2.0),
        (get_freq("C", o), 2.0),
        (get_freq("C", o), 2.0),
        (get_freq("F", o), 2.0),
        (get_freq("A", o), 2.0),
        (get_freq("G", o), 2.0),
        (get_freq("G", o - 1), 2.0),
        (get_freq("C", o), 4.0),
    ]


def get_p1_arp():
    o = 4
    return [
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("B", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("B", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("E", o + 1), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("B", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("B", o - 1), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
    ]


def compose_pack1_tier1():
    bpm = 105
    t1 = generate_track(get_p1_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p1_bass(), bpm, "triangle", 0.2)
    return mix_tracks([t1, t2])


def compose_pack1_tier2():
    bpm = 125
    t1 = generate_track(get_p1_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p1_arp(), bpm, "triangle", 0.1)
    t3 = generate_track(get_p1_bass(), bpm, "triangle", 0.2)
    return mix_tracks([t1, t2, t3])


def compose_pack1_tier3():
    bpm = 145
    t1 = generate_track(get_p1_melody(1), bpm, "square", 0.15)
    t2 = generate_track(get_p1_arp(), bpm, "triangle", 0.1)
    # Driving bass
    bass_driving = []
    for f, d in get_p1_bass():
        if d >= 1.0:
            for _ in range(int(d / 0.5)):
                bass_driving.append((f, 0.5))
        else:
            bass_driving.append((f, d))
    t3 = generate_track(bass_driving, bpm, "square", 0.1)
    return mix_tracks([t1, t2, t3])


# --- Pack 2: Autumn Fields (D Major) ---
# Warmer, flowing stepwise, nostalgic
def get_p2_melody():
    o = 4
    return [
        (get_freq("F#", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("A", o), 1.5),
        (get_freq("B", o), 0.5),
        (get_freq("A", o), 2.0),
        (get_freq("D", o), 2.0),
        (get_freq("E", o), 1.0),
        (get_freq("F#", o), 1.0),
        (get_freq("G", o), 1.5),
        (get_freq("F#", o), 0.5),
        (get_freq("E", o), 4.0),
        (get_freq("F#", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("A", o), 1.5),
        (get_freq("B", o), 0.5),
        (get_freq("D", o + 1), 2.0),
        (get_freq("A", o), 2.0),
        (get_freq("B", o), 1.0),
        (get_freq("A", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("E", o), 1.0),
        (get_freq("D", o), 4.0),
    ]


def get_p2_bass():
    o = 2
    return [
        (get_freq("D", o), 2.0),
        (get_freq("D", o), 2.0),
        (get_freq("F#", o), 2.0),
        (get_freq("B", o - 1), 2.0),
        (get_freq("E", o), 2.0),
        (get_freq("A", o - 1), 2.0),
        (get_freq("E", o), 2.0),
        (get_freq("A", o - 1), 2.0),
        (get_freq("D", o), 2.0),
        (get_freq("D", o), 2.0),
        (get_freq("B", o - 1), 2.0),
        (get_freq("F#", o), 2.0),
        (get_freq("G", o - 1), 2.0),
        (get_freq("A", o - 1), 2.0),
        (get_freq("D", o), 4.0),
    ]


def get_p2_arp():
    o = 3
    return [
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("B", o - 1), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("B", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C#", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("B", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C#", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("B", o - 1), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("D", o + 1), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("G", o - 1), 0.5),
        (get_freq("B", o - 1), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("B", o - 1), 0.5),
        (get_freq("A", o - 1), 0.5),
        (get_freq("C#", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("C#", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F#", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F#", o), 0.5),
    ]


def compose_pack2_tier1():
    bpm = 100
    t1 = generate_track(get_p2_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p2_bass(), bpm, "triangle", 0.25)
    return mix_tracks([t1, t2])


def compose_pack2_tier2():
    bpm = 120
    t1 = generate_track(get_p2_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p2_arp(), bpm, "triangle", 0.12)
    t3 = generate_track(get_p2_bass(), bpm, "triangle", 0.2)
    return mix_tracks([t1, t2, t3])


def compose_pack2_tier3():
    bpm = 145
    t1 = generate_track(get_p2_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p2_arp(), bpm, "triangle", 0.12)
    bass_driving = []
    for f, d in get_p2_bass():
        if d >= 1.0:
            for _ in range(int(d / 0.5)):
                bass_driving.append((f, 0.5))
        else:
            bass_driving.append((f, d))
    t3 = generate_track(bass_driving, bpm, "square", 0.1)
    return mix_tracks([t1, t2, t3])


# --- Pack 3: Starlit Farm (F Major) ---
# Dreamy, peaceful, wide intervals, soft bass
def get_p3_melody():
    o = 4
    return [
        (get_freq("A", o), 2.0),
        (get_freq("F", o), 1.0),
        (get_freq("C", o), 1.0),
        (get_freq("D", o), 1.5),
        (get_freq("F", o), 0.5),
        (get_freq("C", o), 2.0),
        (get_freq("A#", o), 1.5),
        (get_freq("A", o), 0.5),
        (get_freq("G", o), 1.0),
        (get_freq("F", o), 1.0),
        (get_freq("G", o), 4.0),
        (get_freq("A", o), 2.0),
        (get_freq("C", o + 1), 1.0),
        (get_freq("F", o + 1), 1.0),
        (get_freq("E", o + 1), 1.5),
        (get_freq("D", o + 1), 0.5),
        (get_freq("C", o + 1), 2.0),
        (get_freq("A#", o), 1.0),
        (get_freq("A", o), 1.0),
        (get_freq("G", o), 1.0),
        (get_freq("E", o), 1.0),
        (get_freq("F", o), 4.0),
    ]


def get_p3_bass():
    o = 2
    return [
        (get_freq("F", o), 4.0),
        (get_freq("A#", o - 1), 2.0),
        (get_freq("F", o), 2.0),
        (get_freq("G", o - 1), 2.0),
        (get_freq("G", o - 1), 2.0),
        (get_freq("C", o), 4.0),
        (get_freq("F", o), 4.0),
        (get_freq("A#", o - 1), 2.0),
        (get_freq("A", o - 1), 2.0),
        (get_freq("A#", o - 1), 2.0),
        (get_freq("C", o), 2.0),
        (get_freq("F", o - 1), 4.0),
    ]


def get_p3_arp():
    o = 4
    return [
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A#", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("A#", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("A#", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("C", o + 1), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A#", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("D", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A#", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("G", o), 0.5),
        (get_freq("E", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("C", o), 0.5),
        (get_freq("F", o), 0.5),
        (get_freq("A", o), 0.5),
        (get_freq("F", o), 0.5),
    ]


def compose_pack3_tier1():
    bpm = 100
    t1 = generate_track(get_p3_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p3_bass(), bpm, "triangle", 0.3)
    return mix_tracks([t1, t2])


def compose_pack3_tier2():
    bpm = 120
    t1 = generate_track(get_p3_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p3_arp(), bpm, "triangle", 0.15)
    t3 = generate_track(get_p3_bass(), bpm, "triangle", 0.3)
    return mix_tracks([t1, t2, t3])


def compose_pack3_tier3():
    bpm = 140
    t1 = generate_track(get_p3_melody(), bpm, "square", 0.15)
    t2 = generate_track(get_p3_arp(), bpm, "triangle", 0.12)
    bass_driving = []
    for f, d in get_p3_bass():
        if d >= 1.0:
            for _ in range(int(d / 0.5)):
                bass_driving.append((f, 0.5))
        else:
            bass_driving.append((f, d))
    t3 = generate_track(bass_driving, bpm, "square", 0.1)
    return mix_tracks([t1, t2, t3])


def main():
    # Clean up old files
    for old_file in ["tier_1.wav", "tier_2.wav", "tier_3.wav"]:
        old_path = os.path.join(OUTPUT_DIR, old_file)
        if os.path.exists(old_path):
            os.remove(old_path)
            print(f"Removed old file: {old_path}")

    print(f"Generating music tracks in: {OUTPUT_DIR}")
    print(f"Sample rate: {SAMPLE_RATE}Hz, 16-bit mono")
    print("-" * 50)

    tracks = [
        ("pack_1", "tier_1.wav", compose_pack1_tier1),
        ("pack_1", "tier_2.wav", compose_pack1_tier2),
        ("pack_1", "tier_3.wav", compose_pack1_tier3),
        ("pack_2", "tier_1.wav", compose_pack2_tier1),
        ("pack_2", "tier_2.wav", compose_pack2_tier2),
        ("pack_2", "tier_3.wav", compose_pack2_tier3),
        ("pack_3", "tier_1.wav", compose_pack3_tier1),
        ("pack_3", "tier_2.wav", compose_pack3_tier2),
        ("pack_3", "tier_3.wav", compose_pack3_tier3),
    ]

    for pack, filename, generator in tracks:
        pack_dir = os.path.join(OUTPUT_DIR, pack)
        os.makedirs(pack_dir, exist_ok=True)

        output_path = os.path.join(pack_dir, filename)
        samples = generator()
        save_wav(output_path, samples)
        duration = len(samples) / SAMPLE_RATE
        print(f"Created: {pack}/{filename} ({duration:.2f}s, {len(samples)} samples)")

    print("-" * 50)
    print(f"✓ Successfully generated {len(tracks)} music tracks")


if __name__ == "__main__":
    main()
