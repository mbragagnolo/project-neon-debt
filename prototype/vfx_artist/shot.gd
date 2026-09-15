extends SceneTree
## The hit frame in the engine, from outside the project (nothing in game/
## is touched): the combat gym, a Scav frozen in the wrench's box, one swing,
## a capture during hitstop and one a few frames later.
##
##   godot --path game --windowed --resolution 1920x1080 -s <abs>/shot.gd -- mode=before out=<abs dir>
##   godot --path game --windowed --resolution 1920x1080 -s <abs>/shot.gd -- mode=after out=<abs dir> \
##       sheet=<abs>/out/sheets/spark.hit.png hframes=6 anchor=32,32 fps=30
##
## `before` adds the game's own Juice node (the world scene's, not in the gym
## by default) so the shot shows what ships today; `after` adds a Sprite2D
## with the baked sheet at the target's centre instead, frame 0 on the hit,
## stepped at the effect's fps once hitstop lets go.

const PLAYER_AT := Vector2(1800.0, 1380.0)
const SCAV_AT := Vector2(1850.0, 1380.0)

var args: Dictionary = {}
var hit_target: Node = null
var hit_frame_count: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var eq: int = arg.find("=")
		if eq > 0:
			args[arg.substr(0, eq)] = arg.substr(eq + 1)
	_run()


func _run() -> void:
	print("shot.gd: start, args ", args)
	await process_frame
	print("shot.gd: first frame")
	var mode: String = args.get("mode", "before")
	var out_dir: String = args.get("out", ".")
	root.get_node("Settings").set("screen_shake", false)

	var gym: Node = (load("res://rooms/combat_gym.tscn") as PackedScene).instantiate()
	root.add_child(gym)
	await process_frame
	print("shot.gd: gym up")
	var player: Node2D = get_first_node_in_group(&"player") as Node2D
	player.global_position = PLAYER_AT
	var scav: Node2D = (load("res://src/enemies/scav/scav.tscn") as PackedScene).instantiate()
	gym.add_child(scav)
	scav.global_position = SCAV_AT
	await physics_frame
	# Hold the Scav where it is: no patrol, no chase, idle plays on.
	scav.set_physics_process(false)
	for child: Node in scav.get_children():
		child.set_physics_process(false)
	scav.call(&"set_facing", -1)
	player.call(&"set_facing", 1)
	if mode == "before":
		# Loaded at run time, not named: a class_name that touches an autoload
		# cannot compile while this outside script is being loaded (the
		# autoloads are not up yet), and a compile failure here hangs the run.
		var juice: Node = (load("res://src/fx/juice.gd") as GDScript).new()
		gym.add_child(juice)
	root.get_node("Events").connect(&"damage_dealt", _on_damage)
	# Made before the swing: loading the sheet on the hit costs a frame and
	# the 33 ms hold is two.
	var sprite: Sprite2D = null
	if mode == "after":
		sprite = _effect_sprite()
		sprite.visible = false
		gym.add_child(sprite)
	for i in 30:
		await physics_frame
	var cam: Node = player.get_node_or_null("Camera2D")
	if cam != null and cam.has_method(&"snap_to_target"):
		cam.call(&"snap_to_target")
	await process_frame
	print("shot.gd: swinging")
	Input.action_press("attack_melee")
	await physics_frame
	Input.action_release("attack_melee")
	var waited: int = 0
	while hit_target == null and waited < 30:
		await physics_frame
		waited += 1
	if hit_target == null:
		print("no hit landed")
		quit()
		return
	var hitstop: Node = root.get_node("Hitstop")
	print("hit on ", hit_target.name, " after ", waited, " physics frames; hitstop active ", hitstop.call(&"is_active"), " remaining ms ", hitstop.call(&"remaining_msec"))

	if sprite != null:
		var centre: Vector2 = hit_target.call(&"center") if hit_target.has_method(&"center") else (hit_target as Node2D).global_position
		var anchor: Vector2 = _vec(args.get("anchor", "32,32"))
		# Whole art pixels: the camera snaps to 2 room px, so does the effect.
		sprite.global_position = (centre - anchor).snapped(Vector2(2.0, 2.0))
		sprite.visible = true
	await RenderingServer.frame_post_draw
	var capture: String = args.get("capture", "hold")
	if capture == "hold":
		# The viewport readback stalls the engine for a frame or more, so a
		# run captures once: the hold, or the decay (capture=decay).
		print("capture hold: hitstop active ", hitstop.call(&"is_active"), " time_scale ", Engine.time_scale, " player clip frame ", _player_frame(player))
		_capture(out_dir.path_join("shot_%s_hold.png" % mode))
		quit()
		return

	# Let hitstop go, then a few frames into the decay (effect frame 2).
	var fps: float = float(args.get("fps", "30"))
	var decay_ms: int = int(args.get("decay_ms", "67"))
	while hitstop.call(&"is_active"):
		await process_frame
	var t0: int = Time.get_ticks_msec()
	var elapsed: int = 0
	while elapsed < decay_ms:
		await process_frame
		elapsed = Time.get_ticks_msec() - t0
		if sprite != null:
			sprite.frame = mini(sprite.hframes - 1, int(floor(elapsed * fps / 1000.0)))
	await RenderingServer.frame_post_draw
	print("capture decay: ", elapsed, " ms after release, effect frame ", sprite.frame if sprite != null else -1, ", player clip frame ", _player_frame(player))
	_capture(out_dir.path_join("shot_%s_decay.png" % mode))
	quit()


func _on_damage(target: Node, amount: int, _source: Node) -> void:
	if hit_target == null:
		hit_target = target
		print("damage_dealt ", amount, " on ", target.name)


func _effect_sprite() -> Sprite2D:
	var img := Image.load_from_file(args["sheet"])
	var tex := ImageTexture.create_from_image(img)
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.hframes = int(args.get("hframes", "6"))
	s.frame = 0
	s.centered = false
	s.z_index = 50
	return s


func _player_frame(player: Node) -> int:
	var sprite: Node = player.get_node_or_null("Visual/Sprite")
	return (sprite as Sprite2D).frame if sprite is Sprite2D else -1


func _capture(path: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("shot -> ", path)


func _vec(text: String) -> Vector2:
	var parts: PackedStringArray = text.split(",")
	return Vector2(float(parts[0]), float(parts[1])) if parts.size() >= 2 else Vector2.ZERO
