"""The slice's music: four loops and a title bed (docs/audio/direction.md).

    python tools/audio/make_music.py

Each loop is written with a sampler loop chunk, so Godot's WAV importer
loops it as-is. Tails wrap around the loop point (see synth.Loop), which is
what makes a 30 second loop sit under a 30 minute run without a seam.

  stacks   the residential floors, the mezz, the shafts: a dark pad, a sub
           pulse, data blips over rain
  gut      the pump hall: low throb, metal, steam
  roof     wind and a thin pad, sparse bells
  boss     Collections: a driving 128 BPM pulse under detuned stabs
  title    the pad and a slow motif, for the title and the ending
"""
import numpy as np

from synth import *  # noqa: F401,F403


def detuned_saws(midi, dur, spread=0.004, voices=3):
    f = mtof(midi)
    return mix(*[osc("saw", f * (1 + spread * (i - (voices - 1) / 2)), dur) for i in range(voices)]) / voices


def pad(chord, seconds, cutoff=(350, 900), lfo_hz=0.08, seed=1):
    """Detuned saws under a breathing lowpass. Rendered longer than the loop
    so the caller can fold it."""
    voices = mix(*[detuned_saws(m, seconds) for m in chord]) / len(chord)
    t = np.arange(voices.shape[0]) / SR
    chunks = 96
    edges = np.linspace(0, voices.shape[0], chunks + 1).astype(int)
    out = np.zeros_like(voices)
    overlap = samples(0.02)
    for i in range(chunks):
        centre = (edges[i] + edges[i + 1]) / 2 / SR
        c = cutoff[0] + (cutoff[1] - cutoff[0]) * 0.5 * (1 + np.sin(2 * np.pi * lfo_hz * centre + seed))
        a, b = max(edges[i] - overlap, 0), min(edges[i + 1] + overlap, voices.shape[0])
        seg = lowpass(voices[a:b], c, 2)
        w = np.ones(b - a)
        if a > 0:
            w[:overlap] = np.linspace(0, 1, overlap)
        if b < voices.shape[0]:
            w[-overlap:] = np.linspace(1, 0, overlap)
        out[a:b] += seg * w
    breathe = 0.75 + 0.25 * np.sin(2 * np.pi * lfo_hz * 0.7 * t + 1.3)
    return out * breathe


def ping(midi, dur=0.5, k=7.0, kind="sine"):
    return osc(kind, mtof(midi), dur) * decay(dur, k)


def kick(dur=0.28):
    return mix(osc("sine", sweep(150, 42, dur), dur) * decay(dur, 12), click(0.006) * 0.5)


def click(dur=0.012, seed=3):
    return highpass(noise(dur, seed), 2500) * decay(dur, 300)


def snare(seed=4):
    body = bandpass(noise(0.18, seed), 700, 5000) * decay(0.18, 22)
    tone = osc("sine", sweep(220, 150, 0.12), 0.12) * decay(0.12, 30)
    return mix(body * 0.8, tone * 0.5)


def hat(dur=0.05, seed=5):
    return highpass(noise(dur, seed), 6500) * decay(dur, 60)


def rain(seconds, seed=8, cutoff=1800):
    return lowpass(noise(seconds, seed), cutoff) * 0.5


# --- Stacks ----------------------------------------------------------------------------------

def stacks():
    bpm, bars = 68, 8
    beat = 60.0 / bpm
    loop = Loop(bars * 4 * beat)
    long = loop.seconds + 2.0
    loop.layer(loop.folded(pad([45, 52, 57, 60, 64], long, (300, 800), 0.07), 2.0), db=-13)
    loop.layer(loop.folded(rain(long, 8), 2.0), db=-30)
    hum = osc("sine", 50, loop.seconds) * 0.7 + osc("sine", 100, loop.seconds) * 0.3
    t = np.arange(loop.n) / SR
    hum *= 0.8 + 0.2 * np.sin(2 * np.pi * (2.0 / loop.seconds) * t)
    loop.layer(hum, db=-24)
    for bar in range(bars):
        for b in (0, 2):
            sub = osc("sine", sweep(58, 52, 1.1), 1.1) * decay(1.1, 3)
            loop.place(sub, (bar * 4 + b) * beat, db=-12)
        if bar % 4 == 3:
            thump = lowpass(noise(0.5, 9 + bar), 300) * decay(0.5, 8)
            loop.place(thump, (bar * 4 + 3.5) * beat, db=-16)
    rng = np.random.default_rng(11)
    scale = [81, 84, 86, 88, 91, 93, 96]
    for i in range(14):
        at = rng.uniform(0, loop.seconds)
        m = scale[rng.integers(len(scale))]
        blip = delay(ping(m, 0.35, 9), beat * 0.75, 0.45, 0.5, 5)
        loop.place(blip, at, p=rng.uniform(-0.7, 0.7), db=-21)
    write_wav("stacks", loop.buf, loop=True, peak=0.7, subdir="music")


