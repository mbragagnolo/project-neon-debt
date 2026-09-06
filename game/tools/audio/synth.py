"""A small synthesiser for the slice's audio (docs/audio/direction.md).

Every sound in assets/audio is generated from here, deterministically, so a
sound is a recipe in make_sfx.py or make_music.py and not an opaque binary
somebody once found. numpy for the maths, scipy only for the filters.
"""
import os
import struct

import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio"))


# --- Sources -----------------------------------------------------------------------------

def samples(dur):
    return int(round(SR * dur))


def osc(kind, freq, dur, phase=0.0):
    """freq may be a number or an array of instantaneous frequencies."""
    n = samples(dur)
    f = np.asarray(freq, dtype=float)
    if f.ndim == 0:
        f = np.full(n, float(f))
    elif f.shape[0] != n:
        f = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, f.shape[0]), f)
    ph = 2.0 * np.pi * np.cumsum(f) / SR + phase
    if kind == "sine":
        return np.sin(ph)
    frac = (ph / (2.0 * np.pi)) % 1.0
    if kind == "square":
        return np.where(frac < 0.5, 1.0, -1.0)
    if kind == "saw":
        return 2.0 * frac - 1.0
    if kind == "tri":
        return 2.0 * np.abs(2.0 * frac - 1.0) - 1.0
    if kind == "pulse":
        return np.where(frac < 0.25, 1.0, -1.0)
    raise ValueError(kind)


def noise(dur, seed=1):
    return np.random.default_rng(seed).uniform(-1.0, 1.0, samples(dur))


def sweep(f0, f1, dur, exp=True):
    n = samples(dur)
    x = np.linspace(0.0, 1.0, n)
    return f0 * (f1 / f0) ** x if exp else f0 + (f1 - f0) * x


def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


# --- Envelopes ---------------------------------------------------------------------------

def adsr(dur, a=0.005, d=0.05, s=1.0, r=0.05):
    n = samples(dur)
    na, nd, nr = samples(a), samples(d), samples(r)
    ns = max(n - na - nd - nr, 0)
    parts = [
        np.linspace(0, 1, na, endpoint=False),
        np.linspace(1, s, nd, endpoint=False),
        np.full(ns, s),
        np.linspace(s, 0, nr),
    ]
    e = np.concatenate(parts)
    return e[:n] if e.shape[0] >= n else np.pad(e, (0, n - e.shape[0]))


def decay(dur, k, start=1.0):
    t = np.arange(samples(dur)) / SR
    return start * np.exp(-t * k)


def fade(x, fin=0.005, fout=0.02):
    x = x.copy()
    ni, no = min(samples(fin), x.shape[-1]), min(samples(fout), x.shape[-1])
    if ni:
        x[..., :ni] *= np.linspace(0, 1, ni)
    if no:
        x[..., -no:] *= np.linspace(1, 0, no)
    return x


# --- Filters and effects ---------------------------------------------------------------

def _sos(kind, f, order=2):
    nyq = SR / 2.0
    if isinstance(f, (tuple, list)):
        f = [max(20.0, min(f[0], nyq - 100)), max(30.0, min(f[1], nyq - 50))]
    else:
        f = max(20.0, min(float(f), nyq - 50))
    return butter(order, np.asarray(f) / nyq, kind, output="sos")


def lowpass(x, cutoff, order=2):
    return sosfilt(_sos("low", cutoff, order), x)


def highpass(x, cutoff, order=2):
    return sosfilt(_sos("high", cutoff, order), x)


def bandpass(x, lo, hi, order=2):
    return sosfilt(_sos("band", (lo, hi), order), x)


def lowpass_sweep(x, f0, f1, chunks=48, exp=True):
    """A lowpass whose cutoff moves over the sound; chunked and crossfaded."""
    n = x.shape[0]
    if exp:
        cutoffs = f0 * (f1 / f0) ** np.linspace(0, 1, chunks)
    else:
        cutoffs = np.linspace(f0, f1, chunks)
    out = np.zeros(n)
    edges = np.linspace(0, n, chunks + 1).astype(int)
    overlap = max(int(SR * 0.004), 8)
    for i in range(chunks):
        a, b = max(edges[i] - overlap, 0), min(edges[i + 1] + overlap, n)
        seg = lowpass(x[a:b], cutoffs[i])
        w = np.ones(b - a)
        if a > 0:
            w[:overlap] = np.linspace(0, 1, overlap)
        if b < n:
            w[-overlap:] = np.linspace(1, 0, overlap)
        out[a:b] += seg * w
    return out


