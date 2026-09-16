"""The instruments: one function per voice of the palette, on the sound-designer's synth (the composer puts
that folder on the path while this loads, so `from synth import *` resolves; nothing here is run by hand).

Three signatures, by the layer kind that calls them (the composer's tracker.py):
    texture   f(seconds, **args) -> mono or (2, n)     a pad, rain, wind: `seconds` of sound, folded over the seam
    pattern   f(note, dur, **args) -> mono             note is a midi int, a list for a chord, None for `x`
    scatter   f(note, **args) -> mono
A function that takes `n` gets the event's index; a function that takes `loop_s` gets the loop's length.
Seeds are explicit; `n` moves a noise seed so a drum is not the same drum on every beat. A note name in the
track's args is a midi number by the time it arrives here.

The palette is the sound-designer's (its reference/palette.md): square and saw through a lowpass, noise for
breath and metal, sines for the low end, and every bright thing lowpassed after its distortion.
"""
import numpy as np

from synth import *  # noqa: F401,F403


def _saws(midi, dur, spread=0.004, voices=3):
    f = mtof(midi)
    return mix(*[osc("saw", f * (1 + spread * (i - (voices - 1) / 2)), dur) for i in range(voices)]) / voices


def _click(dur=0.012, seed=3):
    return highpass(noise(dur, seed), 2500) * decay(dur, 300)


def _ping(midi, dur=0.5, k=7.0, kind="sine"):
    return osc(kind, mtof(midi), dur) * decay(dur, k)


# --- textures ---------------------------------------------------------------------------------------

def pad(seconds, chord, cutoff=(350, 900), lfo_hz=0.08, seed=1):
    """Detuned saws under a breathing lowpass. Slow: the lowpass is moved in 96 crossfaded chunks."""
    voices = mix(*[_saws(m, seconds) for m in chord]) / len(chord)
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


def rain(seconds, seed=8, cutoff=1800):
    return lowpass(noise(seconds, seed), cutoff) * 0.5


def wind(seconds, seed=40):
    """Noise under a slow lowpass, gusting on two slow sines that never line up."""
    w = noise(seconds, seed)
    t = np.arange(w.shape[0]) / SR
    w = lowpass_sweep(w, 400, 400, 4)
    gust = 0.5 + 0.5 * np.sin(2 * np.pi * 0.06 * t) * np.sin(2 * np.pi * 0.023 * t + 1.0)
    return lowpass(w, 900) * (0.4 + 0.6 * gust)


def hum(seconds, loop_s, f=50.0, cycles=2):
    """A mains hum with an amplitude wobble that cycles a whole number of times per loop. The hum itself is
    snapped to a whole number of cycles per loop too (50 Hz over 28.235 s is 1411.8 cycles: a step at the
    seam, 40 dB of click; 50.008 Hz is 1412 and none), so it needs no fold: fold_s 0 in the track."""
    f = round(f * loop_s) / loop_s
    x = osc("sine", f, seconds) * 0.7 + osc("sine", 2 * f, seconds) * 0.3
    t = np.arange(x.shape[0]) / SR
    return x * (0.8 + 0.2 * np.sin(2 * np.pi * (cycles / loop_s) * t))


def drone(seconds, notes, gains=None, cutoff=180, spread=0.006):
    """Detuned saws on each note, lowpassed to a throb; the first note has four voices, the rest three."""
    gains = gains or [1.0] * len(notes)
    parts = [_saws(m, seconds, spread if i == 0 else spread * 0.7, 4 if i == 0 else 3) * g for i, (m, g) in enumerate(zip(notes, gains))]
    return lowpass(mix(*parts), cutoff)


# --- the low end -------------------------------------------------------------------------------------

def sub(note, dur, fall=2.0, k=3.0):
    """A sine that falls `fall` semitones onto the note and decays."""
    f1 = mtof(note)
    return osc("sine", sweep(f1 * 2 ** (fall / 12.0), f1, dur), dur) * decay(dur, k)


def thump(note, dur, seed=9, n=0):
    return lowpass(noise(dur, seed + n), 300) * decay(dur, 8)


def hiss(note, dur, seed=20, n=0):
    """Steam: high noise swelling in and out."""
    return highpass(noise(dur, seed + n), 2500) * adsr(dur, 0.3, 0.2, 0.7, 0.9)


def heartbeat(note, dur, gap=0.18, k=18.0):
    """Two sub thumps, the second softer: lub, dub."""
    one = osc("sine", sweep(70, 45, 0.3), 0.3) * decay(0.3, k)
    out = np.zeros(samples(max(dur, gap + 0.3)))
    out[: one.shape[0]] += one
    at = samples(gap)
    out[at: at + one.shape[0]] += one * 0.6
    return lowpass(out, 200)


