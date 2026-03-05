#!/usr/bin/env python3
"""
Generate 8-bit style sound effects for Tetris
Creates 10 WAV files using only Python stdlib (wave, struct, math)
"""

import wave
import struct
import math
import os

# Audio settings
SAMPLE_RATE = 44100
MAX_AMPLITUDE = 32767

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")


def generate_tone(freq, duration_ms, waveform="square", decay=True):
    """Generate samples for a tone."""
    num_samples = int(SAMPLE_RATE * duration_ms / 1000)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        if waveform == "square":
            value = (
                MAX_AMPLITUDE
                if math.sin(2 * math.pi * freq * t) >= 0
                else -MAX_AMPLITUDE
            )
        elif waveform == "sine":
            value = int(MAX_AMPLITUDE * math.sin(2 * math.pi * freq * t))
        if decay:
            value = int(value * (1.0 - i / num_samples))  # linear decay
        samples.append(value)
    return samples


def generate_sweep(start_freq, end_freq, duration_ms, waveform="square"):
    """Generate a frequency sweep (glissando effect)."""
    num_samples = int(SAMPLE_RATE * duration_ms / 1000)
    samples = []
    for i in range(num_samples):
        t = i / num_samples  # 0.0 to 1.0
        freq = start_freq + (end_freq - start_freq) * t
        time = i / SAMPLE_RATE
        if waveform == "square":
            value = (
                MAX_AMPLITUDE
                if math.sin(2 * math.pi * freq * time) >= 0
                else -MAX_AMPLITUDE
            )
        else:
            value = int(MAX_AMPLITUDE * math.sin(2 * math.pi * freq * time))
        value = int(value * (1.0 - t * 0.3))  # slight decay
        samples.append(value)
    return samples


def generate_arpeggio(freqs, note_duration_ms):
    """Generate an arpeggio from a list of frequencies."""
    samples = []
    for freq in freqs:
        samples.extend(
            generate_tone(freq, note_duration_ms, waveform="square", decay=True)
        )
    return samples


def generate_two_tone(freq1, freq2, duration_ms):
    """Generate a two-tone blip."""
    samples = []
    half_duration = duration_ms / 2
    samples.extend(generate_tone(freq1, half_duration, waveform="square", decay=False))
    samples.extend(generate_tone(freq2, half_duration, waveform="square", decay=True))
    return samples


def save_wav(filename, samples):
    """Save samples as a WAV file."""
    with wave.open(filename, "w") as f:
        f.setnchannels(1)  # mono
        f.setsampwidth(2)  # 16-bit
        f.setframerate(SAMPLE_RATE)
        for s in samples:
            f.writeframes(struct.pack("<h", max(-32768, min(32767, int(s)))))


def main():
    """Generate all sound effects."""
    # Create output directory if it doesn't exist
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print(f"Generating sound effects in: {OUTPUT_DIR}")
    print(f"Sample rate: {SAMPLE_RATE}Hz, 16-bit mono")
    print("-" * 50)

    sfx_definitions = [
        ("move.wav", lambda: generate_tone(440, 50, waveform="square", decay=True)),
        ("rotate.wav", lambda: generate_tone(660, 50, waveform="square", decay=True)),
        (
            "hard_drop.wav",
            lambda: generate_tone(110, 100, waveform="square", decay=True),
        ),
        (
            "soft_drop.wav",
            lambda: generate_tone(330, 30, waveform="square", decay=True),
        ),
        ("line_clear.wav", lambda: generate_sweep(440, 880, 200, waveform="square")),
        ("tetris_clear.wav", lambda: generate_sweep(440, 1760, 400, waveform="square")),
        ("hold.wav", lambda: generate_two_tone(440, 660, 80)),
        ("lock.wav", lambda: generate_tone(220, 80, waveform="square", decay=True)),
        ("game_over.wav", lambda: generate_sweep(880, 110, 500, waveform="square")),
        (
            "level_up.wav",
            lambda: generate_arpeggio([523, 659, 784, 1047], 75),
        ),  # C-E-G-C
        # Combo SFX - escalating arpeggios
        ("combo_1.wav", lambda: generate_arpeggio([523, 659], 40)),  # C-E (2 notes)
        (
            "combo_2.wav",
            lambda: generate_arpeggio([587, 740, 880], 35),
        ),  # D-F#-A (3 notes)
        (
            "combo_3.wav",
            lambda: generate_arpeggio([659, 831, 988, 1175], 30),
        ),  # E-G#-B-D (4 notes)
        (
            "combo_high.wav",
            lambda: generate_arpeggio([784, 988, 1175, 1397, 1568], 25),
        ),  # G-B-D-E-G (5 notes)
    ]

    for filename, generator in sfx_definitions:
        output_path = os.path.join(OUTPUT_DIR, filename)
        samples = generator()
        save_wav(output_path, samples)
        print(f"Created: {output_path} ({len(samples)} samples)")

    print("-" * 50)
    print(f"✓ Successfully generated {len(sfx_definitions)} sound effects")


if __name__ == "__main__":
    main()
