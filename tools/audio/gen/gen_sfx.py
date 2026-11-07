#!/usr/bin/env python3
"""Reproducible sound effect generator for The Last Frame (TLF-064).

Generates short, mono 16-bit PCM WAV files under assets/audio/sfx/.
Deterministic mathematical synthesis using Python standard library (wave, struct, math).

Usage:
  python tools/audio/gen/gen_sfx.py           # Generates all audio files
  python tools/audio/gen/gen_sfx.py --verify  # Verifies committed files match byte-for-byte
"""

import argparse
import hashlib
import io
import math
import os
import random
import struct
import sys
import wave

SAMPLE_RATE = 22050

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
OUTPUT_DIR = os.path.join(REPO_ROOT, "assets", "audio", "sfx")


def _clamp(val, low=-32767, high=32767):
    return max(low, min(high, int(val)))


def _build_wav_bytes(samples, sample_rate=SAMPLE_RATE):
    """Encodes a float list (-1.0 to 1.0) into 16-bit mono PCM WAV bytes."""
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        packed = bytearray()
        for s in samples:
            val = _clamp(s * 32760.0)
            packed.extend(struct.pack("<h", val))
        wf.writeframes(packed)
    return buf.getvalue()


# --- Sound Synthesizers ----------------------------------------------------


def gen_ability_trace():
    """Soft sweep (rising 380 Hz -> 720 Hz -> 560 Hz with gentle harmonics)."""
    duration = 0.35
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Envelope: smooth attack, gentle release
        env = math.sin(math.pi * (t / duration)) ** 1.5
        # Pitch curve
        freq = 380.0 + 340.0 * math.sin(math.pi * (t / duration))
        phase = 2.0 * math.pi * freq * t
        s = 0.75 * math.sin(phase) + 0.25 * math.sin(phase * 2.0)
        samples.append(s * env * 0.85)
    return _build_wav_bytes(samples)


def gen_ability_rewind():
    """Backward tick (descending burst pulses 780 Hz -> 240 Hz)."""
    duration = 0.28
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    num_pulses = 6
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Frequency drops over time
        freq = 780.0 - 540.0 * (t / duration)
        # Flutter pulses
        pulse_env = math.sin(2.0 * math.pi * num_pulses * (t / duration)) ** 2
        overall_env = (1.0 - (t / duration)) ** 1.2
        phase = 2.0 * math.pi * freq * t
        s = 0.7 * math.sin(phase) + 0.3 * math.sin(phase * 1.5)
        samples.append(s * pulse_env * overall_env * 0.9)
    return _build_wav_bytes(samples)


def gen_ability_freeze():
    """Glassy stop (resonant high crystalline tone with sharp cutoff)."""
    duration = 0.32
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Attack within 5ms, sustained ring, damp at 0.25s
        if t < 0.005:
            env = t / 0.005
        elif t < 0.25:
            env = math.exp(-4.0 * (t - 0.005))
        else:
            env = math.exp(-4.0 * (0.25 - 0.005)) * math.exp(-25.0 * (t - 0.25))

        f1, f2, f3 = 1320.0, 2640.0, 660.0
        s = (
            0.60 * math.sin(2.0 * math.pi * f1 * t)
            + 0.30 * math.sin(2.0 * math.pi * f2 * t)
            + 0.10 * math.sin(2.0 * math.pi * f3 * t)
        )
        samples.append(s * env * 0.88)
    return _build_wav_bytes(samples)


def gen_echo_record_start():
    """Capture start (two rising chime tones: 523 Hz -> 784 Hz)."""
    duration = 0.22
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    t_split = 0.09
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        if t < t_split:
            sub_t = t / t_split
            env = math.sin(math.pi * sub_t)
            freq = 523.25  # C5
            s = math.sin(2.0 * math.pi * freq * t)
        else:
            sub_t = (t - t_split) / (duration - t_split)
            env = math.sin(math.pi * sub_t) ** 0.8
            freq = 783.99  # G5
            s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return _build_wav_bytes(samples)


def gen_echo_record_stop():
    """Capture stop (two falling chime tones: 784 Hz -> 523 Hz)."""
    duration = 0.22
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    t_split = 0.09
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        if t < t_split:
            sub_t = t / t_split
            env = math.sin(math.pi * sub_t)
            freq = 783.99  # G5
            s = math.sin(2.0 * math.pi * freq * t)
        else:
            sub_t = (t - t_split) / (duration - t_split)
            env = math.sin(math.pi * sub_t) ** 0.8
            freq = 523.25  # C5
            s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return _build_wav_bytes(samples)


def gen_echo_play():
    """Echo playback projection (warm chord with subtle vibrato)."""
    duration = 0.40
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration)) ** 1.3
        vibrato = 1.0 + 0.015 * math.sin(2.0 * math.pi * 7.5 * t)
        f1 = 440.0 * vibrato  # A4
        f2 = 554.37 * vibrato  # C#5
        s = 0.55 * math.sin(2.0 * math.pi * f1 * t) + 0.45 * math.sin(2.0 * math.pi * f2 * t)
        samples.append(s * env * 0.85)
    return _build_wav_bytes(samples)