# --- The Gut ---------------------------------------------------------------------------------

def gut():
    bpm, bars = 60, 8
    beat = 60.0 / bpm
    loop = Loop(bars * 4 * beat)
    long = loop.seconds + 2.0
    drone = lowpass(detuned_saws(26, long, 0.006, 4) + detuned_saws(38, long, 0.004, 3) * 0.6, 180)
    loop.layer(loop.folded(drone, 2.0), db=-11)
    loop.layer(loop.folded(pad([50, 56, 62], long, (250, 500), 0.05, 2), 2.0), db=-20)
    for bar in range(bars):
        for b in range(4):
            throb = osc("sine", sweep(48, 40, 0.5), 0.5) * decay(0.5, 8)
            loop.place(throb, (bar * 4 + b) * beat, db=-13 if b % 2 == 0 else -18)
        if bar % 2 == 1:
            hiss = highpass(noise(1.6, 20 + bar), 2500) * adsr(1.6, 0.3, 0.2, 0.7, 0.9)
            loop.place(hiss, (bar * 4 + 1.5) * beat, p=0.5 if bar % 4 == 1 else -0.5, db=-27)
    rng = np.random.default_rng(23)
    for i in range(12):
        at = rng.uniform(0, loop.seconds)
        f = rng.uniform(900, 2600)
        clank = bandpass(noise(0.4, 30 + i), f * 0.8, f * 1.4) * decay(0.4, 14) + osc("sine", f, 0.4) * decay(0.4, 10) * 0.4
        loop.place(clank, at, p=rng.uniform(-0.8, 0.8), db=-24)
    write_wav("gut", loop.buf, loop=True, peak=0.7, subdir="music")


# --- The roof --------------------------------------------------------------------------------

def roof():
    bpm, bars = 64, 8
    beat = 60.0 / bpm
    loop = Loop(bars * 4 * beat)
    long = loop.seconds + 3.0
    wind = noise(long, 40)
    t = np.arange(wind.shape[0]) / SR
    wind = lowpass_sweep(wind, 400, 400, 4)
    gust = 0.5 + 0.5 * np.sin(2 * np.pi * 0.06 * t) * np.sin(2 * np.pi * 0.023 * t + 1.0)
    wind = lowpass(wind, 900) * (0.4 + 0.6 * gust)
    loop.layer(loop.folded(wind, 3.0), db=-20)
    loop.layer(loop.folded(pad([52, 59, 62, 66], long, (500, 1400), 0.06, 3), 3.0), db=-16)
    rng = np.random.default_rng(31)
    for i in range(9):
        at = rng.uniform(0, loop.seconds)
        m = [76, 79, 83, 86, 88][rng.integers(5)]
        bell = ping(m, 1.2, 4) + ping(m + 12, 1.2, 7) * 0.3 + ping(m + 19, 1.2, 9) * 0.15
        loop.place(delay(bell, beat * 0.5, 0.4, 0.4, 4), at, p=rng.uniform(-0.8, 0.8), db=-22)
    siren = osc("sine", 660 + 40 * np.sin(np.linspace(0, 6 * np.pi, samples(4.0))), 4.0) * adsr(4.0, 1.0, 0.5, 0.6, 1.5)
    loop.place(lowpass(siren, 1500), 18.0, p=-0.9, db=-36)
    write_wav("roof", loop.buf, loop=True, peak=0.7, subdir="music")


# --- Collections: the Landlord ------------------------------------------------------------

