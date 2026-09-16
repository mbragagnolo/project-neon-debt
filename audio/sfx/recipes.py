"""Every sound effect in Neon Debt, as a recipe (docs/audio/direction.md). The sound-designer's
master.py renders these through the skill's synth, masters each to its class's loudness and writes
game/assets/audio/sfx/<id>.wav; the table beside this file (sfx.json) says the class, the event and
how many variations each one gets.

Short, dry, a little crunchy: square and saw through a lowpass, noise bursts for impacts, a bit-crush
on anything that dies. The ids are what `Sfx.play()` takes.
"""
from synth import *  # noqa: F401,F403



def click(dur=0.012, seed=3):
    return highpass(noise(dur, seed), 2500) * decay(dur, 300)


# --- Movement ------------------------------------------------------------------------------

def jump():
    body = osc("square", sweep(jitter(260, 0.06), jitter(640, 0.06), 0.14), 0.14) * adsr(0.14, 0.002, 0.04, 0.5, 0.06)
    return mix(lowpass(body, 3000) * 0.5, click() * 0.4)


def wall_jump():
    body = osc("square", sweep(330, 820, 0.14), 0.14) * adsr(0.14, 0.002, 0.04, 0.5, 0.06)
    scrape = bandpass(noise(0.1, 5), 1500, 5000) * decay(0.1, 40)
    return mix(lowpass(body, 3500) * 0.45, scrape * 0.5)


def dash():
    whoosh = bandpass(noise(0.22, 7), 600, 2800) * adsr(0.22, 0.01, 0.06, 0.5, 0.1)
    tone = osc("sine", sweep(900, 250, 0.22), 0.22) * decay(0.22, 14)
    return lowpass(distort(whoosh * 0.8 + tone * 0.3, 2.5), 6000)


def land():
    thud = lowpass(noise(0.14, 9), 400) * decay(0.14, 30)
    low = osc("sine", sweep(jitter(120, 0.08), 55, 0.14), 0.14) * decay(0.14, 22)
    return lowpass(distort(thud * 0.7 + low * 0.8, 3.0), 6000)


def swing():
    w = bandpass(noise(0.18, 11), 400, 3200) * adsr(0.18, 0.01, 0.06, 0.5, 0.09)
    return lowpass(distort(lowpass_sweep(w, jitter(4000, 0.1), 800, 16), 3.0), 6000)


def hazard():
    zap = osc("square", sweep(1400, 200, 0.22), 0.22) * decay(0.22, 14)
    splash = highpass(noise(0.25, 13), 1200) * decay(0.25, 12)
    return lowpass(mix(bitcrush(zap, 5) * 0.5, splash * 0.5), 8000)


# --- Combat -------------------------------------------------------------------------------

def hit():
    crack = highpass(noise(0.07, 17), 900) * decay(0.07, 70)
    body = osc("square", sweep(jitter(320, 0.08), 110, 0.09), 0.09) * decay(0.09, 40)
    return lowpass(distort(mix(crack * 0.8, body * 0.6), 5.0), 7000)


def hit_heavy():
    crack = bandpass(noise(0.14, 19), 300, 3000) * decay(0.14, 35)
    body = osc("square", sweep(200, 60, 0.16), 0.16) * decay(0.16, 22)
    return distort(mix(crack * 0.8, body * 0.8), 3.5)


def hit_guard():
    ring = osc("sine", 1800, 0.18) * decay(0.18, 20) + osc("sine", 2700, 0.18) * decay(0.18, 30) * 0.5
    tick = lowpass(noise(0.012, 21), 6000) * decay(0.012, 300)
    return lowpass(distort(mix(ring * 0.6, tick * 0.5), 2.5), 8000)


def shoot():
    zap = osc("square", sweep(1500, 420, 0.1), 0.1) * decay(0.1, 30)
    return mix(lowpass(bitcrush(zap, 6), 6000) * 0.7, click(0.008, 23) * 0.5)


def shoot_nail():
    pop = lowpass(noise(0.07, 25), 2500) * decay(0.07, 60)
    tone = osc("sine", sweep(700, 200, 0.07), 0.07) * decay(0.07, 40)
    return lowpass(distort(pop * 0.8 + tone * 0.6, 4.0), 7000)


def shoot_rivet():
    thump = osc("sine", sweep(240, 80, 0.12), 0.12) * decay(0.12, 30)
    burst = lowpass(noise(0.1, 27), 3000) * decay(0.1, 50)
    return distort(mix(thump * 0.9, burst * 0.6), 2.5)


def drone_shot():
    zap = osc("saw", sweep(2600, 900, 0.09), 0.09) * decay(0.09, 40)
    return lowpass(distort(lowpass(zap, 7000) * 0.6, 2.0), 7000)


