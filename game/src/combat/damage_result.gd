class_name DamageResult
extends RefCounted
## What one trip through the pipeline produced.
##
## Returned rather than merely applied, so a test can assert on the *reason* a
## hit did nothing. "The dummy took no damage" is true for a whiff, a repeat
## hit of the same swing, an i-frame window and a shield — and those are four
## different bugs.

## Why a hit produced nothing. `NONE` means it landed.
enum Rejection {
	NONE,
	## Step 2 — this swing already hit this target.
	ALREADY_HIT,
	## Step 3 — target is dead, or inside an i-frame window.
	INVULNERABLE,
	## Step 5 — a positional immunity tag rejected it outright, before DEF.
	IMMUNE,
}

var landed: bool = false
var damage: int = 0
## True when `damage` met the target's `stagger_threshold` (step 8).
var staggered: bool = false
var rejection: Rejection = Rejection.NONE


static func rejected(reason: Rejection) -> DamageResult:
	var result := DamageResult.new()
	result.rejection = reason
	return result


static func hit(amount: int, did_stagger: bool) -> DamageResult:
	var result := DamageResult.new()
	result.landed = true
	result.damage = amount
	result.staggered = did_stagger
	return result
