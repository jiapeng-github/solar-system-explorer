extends Node
## A persistent, deliberately quiet feedback layer. Call only after a user action succeeds.
signal cue_played(cue: String)
signal enabled_changed(value: bool)

const BUS := &"UI_SFX"
const MUSIC_BUS := &"Music"
const MUSIC_STREAM = preload("res://assets/music/starlight-voyage-loop.wav")
const MUSIC_DB := -7.0
const MUSIC_FADE_SECONDS := 1.5
var _music: AudioStreamPlayer
var _music_fade := 0.0
var _duck_remaining := 0.0
var _duck_db := 0.0
const STREAMS := {
	"tap": preload("res://assets/audio/01_tap.wav"),
	"navigate": preload("res://assets/audio/02_navigate.wav"),
	"back": preload("res://assets/audio/03_back.wav"),
	"select": preload("res://assets/audio/04_select.wav"),
	"toggle_on": preload("res://assets/audio/05_toggle_on.wav"),
	"toggle_off": preload("res://assets/audio/06_toggle_off.wav"),
	"focus": preload("res://assets/audio/07_focus.wav"),
	"swap": preload("res://assets/audio/08_swap.wav"),
	"adjust": preload("res://assets/audio/09_adjust.wav"),
	"correct": preload("res://assets/audio/10_correct.wav"),
	"retry": preload("res://assets/audio/11_retry.wav"),
	"complete": preload("res://assets/audio/12_complete.wav"),
	"reset": preload("res://assets/audio/13_reset.wav"),
}
const PRIORITY := {
	"tap": 0, "adjust": 1, "select": 1, "toggle_on": 1, "toggle_off": 1,
	"navigate": 2, "back": 2, "focus": 3, "swap": 3, "reset": 3,
	"correct": 4, "retry": 4, "complete": 5,
}
const RESULT_CUES := ["correct", "retry", "complete"]
var path := "user://audio.cfg"
var enabled := true
var foreground := true
var error_message := ""
var _ordinary: AudioStreamPlayer
var _result: AudioStreamPlayer
var _pending := ""
var _flush_scheduled := false
var _last_played: Dictionary = {}

func _ready() -> void:
	add_to_group("ui_audio")
	var config := ConfigFile.new()
	if config.load(path) == OK:
		var saved: Variant = config.get_value("audio", "enabled", true)
		if saved is bool: enabled = saved
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, BUS)
		AudioServer.set_bus_send(index, &"Master")
	_ordinary = _new_player("ActionSound")
	_result = _new_player("ResultSound")
	_setup_music()

func _new_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = BUS
	# WAVs are already mastered softly (roughly -20 dBFS peak); retain that balance.
	player.volume_db = -2.0
	player.max_polyphony = 1
	add_child(player)
	return player

func request(cue: String) -> void:
	if not enabled or not foreground or not is_inside_tree() or not STREAMS.has(cue): return
	var now := Time.get_ticks_msec()
	var interval := 100 if cue == "adjust" else 80
	if _last_played.has(cue) and now - int(_last_played[cue]) < interval: return
	if _pending.is_empty() or int(PRIORITY[cue]) >= int(PRIORITY[_pending]):
		_pending = cue
	if not _flush_scheduled:
		_flush_scheduled = true
		call_deferred("_flush")

func _flush() -> void:
	_flush_scheduled = false
	var cue := _pending
	_pending = ""
	if cue.is_empty() or not enabled or not foreground: return
	var player: AudioStreamPlayer = _result if cue in RESULT_CUES else _ordinary
	if cue in RESULT_CUES:
		_ordinary.stop()
		_duck_remaining = maxf(_duck_remaining,STREAMS[cue].get_length()+0.1)
	player.stop()
	player.stream = STREAMS[cue]
	player.play()
	_last_played[cue] = Time.get_ticks_msec()
	cue_played.emit(cue)