def hurt():
    tone = osc("saw", sweep(420, 140, 0.22), 0.22) * decay(0.22, 14)
    grit = bandpass(noise(0.15, 29), 400, 2500) * decay(0.15, 30)
    return distort(mix(lowpass(tone, 2500) * 0.7, grit * 0.5), 2.0)


def die():
    tone = osc("saw", sweep(380, 60, 0.7), 0.7) * decay(0.7, 4)
    grit = lowpass(noise(0.6, 31), 1200) * decay(0.6, 6)
    return bitcrush(distort(mix(tone * 0.7, grit * 0.4), 2.5), 5)


def enemy_die():
    crunch = lowpass(noise(0.3, 33), 1800) * decay(0.3, 14)
    tone = osc("square", sweep(500, 90, 0.35), 0.35) * decay(0.35, 10)
    return bitcrush(distort(mix(crunch * 0.7, tone * 0.5), 2.0), 5)


def mech_die():
    crunch = lowpass(noise(0.45, 35), 2500) * decay(0.45, 9)
    spark = highpass(noise(0.4, 36), 4000) * tremolo(decay(0.4, 8), 40, 0.9)
    tone = osc("saw", sweep(300, 40, 0.5), 0.5) * decay(0.5, 7)
    return lowpass(bitcrush(distort(mix(crunch * 0.6, spark * 0.4, tone * 0.5), 2.5), 5), 9000)


def tell():
    t = osc("square", sweep(380, 760, 0.12), 0.12) * adsr(0.12, 0.002, 0.03, 0.6, 0.05)
    return lowpass(t, 4000) * 0.45


def lunge():
    w = bandpass(noise(0.2, 37), 500, 2500) * adsr(0.2, 0.005, 0.06, 0.6, 0.1)
    return lowpass(distort(lowpass_sweep(w, 3500, 600, 12), 3.0), 6000)


def stun():
    buzz = osc("square", sweep(900, 300, 0.45), 0.45) * tremolo(decay(0.45, 6), 28, 0.95)
    return bitcrush(buzz, 5) * 0.6


def slam():
    boom = osc("sine", sweep(110, 32, 0.6), 0.6) * decay(0.6, 6)
    crack = lowpass(noise(0.35, 39), 1500) * decay(0.35, 14)
    return distort(mix(boom * 1.0, crack * 0.7), 2.0)


def beam_charge():
    rise = osc("saw", sweep(120, 1400, 0.55), 0.55) * adsr(0.55, 0.05, 0.1, 0.9, 0.1)
    shimmer = osc("sine", sweep(2000, 5000, 0.55), 0.55) * adsr(0.55, 0.2, 0.1, 0.5, 0.1)
    return lowpass_sweep(rise, 500, 6000, 24) * 0.6 + shimmer * 0.15


def beam_fire():
    buzz = osc("saw", 190, 0.7) * 0.5 + osc("saw", 191.7, 0.7) * 0.5
    hiss = highpass(noise(0.7, 41), 3000) * 0.3
    return (lowpass(buzz, 2500) + hiss) * adsr(0.7, 0.01, 0.1, 0.8, 0.25)


def roar():
    a = osc("saw", 70 + 6 * np.sin(np.linspace(0, 40, samples(0.9))), 0.9)
    b = osc("saw", 74.5, 0.9)
    growl = lowpass(noise(0.9, 43), 800) * 0.5
    body = lowpass(a * 0.5 + b * 0.5 + growl, 1200) * adsr(0.9, 0.05, 0.2, 0.8, 0.3)
    return distort(body, 3.0)


# --- Hacks --------------------------------------------------------------------------------

def hack_guard():
    chord = mix(*[osc("saw", mtof(m) * (1 + 0.003 * i), 0.4) for i, m in enumerate([69, 76, 81])])
    body = lowpass_sweep(chord, 400, 5000, 20) * adsr(0.4, 0.02, 0.1, 0.6, 0.15)
    return body * 0.35


def hack_burst():
    thump = osc("sine", sweep(160, 40, 0.45), 0.45) * decay(0.45, 8)
    blast = lowpass_sweep(noise(0.4, 45), 6000, 300, 16) * decay(0.4, 9)
    zap = osc("square", sweep(2400, 300, 0.2), 0.2) * decay(0.2, 20)
    return distort(mix(thump * 0.9, blast * 0.7, zap * 0.3), 2.0)


def hack_pulse():
    ping = osc("sine", 1320, 0.55) * decay(0.55, 7) + osc("sine", 1980, 0.55) * decay(0.55, 12) * 0.5
    wobble = tremolo(ping, 18, 0.6)
    return delay(wobble, 0.09, 0.5, 0.4, 5) * 0.5


