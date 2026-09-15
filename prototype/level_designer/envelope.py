"""A Python port of MovementConfig + MovementEnvelope, read from movement_config.tres."""
import math
import re


def load_config(tres_path):
    cfg = {}
    in_resource = False
    with open(tres_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line == "[resource]":
                in_resource = True
                continue
            if not in_resource or "=" not in line:
                continue
            k, v = [s.strip() for s in line.split("=", 1)]
            if v in ("true", "false"):
                cfg[k] = v == "true"
            elif re.fullmatch(r"-?\d+(\.\d+)?", v):
                cfg[k] = float(v)
    return cfg


class Envelope:
    GATE_MARGIN = 1.15
    BODY_WIDTH = 48.0

    def __init__(self, cfg):
        self.c = cfg

    # MovementConfig
    def rise_gravity(self):
        t = self.c["jump_time_to_apex"]
        return 2.0 * self.c["jump_height"] / (t * t)

    def fall_gravity(self):
        return self.rise_gravity() * self.c["fall_gravity_multiplier"]

    # MovementEnvelope
    def rise_time(self):
        return self.c["jump_time_to_apex"]

    def fall_time(self):
        return math.sqrt(2.0 * self.c["jump_height"] / self.fall_gravity())

    def flight_time(self):
        return self.rise_time() + self.fall_time()

    def jump_height(self):
        return self.c["jump_height"]

    def flat_jump_distance(self):
        return self.c["run_speed"] * self.flight_time()

    def dash_distance(self):
        return self.c["dash_distance"]

    def jump_air_dash_distance(self):
        return self.flat_jump_distance() + self.dash_distance()

    def max_gap(self, has_air_dash):
        if has_air_dash:
            return self.jump_air_dash_distance()
        return max(self.flat_jump_distance(), self.dash_distance())

    def wall_jump_height(self):
        return self.c["wall_jump_height"]

    def wall_jump_reach(self):
        g = self.rise_gravity()
        rise = math.sqrt(2.0 * self.c["wall_jump_height"] / g)
        fall = math.sqrt(2.0 * self.c["wall_jump_height"] / self.fall_gravity())
        lock = self.c["wall_jump_lockout_time"]
        return self.c["wall_jump_push"] * lock + self.c["run_speed"] * (rise + fall - lock)

    def is_valid_air_dash_gate(self, gap):
        travel = gap - self.BODY_WIDTH
        return travel >= self.max_gap(False) * self.GATE_MARGIN and travel * self.GATE_MARGIN <= self.max_gap(True)

    def is_plain_jump(self, gap):
        return (gap - self.BODY_WIDTH) * self.GATE_MARGIN <= self.max_gap(False)

    def is_valid_tease_height(self, h):
        return h >= self.jump_height() * self.GATE_MARGIN

    def is_climbable_shaft(self, width):
        return (width - self.BODY_WIDTH) * self.GATE_MARGIN <= self.wall_jump_reach()

    def summary(self):
        return {
            "flat jump (px)": round(self.flat_jump_distance(), 1),
            "dash (px)": self.dash_distance(),
            "jump + air dash (px)": round(self.jump_air_dash_distance(), 1),
            "jump height (px)": self.jump_height(),
            "wall jump reach (px)": round(self.wall_jump_reach(), 1),
        }