func set_enabled(value: bool, persist := true) -> void:
	if enabled == value: return
	enabled = value
	_clear()
	if persist:
		var config := ConfigFile.new()
		config.set_value("audio", "enabled", enabled)
		error_message = "" if config.save(path) == OK else "声音偏好暂未保存，重新打开后会使用原设置。"
	_sync_music()
	enabled_changed.emit(enabled)
	if enabled:
		_last_played.erase("tap")
		request("tap")

func set_foreground(value: bool) -> void:
	if foreground == value: return
	foreground = value
	if not foreground: _clear()
	_sync_music()

func _clear() -> void:
	_pending = ""
	if is_instance_valid(_ordinary): _ordinary.stop()
	if is_instance_valid(_result): _result.stop()

func _exit_tree() -> void:
	_clear()
	# The audio mixer owns playback references until its next mix. Release the
	# players' resource references explicitly before the application tree closes.
	if is_instance_valid(_ordinary): _ordinary.stream = null
	if is_instance_valid(_result): _result.stream = null
	if is_instance_valid(_music):
		_music.stop()
		_music.stream = null

static func play_from(node: Node, cue: String) -> void:
	if cue.is_empty() or not is_instance_valid(node) or not node.is_inside_tree(): return
	var service: Node = node.get_tree().get_first_node_in_group("ui_audio")
	if service != null: service.request(cue)

static func bind_slider(slider: Range) -> void:
	if slider.has_meta("ui_audio_slider_bound"): return
	slider.set_meta("ui_audio_slider_bound", true)
	if slider is Slider:
		slider.set_meta("audio_dragging", false)
		slider.drag_started.connect(func() -> void: slider.set_meta("audio_dragging", true))
		slider.drag_ended.connect(func(changed: bool) -> void:
			slider.set_meta("audio_dragging", false)
			if changed: play_from(slider, "adjust")
		)
	# Native Slider changes happen after gui_input. Compare on the deferred turn,
	# never on value_changed, which also fires during animation and record loading.
	slider.gui_input.connect(func(event: InputEvent) -> void:
		if not event is InputEventKey or not event.pressed: return
		var adjusts := false
		for action in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_home", "ui_end"]:
			if event.is_action_pressed(action, true): adjusts = true
		if not adjusts: return
		var before := slider.value
		_finish_slider_key.call_deferred(weakref(slider), before)
	)

static func _finish_slider_key(reference: WeakRef, before: float) -> void:
	var slider: Range = reference.get_ref() as Range
	if is_instance_valid(slider) and not is_equal_approx(slider.value, before):
		play_from(slider, "adjust")

func _setup_music() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) < 0:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index,MUSIC_BUS)
		AudioServer.set_bus_send(index,&"Master")
	_music = AudioStreamPlayer.new()
	_music.name = "BackgroundMusic"
	_music.bus = MUSIC_BUS
	_music.max_polyphony = 1
	var loop := MUSIC_STREAM.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = roundi(loop.get_length()*loop.mix_rate)
	_music.stream = loop
	_music.volume_db = -80.0
	add_child(_music)
	_sync_music()

func _sync_music() -> void:
	if not is_instance_valid(_music): return
	_duck_remaining = 0.0
	_duck_db = 0.0
	_music_fade = 0.0
	_music.volume_db = -80.0
	if not enabled or not foreground:
		# Pausing preserves the sample position and silences output immediately.
		_music.stream_paused = true
		return
	_music.stream_paused = false
	if not _music.playing: _music.play()

func _process(delta: float) -> void:
	if not enabled or not foreground or not is_instance_valid(_music): return
	_music_fade = minf(1.0,_music_fade+delta/MUSIC_FADE_SECONDS)
	var duck_target := -4.0 if _duck_remaining > 0.0 else 0.0
	_duck_db = move_toward(_duck_db,duck_target,delta*(50.0 if duck_target < _duck_db else 6.67))
	_duck_remaining = maxf(0.0,_duck_remaining-delta)
	_music.volume_db = MUSIC_DB+_duck_db+linear_to_db(maxf(_music_fade,0.0001))