def delay(x, time, feedback=0.35, mix_level=0.35, taps=6):
    n = x.shape[0]
    d = samples(time)
    wet = np.zeros(n + d * taps)
    for i in range(1, taps + 1):
        wet[d * i : d * i + n] += x * (feedback ** i)
    return np.concatenate([x, np.zeros(d * taps)]) + wet * mix_level


def distort(x, drive=2.0):
    return np.tanh(x * drive) / np.tanh(drive)


def bitcrush(x, bits=6, hold=1):
    q = 2 ** (bits - 1)
    y = np.round(x * q) / q
    if hold > 1:
        y = np.repeat(y[::hold], hold)[: x.shape[0]]
    return y


def tremolo(x, rate, depth=0.5):
    t = np.arange(x.shape[0]) / SR
    return x * (1.0 - depth + depth * 0.5 * (1.0 + np.sin(2 * np.pi * rate * t)))


# --- Mixing --------------------------------------------------------------------------------

def mix(*parts):
    n = max(p.shape[-1] for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: p.shape[-1]] += p
    return out


def gain(x, db):
    return x * 10 ** (db / 20.0)


def normalize(x, peak=0.9):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def pan(x, p):
    """mono -> (2, n); p in [-1, 1]."""
    a = (p + 1.0) * 0.25 * np.pi
    return np.stack([x * np.cos(a), x * np.sin(a)])


# --- Loops ---------------------------------------------------------------------------------

class Loop:
    """A stereo buffer of a fixed length that sounds wrap around the end of,
    so a tail that runs past the loop point is heard at the start. The seam
    disappears."""

    def __init__(self, seconds):
        self.n = samples(seconds)
        self.seconds = seconds
        self.buf = np.zeros((2, self.n))

    def place(self, x, at, p=0.0, db=0.0):
        if x.ndim == 1:
            x = pan(x, p)
        x = gain(x, db)
        start = samples(at) % self.n
        idx = (np.arange(x.shape[1]) + start) % self.n
        np.add.at(self.buf, (0, idx), x[0])
        np.add.at(self.buf, (1, idx), x[1])

    def layer(self, x, db=0.0):
        """A continuous layer as long as the loop (longer wraps around)."""
        if x.ndim == 1:
            x = np.stack([x, x])
        x = gain(x, db)
        for ch in range(2):
            idx = np.arange(x.shape[1]) % self.n
            np.add.at(self.buf, (ch, idx), x[ch])

    def folded(self, x, overlap=1.0):
        """Generate `x` longer than the loop and crossfade its tail into its
        head so a non-periodic texture loops cleanly."""
        n_over = samples(overlap)
        body = x[..., : self.n].copy()
        tail = x[..., self.n : self.n + n_over]
        m = tail.shape[-1]
        w = np.linspace(0, 1, m)
        body[..., :m] = body[..., :m] * w + tail * (1 - w)
        return body


# --- Output --------------------------------------------------------------------------------

def write_wav(name, x, loop=False, peak=0.9, subdir="sfx"):
    if x.ndim == 1:
        x = np.stack([x, x]) if subdir == "music" else x[None, :]
    x = np.clip(x * (peak / max(np.max(np.abs(x)), 1e-9)), -1.0, 1.0)
    channels, n = x.shape
    if subdir == "music":
        # Loops are long and stereo: Ogg Vorbis, a tenth the size. The Music
        # autoload sets the loop flag on the stream.
        import soundfile
        path = os.path.join(OUT, subdir, name + ".ogg")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        # One second at a time: libsndfile's Vorbis encoder falls over on a
        # single multi-megabyte write.
        with soundfile.SoundFile(path, "w", SR, channels, format="OGG", subtype="VORBIS") as f:
            for start in range(0, n, SR):
                f.write(x[:, start : start + SR].T)
        print("%-28s %5.2fs %s" % (os.path.relpath(path, OUT), n / SR, "loop" if loop else ""))
        return
    pcm = (x.T * 32767.0).astype("<i2").tobytes()
    path = os.path.join(OUT, subdir, name + ".wav")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fmt = struct.pack("<HHIIHH", 1, channels, SR, SR * channels * 2, channels * 2, 16)
    chunks = [b"fmt " + struct.pack("<I", len(fmt)) + fmt]
    if loop:
        # A sampler loop chunk: Godot's WAV importer picks it up ("Detect From WAV").
        smpl = struct.pack("<IIIIIIIII", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<IIIIII", 0, 0, 0, n - 1, 0, 0)
        chunks.append(b"smpl" + struct.pack("<I", len(smpl)) + smpl)
    chunks.append(b"data" + struct.pack("<I", len(pcm)) + pcm)
    body = b"WAVE" + b"".join(chunks)
    with open(path, "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", len(body)) + body)
    print("%-28s %5.2fs %s" % (os.path.relpath(path, OUT), n / SR, "loop" if loop else ""))
