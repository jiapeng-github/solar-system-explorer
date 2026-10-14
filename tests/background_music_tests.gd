extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func frames() -> void:
	for i in range(4): await process_frame
func run() -> void:
	create_timer(45).timeout.connect(func(): quit(2))
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/music-test-progress.json"
	app.quality.path = "res://work/music-test-quality.cfg"
	app.audio.path = "res://work/music-test-audio.cfg"
	DirAccess.remove_absolute(app.audio.path)
	app.progress.reset_progress()
	root.add_child(app)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var audio = app.audio
	audio.set_process(false)
	await frames()
	var music: AudioStreamPlayer = audio._music
	var original_id := music.get_instance_id()
	check(music.playing and not music.stream_paused,"Enabled startup starts music")
	check(music.bus == &"Music" and audio._ordinary.bus == &"UI_SFX","Separate music and feedback buses")
	check(music.stream is AudioStreamWAV and music.stream.format == AudioStreamWAV.FORMAT_16_BITS,"Uncompressed PCM loop preserves original seam")
	check(music.stream.stereo and music.stream.mix_rate == 48000,"Stereo 48kHz music")
	check(music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and music.stream.loop_end == 2880000,"60-second native sample loop")
	check(music.volume_db < -40,"Startup begins quietly")
	audio._process(1.5)
	check(is_equal_approx(music.volume_db,-7),"Fade reaches designed music level")
	music.seek(12.0)
	await create_timer(0.15).timeout
	var before := music.get_playback_position()
	for page in ["explore","compare","knowledge","progress","home"]:
		app.navigate(page)
		await frames()
		check(audio._music.get_instance_id() == original_id,"Page keeps one music player: "+page)
	check(music.get_playback_position() >= before,"Navigation never resets playback position")
	for mode in ["day","year","seasons"]:
		app._open_lesson(mode)
		await frames()
		check(audio._music.get_instance_id() == original_id,"Experiment shares global music: "+mode)
	audio.request("correct")
	await frames()
	audio._process(0.1)
	check(is_equal_approx(music.volume_db,-11),"Answer feedback ducks music by 4dB")
	for i in range(20): audio._process(0.1)
	check(is_equal_approx(music.volume_db,-7),"Music returns smoothly after feedback")
	audio.set_enabled(false)
	var paused_at := music.get_playback_position()
	await create_timer(0.15).timeout
	check(music.stream_paused,"Mute immediately pauses music")
	check(absf(music.get_playback_position()-paused_at)<0.05,"Muted playback retains its position")
	check(not audio._ordinary.playing and not audio._result.playing,"Mute stops both sound effect channels")
	app._reset_learning()
	check(not audio.enabled and music.stream_paused,"Learning reset preserves music mute")
	var restored = preload("res://scripts/ui_audio.gd").new()
	restored.path = audio.path
	root.add_child(restored)
	check(not restored.enabled and not restored._music.playing,"Saved mute prevents music on restart")
	restored.queue_free()
	await frames()
	audio.set_enabled(true)
	check(not music.stream_paused and music.get_playback_position()>=paused_at-0.05,"Unmute resumes, does not restart")
	check(music.volume_db < -40,"Unmute fades in")
	audio._process(1.5)
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	paused_at = music.get_playback_position()
	await create_timer(0.15).timeout
	check(music.stream_paused and absf(music.get_playback_position()-paused_at)<0.05,"Android background pauses music at current position")
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not music.stream_paused and music.volume_db < -40,"Android resume fades in")
	audio._process(1.5)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(is_equal_approx(music.volume_db,-7),"Duplicate foreground notification does not restart fade")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(music.stream_paused and not app._foreground,"Resume waits for focus when another system surface still owns it")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not music.stream_paused and music.volume_db < -40,"Music fades only after both resume conditions are satisfied")
	audio._process(1.5)
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(music.stream_paused and not app._foreground,"Focus cannot restart music while the app is still suspended")
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not music.stream_paused and music.volume_db < -40,"Resuming a focused app starts one fade")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	audio.set_enabled(false)
	audio.set_enabled(true)
	check(music.stream_paused,"Enabling sound in background cannot start music")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await create_timer(0.15).timeout
	music.seek(59.8)
	await create_timer(0.8).timeout
	check(music.playing and music.get_playback_position()<1.0,"Native music playback crosses loop boundary without stopping (position=%.3f, paused=%s, focused=%s, suspended=%s)" % [music.get_playback_position(),music.stream_paused,app._activity.focused,app._activity.paused])
	check(app._sound_button.accessibility_description.contains("背景音乐"),"Sound button describes music and effects")
	audio.set_foreground(false)
	app.queue_free()
	await create_timer(0.12).timeout
	print("PASS: music looping, fade, ducking, all-page continuity, mute persistence and Android lifecycle" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