def deny():
    a = osc("square", 220, 0.09) * adsr(0.09, 0.002, 0.02, 0.7, 0.04)
    b = osc("square", 165, 0.12) * adsr(0.12, 0.002, 0.02, 0.7, 0.06)
    return lowpass(np.concatenate([a, np.zeros(samples(0.03)), b]), 2500) * 0.4


def hack_acquire():
    notes = [69, 73, 76, 81, 88]
    out = np.zeros(samples(1.2))
    for i, m in enumerate(notes):
        tone = osc("tri", mtof(m), 0.5) * decay(0.5, 6)
        s = samples(0.09 * i)
        out[s : s + tone.shape[0]] += tone * 0.5
    return delay(out, 0.18, 0.4, 0.3, 4)


# --- Pickups and progress ----------------------------------------------------------------

def pickup():
    a = osc("sine", mtof(84), 0.12) * decay(0.12, 14)
    b = osc("sine", mtof(91), 0.2) * decay(0.2, 10)
    return np.concatenate([a, b]) * 0.6


def credits():
    out = np.zeros(samples(0.35))
    for i, m in enumerate([88, 93, 96]):
        tone = osc("square", mtof(m), 0.12) * decay(0.12, 25)
        s = samples(0.05 * i)
        out[s : s + tone.shape[0]] += lowpass(tone, 5000) * 0.3
    return out


def stat_up():
    out = np.zeros(samples(0.8))
    for i, m in enumerate([72, 76, 79, 84]):
        tone = osc("tri", mtof(m), 0.4) * decay(0.4, 7)
        s = samples(0.08 * i)
        out[s : s + tone.shape[0]] += tone * 0.5
    return delay(out, 0.15, 0.35, 0.3, 3)


def level_up():
    out = np.zeros(samples(1.4))
    seq = [(69, 0.0), (76, 0.1), (81, 0.2), (88, 0.3), (93, 0.45), (100, 0.6)]
    for m, at in seq:
        tone = (osc("tri", mtof(m), 0.6) + osc("square", mtof(m) * 0.5, 0.6) * 0.3) * decay(0.6, 5)
        s = samples(at)
        out[s : s + tone.shape[0]] += lowpass(tone, 6000) * 0.4
    return delay(out, 0.2, 0.4, 0.3, 4)


def quest():
    out = np.zeros(samples(1.0))
    for i, m in enumerate([76, 79, 83, 88]):
        tone = osc("sine", mtof(m), 0.5) * decay(0.5, 6)
        s = samples(0.12 * i)
        out[s : s + tone.shape[0]] += tone * 0.5
    return delay(out, 0.17, 0.4, 0.35, 4)


def save():
    hum = lowpass(osc("saw", 110, 0.9), 600) * adsr(0.9, 0.1, 0.2, 0.5, 0.4) * 0.3
    out = np.zeros(samples(0.9))
    for i, m in enumerate([81, 85, 88]):
        tone = osc("sine", mtof(m), 0.45) * decay(0.45, 8)
        s = samples(0.15 * i + 0.1)
        out[s : s + tone.shape[0]] += tone * 0.45
    return hum + out


def door():
    servo = osc("saw", sweep(180, 260, 0.35), 0.35) * adsr(0.35, 0.02, 0.05, 0.7, 0.1)
    slide = bandpass(noise(0.35, 47), 300, 1800) * adsr(0.35, 0.02, 0.1, 0.5, 0.15)
    clunk = lowpass(noise(0.08, 48), 500) * decay(0.08, 50)
    body = lowpass(servo, 1500) * 0.3 + slide * 0.5
    return np.concatenate([body, clunk * 0.9])


def breach():
    spark = highpass(noise(0.3, 49), 3000) * tremolo(decay(0.3, 10), 45, 0.9)
    clunk = osc("sine", sweep(200, 60, 0.25), 0.25) * decay(0.25, 18)
    slide = bandpass(noise(0.4, 50), 200, 1200) * adsr(0.4, 0.02, 0.1, 0.6, 0.15)
    return np.concatenate([spark * 0.6, distort(mix(clunk * 0.9, slide * 0.5), 2.0)])


def door_pass():
    w = bandpass(noise(0.45, 51), 200, 1600) * adsr(0.45, 0.08, 0.1, 0.6, 0.25)
    return lowpass_sweep(w, 600, 3000, 12) * 0.6


def lift():
    hum = lowpass(osc("saw", 90, 0.6) + osc("saw", 91.5, 0.6), 500) * adsr(0.6, 0.1, 0.1, 0.8, 0.3)
    clank = lowpass(noise(0.06, 53), 900) * decay(0.06, 60)
    return mix(hum * 0.3, clank * 0.8)