def boss():
    bpm, bars = 128, 16
    beat = 60.0 / bpm
    step = beat / 4.0
    loop = Loop(bars * 4 * beat)
    # Drums.
    for bar in range(bars):
        for b in range(4):
            loop.place(kick(), (bar * 4 + b) * beat, db=-6)
            if b in (1, 3):
                loop.place(snare(4 + bar), (bar * 4 + b) * beat, db=-12)
        for e in range(8):
            loop.place(hat(0.05 if e % 2 else 0.035, 5 + e), (bar * 4 + e * 0.5) * beat, p=0.3, db=-20 if e % 2 else -24)
        if bar % 4 == 3:
            for s in range(4):
                loop.place(snare(9 + s), (bar * 4 + 3 + s * 0.25) * beat, db=-16 + s)
    # Bass riff: sixteenth steps, midi (None = rest).
    riff = [45, None, 45, 45, None, 48, None, 45, 43, None, 45, None, 48, 50, None, 45]
    riff_b = [41, None, 41, 41, None, 43, None, 41, 40, None, 41, None, 43, 45, None, 48]
    for bar in range(bars):
        pattern = riff_b if bar % 4 == 3 else riff
        for i, m in enumerate(pattern):
            if m is None:
                continue
            dur = step * 0.9
            b = lowpass_sweep(osc("saw", mtof(m - 12), dur) + osc("square", mtof(m - 12) * 1.005, dur) * 0.4, 1200, 250, 6) * adsr(dur, 0.003, 0.05, 0.6, 0.03)
            loop.place(distort(b, 1.8), (bar * 4) * beat + i * step, db=-9)
    # Stabs on the off-beats.
    chords = {0: [57, 60, 64], 1: [57, 60, 64], 2: [55, 59, 62], 3: [53, 57, 60]}
    for bar in range(bars):
        chord = chords[bar % 4]
        for pos in (1.5, 3.5):
            dur = 0.28
            stab = mix(*[detuned_saws(m, dur, 0.006, 3) for m in chord]) / 3
            stab = lowpass_sweep(stab, 3500, 400, 10) * adsr(dur, 0.005, 0.1, 0.4, 0.1)
            loop.place(stab, (bar * 4 + pos) * beat, p=-0.4 if pos < 2 else 0.4, db=-14)
    # A lead in the second half.
    lead = [(69, 0), (72, 1), (71, 2), (67, 3), (64, 4), (67, 5.5), (69, 6), (None, 7)]
    for bar in range(8, 16):
        if bar % 2 == 1:
            continue
        for m, at in lead:
            if m is None:
                continue
            dur = beat * 0.45
            l = lowpass(osc("square", mtof(m), dur) + osc("square", mtof(m) * 1.007, dur), 4000) * adsr(dur, 0.005, 0.1, 0.6, 0.08)
            loop.place(delay(l, beat * 0.75, 0.4, 0.35, 4), (bar * 4 + at * 0.5) * beat, db=-17)
    # A riser over the last bar rolls into the loop start.
    riser = lowpass_sweep(noise(4 * beat, 77), 300, 8000, 24) * adsr(4 * beat, 1.0, 0.2, 1.0, 0.05)
    loop.place(riser, (bars - 1) * 4 * beat, db=-18)
    write_wav("boss", loop.buf, loop=True, peak=0.8, subdir="music")


# --- Title and ending -------------------------------------------------------------------------

def title():
    bpm, bars = 60, 8
    beat = 60.0 / bpm
    loop = Loop(bars * 4 * beat)
    long = loop.seconds + 3.0
    loop.layer(loop.folded(pad([45, 52, 57, 60], long, (250, 700), 0.05, 5), 3.0), db=-13)
    loop.layer(loop.folded(rain(long, 61, 1400), 3.0), db=-32)
    motif = [(69, 0), (72, 2), (71, 4), (67, 6), (64, 8), (67, 10), (69, 12), (76, 14), (72, 18), (71, 20), (69, 22), (64, 26)]
    for m, at in motif:
        tone = (osc("tri", mtof(m), 1.6) + osc("sine", mtof(m) * 2, 1.6) * 0.2) * decay(1.6, 2.2)
        loop.place(delay(lowpass(tone, 3000), beat * 0.75, 0.45, 0.4, 5), at * beat, p=0.2 * np.sin(at), db=-19)
    for bar in range(bars):
        sub = osc("sine", sweep(55, 50, 1.6), 1.6) * decay(1.6, 2.5)
        loop.place(sub, bar * 4 * beat, db=-13)
    write_wav("title", loop.buf, loop=True, peak=0.7, subdir="music")


if __name__ == "__main__":
    stacks()
    gut()
    roof()
    boss()
    title()
