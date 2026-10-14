extends SceneTree
const Audio := preload("res://scripts/ui_audio.gd")
const SoundButton := preload("res://scripts/ui/sound_button.gd")
const SETTINGS_PATH := "res://work/audio-service-test.cfg"
var service: Node
var played: Array[String] = []
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in range(2): await process_frame

func run() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(2))
	DirAccess.remove_absolute(SETTINGS_PATH)
	service = Audio.new()
	service.path = SETTINGS_PATH
	service.cue_played.connect(func(cue: String) -> void: played.append(cue))
	root.add_child(service)
	await settle()
	check(service.enabled and played.is_empty(), "Default enabled; initialization emits no action cue")
	check(service.get_child_count() == 3, "Two feedback players plus one persistent music player")
	check(AudioServer.get_bus_index("UI_SFX") >= 0, "Dedicated SFX bus exists")
	for cue: String in Audio.STREAMS:
		var stream: AudioStreamWAV = Audio.STREAMS[cue]
		check(stream.mix_rate == 48000 and not stream.stereo and stream.get_length() < 0.6, "Short mono resource " + cue)
	service.request("tap")
	service.request("select")
	service.request("navigate")
	service.request("focus")
	service.request("correct")
	service.request("complete")
	service.request("retry")
	await settle()
	check(played == ["complete"], "One completion supersedes all same-turn ordinary/result cues")
	service.request("complete")
	await settle()
	check(played.size() == 1, "Immediate identical cue is debounced")
	await create_timer(0.11).timeout
	service.request("complete")
	await settle()
	check(played.size() == 2, "Cue is accepted after debounce interval")
	service.request("adjust")
	await settle()
	service.request("adjust")
	await settle()
	check(played.count("adjust") == 1, "Adjust repeats are throttled")
	service.request("tap")
	service.set_enabled(false)
	await settle()
	check(played.count("tap") == 0, "Muting drops pending cues")
	check(not service._ordinary.playing and not service._result.playing, "Muting stops both channels")
	var config := ConfigFile.new()
	check(config.load(SETTINGS_PATH) == OK and config.get_value("audio", "enabled", true) == false, "Mute preference persisted")
	service.request("navigate")
	await settle()
	check(played.count("navigate") == 0, "Muted actions are silent")
	service.set_enabled(true)
	await settle()
	check(played.count("tap") == 1, "Enabling plays one audition tap")
	service.request("swap")
	service.set_foreground(false)
	service.request("back")
	await settle()
	service.set_foreground(true)
	await settle()
	check(played.count("swap") == 0 and played.count("back") == 0, "Background cancels pending feedback without replay")
	Audio.play_from(service, "reset")
	await settle()
	check(played.back() == "reset", "Static helper routes to persistent service")
	var before_count := played.size()
	Audio.play_from(service, "")
	service.request("unknown")
	await settle()
	check(played.size() == before_count, "Unknown and empty cues ignored")
	var slider := HSlider.new()
	root.add_child(slider)
	Audio.bind_slider(slider)
	Audio.bind_slider(slider)
	await create_timer(0.11).timeout
	slider.value = 30
	await settle()
	check(played.size() == before_count, "Programmatic slider change stays silent")
	slider.drag_ended.emit(false)
	await settle()
	check(played.size() == before_count, "Unchanged slider release stays silent")
	slider.drag_ended.emit(true)
	await settle()
	check(played.size() == before_count + 1 and played.back() == "adjust", "Changed slider release emits one adjust; binding idempotent")
	await create_timer(0.11).timeout
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.pressed = true
	slider.gui_input.emit(right)
	slider.value = 31
	await settle()
	check(played.size() == before_count + 2, "Keyboard-driven slider change emits adjust")
	slider.gui_input.emit(right)
	await settle()
	check(played.size() == before_count + 2, "Keyboard at unchanged boundary stays silent")
	var mute := SoundButton.new()
	mute.setup(service)
	root.add_child(mute)
	await settle()
	check(mute.custom_minimum_size == Vector2(44, 44) and mute.tooltip_text.contains("声音开启"), "Mute control size and label")
	mute.pressed.emit()
	check(not service.enabled and mute.tooltip_text.contains("已静音"), "Mute button changes preference and label")
	mute.pressed.emit()
	await settle()
	check(service.enabled and played.back() == "tap", "Mute button enables with audition")
	service.set_enabled(false)
	var bus_count := AudioServer.bus_count
	var restored := Audio.new()
	restored.path = SETTINGS_PATH
	root.add_child(restored)
	await settle()
	check(not restored.enabled and AudioServer.bus_count == bus_count, "Preference reload is silent and bus is reused")
	service.set_foreground(false)
	await create_timer(0.1).timeout
	restored.queue_free()
	slider.queue_free()
	mute.queue_free()
	service.queue_free()
	await settle()
	await create_timer(0.1).timeout
	DirAccess.remove_absolute(SETTINGS_PATH)
	print("PASS: audio priority, deduplication, preference, foreground, resources, slider and mute control" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