# --- drums ---------------------------------------------------------------------------------------------

def kick(note, dur, length=0.28):
    return mix(osc("sine", sweep(150, 42, length), length) * decay(length, 12), _click(0.006) * 0.5)


def snare(note, dur, seed=4, n=0):
    body = bandpass(noise(0.18, seed + n), 700, 5000) * decay(0.18, 22)
    tone = osc("sine", sweep(220, 150, 0.12), 0.12) * decay(0.12, 30)
    return mix(body * 0.8, tone * 0.5)


def hat(note, dur, length=0.05, seed=5, n=0):
    return highpass(noise(length, seed + n), 6500) * decay(length, 60)


def tick(note, dur, length=0.02, seed=6, n=0):
    """A soft hat, a clock: the boss's floor before his bar appears."""
    return lowpass(highpass(noise(length, seed + n), 5000), 9000) * decay(length, 120)


def hammer(note, dur, seed=50, n=0):
    """A metallic hit: a ringing band of noise over a low knock, saturated then lowpassed."""
    ring = bandpass(noise(0.35, seed + n), 1500, 6000) * decay(0.35, 16)
    knock = osc("sine", sweep(180, 90, 0.2), 0.2) * decay(0.2, 20)
    return lowpass(distort(mix(ring * 0.7, knock), 2.5), 7000)


# --- pitched voices ------------------------------------------------------------------------------------

def bass(note, dur, octave=-1, drive=1.8):
    f = mtof(note + 12 * octave)
    b = lowpass_sweep(osc("saw", f, dur) + osc("square", f * 1.005, dur) * 0.4, 1200, 250, 6) * adsr(dur, 0.003, 0.05, 0.6, 0.03)
    return distort(b, drive)


def pulse(note, dur, cutoff=900):
    """A short lowpassed square: the combat pulse under the district beds."""
    x = osc("square", mtof(note), dur) * adsr(dur, 0.003, 0.04, 0.5, 0.04)
    return lowpass(x, cutoff)


def arp(note, dur, cutoff=2500):
    """A plucked saw for a fast line."""
    x = osc("saw", mtof(note), dur) * adsr(dur, 0.002, 0.06, 0.3, 0.03)
    return lowpass(x, cutoff)


def stab(note, dur, spread=0.006):
    chord = note if isinstance(note, list) else [note]
    x = mix(*[_saws(m, dur, spread, 3) for m in chord]) / len(chord)
    return lowpass_sweep(x, 3500, 400, 10) * adsr(dur, 0.005, 0.1, 0.4, 0.1)


def lead(note, dur, delay_s=0.35):
    x = lowpass(osc("square", mtof(note), dur) + osc("square", mtof(note) * 1.007, dur), 4000) * adsr(dur, 0.005, 0.1, 0.6, 0.08)
    return delay(x, delay_s, 0.4, 0.35, 4)


def tone(note, dur, delay_s=0.75):
    """The title's voice: a triangle with a hint of octave, a long decay, a slow delay."""
    x = (osc("tri", mtof(note), dur) + osc("sine", mtof(note) * 2, dur) * 0.2) * decay(dur, 2.2)
    return delay(lowpass(x, 3000), delay_s, 0.45, 0.4, 5)


def siren(note, dur, wobble_hz=0.75, depth=40.0):
    f = mtof(note) + depth * np.sin(np.linspace(0, 2 * np.pi * wobble_hz * dur, samples(dur)))
    return lowpass(osc("sine", f, dur) * adsr(dur, 1.0, 0.5, 0.6, 1.5), 1500)


def riser(note, dur, seed=77):
    return lowpass_sweep(noise(dur, seed), 300, 8000, 24) * adsr(dur, 1.0, 0.2, 1.0, 0.05)


# --- scatter voices ------------------------------------------------------------------------------------

def blip(note, dur=0.35, k=9.0, delay_s=0.66, feedback=0.45, wet=0.5, taps=5):
    return delay(_ping(note, dur, k), delay_s, feedback, wet, taps)


def bell(note, dur=1.2, delay_s=0.47):
    x = _ping(note, dur, 4) + _ping(note + 12, dur, 7) * 0.3 + _ping(note + 19, dur, 9) * 0.15
    return delay(x, delay_s, 0.4, 0.4, 4)


def clank(note, seed=30, n=0):
    f = mtof(note)
    return bandpass(noise(0.4, seed + n), f * 0.8, f * 1.4) * decay(0.4, 14) + osc("sine", f, 0.4) * decay(0.4, 10) * 0.4