def gen_ability_locked():
    """Refused / ability locked (dull low refusal thud / click)."""
    duration = 0.16
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-22.0 * t)
        # Low damped wave with initial click
        freq = 135.0
        s = 0.7 * math.sin(2.0 * math.pi * freq * t) + 0.3 * (
            1.0 if (int(t * 135.0 * 2) % 2 == 0) else -1.0
        )
        if t < 0.008:
            s += 0.5 * (1.0 - t / 0.008)
        samples.append(s * env * 0.88)
    return _build_wav_bytes(samples)


def gen_clock_tick():
    """23:59 digital clock tick (crisp micro-transient)."""
    duration = 0.06
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    rng = random.Random(42)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-85.0 * t)
        # Sharp high tone + transient noise
        tone = math.sin(2.0 * math.pi * 2100.0 * t)
        noise = (rng.random() * 2.0 - 1.0) * math.exp(-250.0 * t)
        s = 0.75 * tone + 0.25 * noise
        samples.append(s * env * 0.82)
    return _build_wav_bytes(samples)


def gen_operator_motif():
    """Faint second tick under the watch whenever the VOICE speaks."""
    duration = 0.30
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # First tick at t=0
        env1 = math.exp(-90.0 * t)
        s1 = math.sin(2.0 * math.pi * 1650.0 * t) * env1 * 0.80

        # Faint second shadow tick at t=0.10s
        s2 = 0.0
        if t >= 0.10:
            dt = t - 0.10
            env2 = math.exp(-85.0 * dt)
            s2 = math.sin(2.0 * math.pi * 1150.0 * dt) * env2 * 0.42

        samples.append(s1 + s2)
    return _build_wav_bytes(samples)


def gen_operator_sighting():
    """TLF-058 Operator vanish sting (eerie tritone descent)."""
    duration = 0.65
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration)) ** 1.1 * math.exp(-1.5 * t)
        pitch_drop = 1.0 - 0.22 * (t / duration)
        f1 = 440.0 * pitch_drop  # A4
        f2 = 622.25 * pitch_drop  # D#5 (tritone dissonance)
        tremolo = 1.0 + 0.15 * math.sin(2.0 * math.pi * 9.0 * t)
        s = 0.52 * math.sin(2.0 * math.pi * f1 * t) + 0.48 * math.sin(2.0 * math.pi * f2 * t)
        samples.append(s * env * tremolo * 0.82)
    return _build_wav_bytes(samples)


def gen_device_click():
    """Beat 10 street device latch (dual mechanical switch click)."""
    duration = 0.14
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Pulse 1 at t=0
        env1 = math.exp(-75.0 * t)
        s1 = math.sin(2.0 * math.pi * 1850.0 * t) * env1 * 0.80

        # Pulse 2 at t=0.024s (mechanical latch settling)
        s2 = 0.0
        if t >= 0.024:
            dt = t - 0.024
            env2 = math.exp(-80.0 * dt)
            s2 = math.sin(2.0 * math.pi * 980.0 * dt) * env2 * 0.65

        samples.append(s1 + s2)
    return _build_wav_bytes(samples)


# --- Registry ---

GENERATORS = {
    "sfx_ability_trace.wav": gen_ability_trace,
    "sfx_ability_rewind.wav": gen_ability_rewind,
    "sfx_ability_freeze.wav": gen_ability_freeze,
    "sfx_echo_record_start.wav": gen_echo_record_start,
    "sfx_echo_record_stop.wav": gen_echo_record_stop,
    "sfx_echo_play.wav": gen_echo_play,
    "sfx_ability_locked.wav": gen_ability_locked,
    "sfx_clock_tick.wav": gen_clock_tick,
    "sfx_operator_motif.wav": gen_operator_motif,
    "sfx_operator_sighting.wav": gen_operator_sighting,
    "sfx_device_click.wav": gen_device_click,
}


def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def main():
    parser = argparse.ArgumentParser(description="TLF-064 Audio SFX Generator")
    parser.add_argument("--verify", action="store_true", help="Verify committed files match generated bytes")
    args = parser.parse_args()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    if args.verify:
        all_ok = True
        print("=== Verifying TLF-064 Generated Audio Files ===")
        for filename, gen_fn in sorted(GENERATORS.items()):
            target_path = os.path.join(OUTPUT_DIR, filename)
            if not os.path.exists(target_path):
                print("FAIL  %-30s  FILE MISSING" % filename)
                all_ok = False
                continue
            with open(target_path, "rb") as fh:
                existing_bytes = fh.read()
            expected_bytes = gen_fn()
            if existing_bytes == expected_bytes:
                h = sha256_bytes(expected_bytes)[:12]
                print("OK    %-30s  MATCH (%s, %d bytes)" % (filename, h, len(expected_bytes)))
            else:
                h_exp = sha256_bytes(expected_bytes)[:12]
                h_act = sha256_bytes(existing_bytes)[:12]
                print("FAIL  %-30s  DIFFERS (want %s, got %s)" % (filename, h_exp, h_act))
                all_ok = False
        if not all_ok:
            sys.exit(1)
        print("All audio files verified byte-identical.")
        sys.exit(0)

    print("=== Generating TLF-064 Audio Files ===")
    for filename, gen_fn in sorted(GENERATORS.items()):
        target_path = os.path.join(OUTPUT_DIR, filename)
        data = gen_fn()
        with open(target_path, "wb") as fh:
            fh.write(data)
        h = sha256_bytes(data)[:12]
        print("WROTE %-30s (%s, %d bytes)" % (filename, h, len(data)))
    print("Done generating 11 SFX audio files.")


if __name__ == "__main__":
    main()
