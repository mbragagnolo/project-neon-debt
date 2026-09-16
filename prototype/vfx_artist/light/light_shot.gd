extends SceneTree
## 14-C through the real world scene with light effects added from outside
## the project: HDR 2D and a WorldEnvironment glow (bloom), and one light
## shaft under the window as an additive polygon with vertex colours.
## Nothing in game/ is touched. One capture per run (the readback stalls).
##
##   godot --path game --windowed --resolution 1920x1080 -s <abs>/light_shot.gd -- \
##       mode=today out=<abs png> player=330,900
##   ... mode=glow threshold=0.7 intensity=0.6 strength=0.9 bloom=0.0 blend=softlight levels=3,5
##   ... mode=shaft (glow as above) shaft_alpha=0.28 shaft_lean=220 shaft_spread=80
##
## `mode=today` changes nothing: the control shot from the same rig.

var args: Dictionary = {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var eq: int = arg.find("=")
		if eq > 0:
			args[arg.substr(0, eq)] = arg.substr(eq + 1)
	_run()


func _run() -> void:
	await process_frame
	var mode: String = args.get("mode", "today")
	root.get_node("Settings").set("screen_shake", false)
	var world: Node = (load("res://rooms/world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	# The world travels to the start room behind a fade; wait it out.
	await create_timer(float(args.get("wait", "2.0"))).timeout
	var player: Node = get_first_node_in_group(&"player")
	if player is Node2D and args.has("player"):
		(player as Node2D).global_position = _vec(args["player"])
		var cam: Node = player.get_node_or_null("Camera2D")
		if cam != null and cam.has_method(&"snap_to_target"):
			cam.call(&"snap_to_target")
	await create_timer(0.3).timeout

	if args.has("boost"):
		# Overexpose the room's own lights, to see what blooms once a surface goes past 1.0 in HDR.
		var room: Node = world.get("current_room")
		var n: int = 0
		for light: Node in (room if room != null else world).find_children("*", "PointLight2D", true, false):
			(light as PointLight2D).energy *= float(args["boost"])
			n += 1
		print("boost: ", n, " lights x ", args["boost"])
	if mode in ["glow", "shaft"]:
		_glow()
	if mode == "shaft":
		_shaft(world)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var cam_node: Camera2D = root.get_viewport().get_camera_2d()
	if cam_node != null:
		print("camera centre ", cam_node.get_screen_center_position(), " zoom ", cam_node.zoom, " hdr_2d ", root.use_hdr_2d)
	var img: Image = root.get_viewport().get_texture().get_image()
	var path: String = args.get("out", "light_shot.png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("shot -> ", path)
	quit()


## Bloom: the viewport in HDR so bright surfaces can exceed 1.0, and a glow
## on the environment. In 2D the glow thresholds on the canvas's own
## values, so the window plane (painted bright) and the hot points bloom.
func _glow() -> void:
	root.use_hdr_2d = args.get("hdr", "1") == "1"
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_hdr_threshold = float(args.get("threshold", "0.7"))
	env.glow_intensity = float(args.get("intensity", "0.6"))
	env.glow_strength = float(args.get("strength", "0.9"))
	env.glow_bloom = float(args.get("bloom", "0.0"))
	env.glow_hdr_scale = float(args.get("hdr_scale", "2.0"))
	var blend: String = args.get("blend", "softlight")
	env.glow_blend_mode = {"additive": Environment.GLOW_BLEND_MODE_ADDITIVE, "screen": Environment.GLOW_BLEND_MODE_SCREEN,
		"softlight": Environment.GLOW_BLEND_MODE_SOFTLIGHT, "replace": Environment.GLOW_BLEND_MODE_REPLACE,
		"mix": Environment.GLOW_BLEND_MODE_MIX}.get(blend, Environment.GLOW_BLEND_MODE_SOFTLIGHT)
	for i in 7:
		env.set_glow_level(i, false)
	for level: String in String(args.get("levels", "3,5")).split(","):
		env.set_glow_level(int(level) - 1, true)
	var we := WorldEnvironment.new()
	we.name = "LightSpikeGlow"
	we.environment = env
	root.add_child(we)
	print("glow: threshold ", env.glow_hdr_threshold, " intensity ", env.glow_intensity, " strength ", env.glow_strength,
		" bloom ", env.glow_bloom, " blend ", blend, " levels ", args.get("levels", "3,5"))


## One shaft: the window's glass (room px 846..1074 x 606..954 in 14-C) cast
## down and left to the floor at 1020 as an additive polygon, cold, fading
## to nothing at the floor. Vertex colours carry the fade; three thinner
## bands inside it carry the "rays". Placed in the room so the ambient
## darkens it like everything else the light touches.
func _shaft(world: Node) -> void:
	var room: Node = world.get("current_room")
	if room == null:
		room = world
	var alpha: float = float(args.get("shaft_alpha", "0.28"))
	var lean: float = float(args.get("shaft_lean", "220"))
	var spread: float = float(args.get("shaft_spread", "80"))
	var colour := Color(0.55, 0.72, 1.0)
	var glass := Rect2(846, 606, 228, 348)
	var floor_y: float = float(args.get("shaft_floor", "1020"))
	var holder := Node2D.new()
	holder.name = "LightSpikeShaft"
	holder.z_index = 4
	room.add_child(holder)
	# One wide band and three rays inside it; each is drawn as slices whose
	# alpha follows a sine across the band, so the edges are soft, and the
	# vertex colours fade it to nothing at the floor.
	var bands: Array = [[0.0, 1.0, alpha * 0.6]]
	for i in 3:
		var u0: float = 0.1 + i * 0.3
		bands.append([u0, u0 + 0.14, alpha])
	var slices: int = int(args.get("shaft_slices", "8"))
	for band: Array in bands:
		var bu0: float = float(band[0])
		var bu1: float = float(band[1])
		for k in slices:
			var t0: float = float(k) / slices
			var t1: float = float(k + 1) / slices
			var u0: float = bu0 + (bu1 - bu0) * t0
			var u1: float = bu0 + (bu1 - bu0) * t1
			var a: float = float(band[2]) * sin(PI * (t0 + t1) * 0.5)
			var x0: float = glass.position.x + glass.size.x * u0
			var x1: float = glass.position.x + glass.size.x * u1
			var poly := Polygon2D.new()
			poly.polygon = PackedVector2Array([
				Vector2(x0, glass.position.y), Vector2(x1, glass.position.y),
				Vector2(x1 - lean + spread * u1, floor_y), Vector2(x0 - lean + spread * u0, floor_y)])
			poly.vertex_colors = PackedColorArray([Color(colour, a), Color(colour, a), Color(colour, 0.0), Color(colour, 0.0)])
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			poly.material = mat
			holder.add_child(poly)
	print("shaft: alpha ", alpha, " lean ", lean, " spread ", spread, " in ", room.name)


func _vec(text: String) -> Vector2:
	var parts: PackedStringArray = text.split(",")
	return Vector2(float(parts[0]), float(parts[1])) if parts.size() >= 2 else Vector2.ZERO
