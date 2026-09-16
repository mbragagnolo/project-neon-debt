extends Node
## Screenshot rig: instance a room, wait for the sprites to settle, save the
## viewport to a PNG, quit. Needs a real window (headless Godot does not
## render), so:
##
##     godot --path . --windowed --resolution 1600x900 tools/shot_gym.tscn
##     godot --path . --windowed --resolution 1600x900 tools/shot_gym.tscn -- \
##         room=res://rooms/combat_gym.tscn out=res://tools/art/work/scav/ingame.png \
##         player=2700,1380 spawn=res://src/enemies/drone/drone.tscn:2500,1200 wait=1.5
##
## Everything after `--` is optional: `room` (default the movement gym),
## `out` (default work/ingame.png), `player=x,y` moves the player so the
## camera lands where the subject is (applied again after the wait, so it
## holds in world.tscn), `travel=room_id:door` travels the world to another
## room first, `zoom=1.5` sets the camera zoom, `spawn=scene:x,y` (repeatable, `;` to
## chain) drops extra enemies or NPCs into the room, `wait` is the settle time
## in seconds. Used to eyeball an art change in the actual scene without
## opening the editor.

const DEFAULT_ROOM := "res://rooms/gym.tscn"
const DEFAULT_OUT := "res://tools/art/work/ingame.png"


func _ready() -> void:
	var args: Dictionary = _user_args()
	var room_path: String = args.get("room", DEFAULT_ROOM)
	var out: String = args.get("out", DEFAULT_OUT)
	var wait: float = float(args.get("wait", "1.2"))

	var room: Node = load(room_path).instantiate()
	add_child(room)

	if args.has("player"):
		var player: Node = get_tree().get_first_node_in_group(&"player")
		if player is Node2D:
			(player as Node2D).global_position = _vec(args["player"])
			var cam: Node = player.get_node_or_null("Camera2D")
			if cam != null and cam.has_method(&"snap_to_target"):
				cam.call(&"snap_to_target")
	if args.has("zoom"):
		var player_node: Node = get_tree().get_first_node_in_group(&"player")
		var cam2: Node = player_node.get_node_or_null("Camera2D") if player_node != null else null
		if cam2 is Camera2D:
			var z: float = float(args["zoom"])
			(cam2 as Camera2D).zoom = Vector2(z, z)
			if cam2.has_method(&"snap_to_target"):
				cam2.call(&"snap_to_target")

	for entry: String in String(args.get("spawn", "")).split(";", false):
		var colon: int = entry.rfind(":")
		if colon < 0:
			continue
		var scene: PackedScene = load(entry.substr(0, colon))
		if scene == null:
			continue
		var node: Node = scene.instantiate()
		room.add_child(node)
		if node is Node2D:
			(node as Node2D).global_position = _vec(entry.substr(colon + 1))

	await get_tree().create_timer(wait).timeout
	# The world places its own player once its start travel lands, so a
	# `travel` or a `player` given for world.tscn is applied after the wait.
	if args.has("travel") and room.has_method(&"travel"):
		var parts: PackedStringArray = String(args["travel"]).split(":")
		await room.call(&"travel", StringName(parts[0]), StringName(parts[1] if parts.size() > 1 else "start"))
		await get_tree().create_timer(0.5).timeout
	if args.has("player"):
		var late_player: Node = get_tree().get_first_node_in_group(&"player")
		if late_player is Node2D:
			(late_player as Node2D).global_position = _vec(args["player"])
			var late_cam: Node = late_player.get_node_or_null("Camera2D")
			if late_cam != null and late_cam.has_method(&"snap_to_target"):
				late_cam.call(&"snap_to_target")
			await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	# Where things landed, for registering planes against the camera.
	var cam_node: Camera2D = get_viewport().get_camera_2d()
	if cam_node != null:
		print("camera centre ", cam_node.get_screen_center_position(), " zoom ", cam_node.zoom)
	for scroller: Node in room.find_children("*", "Parallax2D", true, false):
		print("parallax ", scroller.name, " at ", (scroller as Node2D).position, " screen_offset ", scroller.get("screen_offset"), " scroll_offset ", scroller.get("scroll_offset"))
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("shot -> ", path)
	get_tree().quit()


func _user_args() -> Dictionary:
	var out: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		var eq: int = arg.find("=")
		if eq > 0:
			out[arg.substr(0, eq)] = arg.substr(eq + 1)
	return out


func _vec(text: String) -> Vector2:
	var parts: PackedStringArray = text.split(",")
	if parts.size() < 2:
		return Vector2.ZERO
	return Vector2(float(parts[0]), float(parts[1]))
