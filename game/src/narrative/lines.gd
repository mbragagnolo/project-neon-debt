class_name Lines
extends RefCounted
## Every written line in the slice (docs/narrative/hook.md).
##
## The protagonist talks Castlevania-style: a handful of terse lines at story
## beats, never a tree, never a choice. Scarcity is what makes them land, so
## this file is deliberately short. Tone: working-class cyberpunk — paycheck
## dread, gallows humour, the debt statement as the scariest artifact.
##
## Names, under the hook's conventions. The corp is ONE name used everywhere;
## the protagonist is printed the way the corp would print them, on
## paperwork; NPCs get Stacks slang.

## The creditor. On the terminals, the augs, the Landlord's paperwork.
const CORP := "VESTA"
const CORP_LONG := "VESTA Somatic Finance"
## The account holder — how the corp prints it.
const PROTAGONIST := "OKONKWO, D."
const PROTAGONIST_SHORT := "Dani"
const ACCOUNT := "ACCT 14C-0091-77"
## The vendor / ripperdoc, ground floor.
const VENDOR := "Stitch"
## The neighbour, 14th floor.
const NEIGHBOUR := "Marisol"
## The dead defaulter in the Gut.
const DEFAULTER := "Ferro"
## The enforcer. A title, not a name — the Stacks never learned his.
const BOSS := "The Landlord"

# --- The protagonist's lines ------------------------------------------------

const BARK_WAKE := "Fourteen-C. Still mine, as long as the payments clear."
const BARK_FIRST_SAVE := "Their terminal. Their body. Every save is a receipt."
const BARK_MAG_HOOK := "A tower tech's mag-hook. He's not going to need it."
const BARK_CYBERDECK := "More room to run their programs. Or mine."
const BARK_OVERLOAD := "Corporate property, pointed the other way."
const BARK_BREACH := "Every door in the Stacks answers to VESTA. Now one of them answers to me."
const BARK_SIDEWINDER := "A Sidewinder unit, still sealed. Legs like these need surgery, not a screwdriver."
const BARK_SIDEWINDER_INSTALLED := "Stitch says it'll hold. Stitch says a lot of things."
const BARK_CHIP := "Ferro's chip. Whatever's on it, he'd rather die down here than let them take it."
const BARK_QUEST_DONE := "A dead man's hardhat. Fits."
const BARK_PRE_BOSS := "He's got the override. I've got a wrench."
const BARK_POST_BOSS := "It's not forgiveness. It's the keys."

# --- NPC dialogue -----------------------------------------------------------

const MARISOL_OFFER: Array[String] = [
	"You're 14-C. The one still paying.",
	"Ferro ran when Collections hit twelve. Took his chip and went down into the Gut.",
	"He's dead down there. I know that. I want the chip back before they repossess what's left of him.",
	"Bring it and you can have his hardhat. He'd have hated that. Take it anyway.",
]
const MARISOL_ACTIVE: Array[String] = [
	"The Gut. Past the pumps, below the lift. The water's live — VESTA never paid to ground it.",
]
const MARISOL_COMPLETE: Array[String] = [
	"That's his. Thank you.",
	"The hat's yours. Don't die in it.",
]
const MARISOL_AFTER: Array[String] = [
	"Go on. The Landlord's got a floor to work, and it's ours.",
]

const STITCH_GREET: Array[String] = [
	"Stitch. Ripperdoc, pawn, whatever the day needs.",
	"Credits only. VESTA stopped taking my calls.",
]
const STITCH_INSTALL: Array[String] = [
	"A Sidewinder. Sealed unit, corp stamp and all. Where'd you-- no. Don't tell me.",
	"Lie down. This won't hurt. The anaesthetic's on your tab.",
]
const STITCH_AFTER_INSTALL: Array[String] = [
	"Legs feel wrong for a day. Then they feel like yours. That's the trick of it.",
]

# --- Signage ------------------------------------------------------------------

const NOTICE_REPOSSESSION := "%s\n%s\nNOTICE OF DELINQUENCY\nRemote disablement pending.\nCollections has been assigned." % [CORP_LONG, ACCOUNT]
const NOTICE_TIER := "%s FIRMWARE\nTIER 2 · LOCKED" % CORP
const NOTICE_CARE := "%s CARE TERMINAL\nRestoration is a service. Services are billed." % CORP