def buy():
    a = osc("square", mtof(88), 0.08) * decay(0.08, 25)
    b = osc("square", mtof(95), 0.16) * decay(0.16, 18)
    ring = highpass(noise(0.12, 55), 5000) * decay(0.12, 30)
    return mix(lowpass(np.concatenate([a, b]), 6000) * 0.35, np.concatenate([np.zeros(samples(0.08)), ring * 0.3]))


# --- UI ----------------------------------------------------------------------------------------

def ui_move():
    return lowpass(distort(osc("square", 1100, 0.05), 2.0), 5000) * decay(0.05, 45) * 0.3


def ui_confirm():
    a = osc("square", mtof(84), 0.06) * decay(0.06, 40)
    b = osc("square", mtof(91), 0.1) * decay(0.1, 25)
    return lowpass(np.concatenate([a, b]), 6000) * 0.3


def ui_back():
    a = osc("square", mtof(79), 0.06) * decay(0.06, 40)
    b = osc("square", mtof(72), 0.1) * decay(0.1, 25)
    return lowpass(np.concatenate([a, b]), 5000) * 0.3


def ui_open():
    w = lowpass_sweep(noise(0.22, 57), 300, 5000, 12) * adsr(0.22, 0.01, 0.05, 0.6, 0.1)
    tone = osc("sine", sweep(500, 1100, 0.22), 0.22) * decay(0.22, 12)
    return w * 0.35 + tone * 0.25


def ui_close():
    w = lowpass_sweep(noise(0.18, 58), 5000, 300, 12) * adsr(0.18, 0.01, 0.05, 0.6, 0.08)
    tone = osc("sine", sweep(1000, 450, 0.18), 0.18) * decay(0.18, 14)
    return lowpass(distort(w * 0.35 + tone * 0.25, 2.5), 6000)


def toast():
    return (osc("sine", mtof(93), 0.25) * decay(0.25, 12) + osc("sine", mtof(100), 0.25) * decay(0.25, 20) * 0.4) * 0.4


def text():
    return highpass(osc("square", 2200, 0.02), 1500) * decay(0.02, 150) * 0.25


def bark():
    return (osc("sine", mtof(81), 0.09) * decay(0.09, 25) + osc("sine", mtof(86), 0.09) * decay(0.09, 40)) * 0.35


def title_start():
    thump = osc("sine", sweep(120, 45, 0.5), 0.5) * decay(0.5, 7)
    rise = lowpass_sweep(osc("saw", 110, 0.8) + osc("saw", 110.7, 0.8), 200, 4000, 24) * adsr(0.8, 0.1, 0.1, 0.8, 0.3)
    return distort(mix(thump * 0.8, rise * 0.3), 1.8)


SOUNDS = {
    "jump": jump, "wall_jump": wall_jump, "dash": dash, "land": land, "swing": swing, "hazard": hazard,
    "hit": hit, "hit_heavy": hit_heavy, "hit_guard": hit_guard,
    "shoot": shoot, "shoot_nail": shoot_nail, "shoot_rivet": shoot_rivet, "drone_shot": drone_shot,
    "hurt": hurt, "die": die, "enemy_die": enemy_die, "mech_die": mech_die,
    "tell": tell, "lunge": lunge, "stun": stun, "slam": slam, "beam_charge": beam_charge, "beam_fire": beam_fire, "roar": roar,
    "hack_guard": hack_guard, "hack_burst": hack_burst, "hack_pulse": hack_pulse, "deny": deny, "hack_acquire": hack_acquire,
    "pickup": pickup, "credits": credits, "stat_up": stat_up, "level_up": level_up, "quest": quest, "save": save,
    "door": door, "breach": breach, "door_pass": door_pass, "lift": lift, "buy": buy,
    "ui_move": ui_move, "ui_confirm": ui_confirm, "ui_back": ui_back, "ui_open": ui_open, "ui_close": ui_close,
    "toast": toast, "text": text, "bark": bark, "title_start": title_start,
}


# The loudness class per sound (audio/audio.json sfx.classes has the target per class). table.py reads
# this once to seed sfx.json; after that the table is the truth.
CLASSES = {
    "move": ["jump", "wall_jump", "dash", "swing"],
    "impact": ["land", "hazard", "hit", "hit_heavy", "hit_guard", "hurt", "slam"],
    "shot": ["shoot", "shoot_nail", "shoot_rivet", "drone_shot"],
    "death": ["die", "enemy_die", "mech_die"],
    "enemy": ["tell", "lunge", "stun", "beam_charge", "beam_fire", "roar"],
    "hack": ["hack_guard", "hack_burst", "hack_pulse", "deny", "hack_acquire"],
    "stinger": ["pickup", "credits", "stat_up", "level_up", "quest", "save", "buy", "toast", "title_start"],
    "world": ["door", "breach", "door_pass", "lift"],
    "ui": ["ui_move", "ui_confirm", "ui_back", "ui_open", "ui_close", "text", "bark"],
}
