extends Node
## Procedural audio — all SFX and the music loop are synthesized in code at boot
## (no asset files). Call Audio.play("hit") etc; music loops via play_music().

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
const MUSIC_DB := -17.0
var _music: AudioStreamPlayer
var _music_tw: Tween
var _music_off_db := 0.0
var _sfx_off_db := 0.0

func set_music_volume(v: float) -> void:
	_music_off_db = linear_to_db(maxf(v, 0.01))
	if _music != null and (_music_tw == null or not _music_tw.is_valid()):
		_music.volume_db = MUSIC_DB + _music_off_db

func set_sfx_volume(v: float) -> void:
	_sfx_off_db = linear_to_db(maxf(v, 0.01))
var _sfx := {}
var _tracks := {}
var _current_track := "menu"
var sfx_muted := false
var music_muted := false

func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	_build_sfx()
	_build_tracks()

func play(name: String, vol_db := -7.0) -> void:
	if sfx_muted:
		return
	var s = _sfx.get(name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.volume_db = vol_db + _sfx_off_db
	p.play()

## Per-act variation (critic review item 6): acts 2/3 transpose the in-run tracks
## up 2/4 semitones and push the tempo +6/+12 BPM, so a 45-minute run never loops
## one identical bar set. Variants build lazily on first request (masked by the
## scene fade) and cache for the session.
const ACT_PITCH := {2: 1.1225, 3: 1.2599}
const ACT_BPM := {2: 6.0, 3: 12.0}

func _variant_key(track: String, act: int) -> String:
	var a: int = clampi(act, 1, 3)
	if a <= 1 or track == "menu" or "@" in track or not TRACK_DEFS.has(track):
		return track
	var key := "%s@%d" % [track, a]
	if not _tracks.has(key):
		var d: Dictionary = TRACK_DEFS[track].duplicate(true)
		d["bpm"] = float(d.bpm) + float(ACT_BPM[a])
		var prog: Array = []
		for f in d.prog:
			prog.append(float(f) * float(ACT_PITCH[a]))
		d["prog"] = prog
		_tracks[key] = _build_track(d)
	return key

## Switch to a named track (menu/combat/combat2/elite/boss). Re-calling with the
## track that's already playing is a no-op, so scenes can call it freely.
func play_music(track := "", act := 1) -> void:
	if track == "":
		track = _current_track
	track = _variant_key(track, act)
	if music_muted:
		_current_track = track   # remember it for unmute
		return
	var s = _tracks.get(track)
	if s == null:
		return
	if _current_track == track and _music.playing:
		return
	_current_track = track
	if _music.playing:
		# crossfade: dip, swap streams, swell back — no more mid-bar hard cuts
		if _music_tw != null and _music_tw.is_valid():
			_music_tw.kill()
		_music_tw = create_tween()
		_music_tw.tween_property(_music, "volume_db", -50.0, 0.25)
		_music_tw.tween_callback(func():
			_music.stream = s
			_music.play())
		_music_tw.tween_property(_music, "volume_db", MUSIC_DB + _music_off_db, 0.35)
	else:
		_music.volume_db = MUSIC_DB + _music_off_db
		_music.stream = s
		_music.play()

func stop_music() -> void:
	_music.stop()

func set_sfx_muted(m: bool) -> void:
	sfx_muted = m

func set_music_muted(m: bool) -> void:
	music_muted = m
	if m:
		_music.stop()
	else:
		play_music()

# --- synthesis -----------------------------------------------------------

func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clamp(samples[i], -1.0, 1.0) * 32767.0))
	st.data = bytes
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = samples.size()
	return st

func _tone(freq: float, dur: float, wave: String, vol: float, decay := true) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := i / float(RATE)
		var ph := fmod(freq * t, 1.0)
		var s := 0.0
		match wave:
			"sine":
				s = sin(ph * TAU)
			"square":
				s = 1.0 if ph < 0.5 else -1.0
			"saw":
				s = ph * 2.0 - 1.0
			"triangle":
				s = 2.0 * absf(2.0 * ph - 1.0) - 1.0
			"noise":
				s = randf() * 2.0 - 1.0
		var env := 1.0
		if decay:
			env = 1.0 - i / float(n)
		out[i] = s * vol * env
	return out

func _glide(f0: float, f1: float, dur: float, wave: String, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var k := i / float(n)
		var f: float = lerp(f0, f1, k)
		phase = fmod(phase + f / RATE, 1.0)
		var s := 1.0 if phase < 0.5 else -1.0
		if wave == "sine":
			s = sin(phase * TAU)
		out[i] = s * vol * (1.0 - k)
	return out

func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = max(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var v := 0.0
		if i < a.size():
			v += a[i]
		if i < b.size():
			v += b[i]
		out[i] = v
	return out

func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out

func _build_sfx() -> void:
	_sfx["card"] = _wav(_tone(720, 0.07, "sine", 0.5))
	_sfx["click"] = _wav(_tone(900, 0.04, "sine", 0.4))
	_sfx["hit"] = _wav(_mix(_tone(140, 0.1, "square", 0.35), _tone(0, 0.1, "noise", 0.3)))
	_sfx["crit"] = _wav(_cat([_tone(660, 0.07, "square", 0.4), _tone(990, 0.09, "square", 0.4), _tone(1320, 0.12, "square", 0.4)]))
	_sfx["block"] = _wav(_tone(190, 0.11, "square", 0.4))
	_sfx["hurt"] = _wav(_mix(_tone(95, 0.16, "saw", 0.35), _tone(0, 0.12, "noise", 0.3)))
	_sfx["death"] = _wav(_glide(420, 70, 0.32, "square", 0.4))
	_sfx["aura"] = _wav(_tone(1280, 0.12, "sine", 0.32))
	_sfx["win"] = _wav(_cat([_tone(523, 0.1, "square", 0.4), _tone(659, 0.1, "square", 0.4), _tone(784, 0.1, "square", 0.4), _tone(1047, 0.2, "square", 0.4)]))
	_sfx["lose"] = _wav(_cat([_tone(392, 0.13, "saw", 0.4), _tone(311, 0.13, "saw", 0.4), _tone(196, 0.26, "saw", 0.4)]))
	_sfx["heal"] = _wav(_cat([_tone(660, 0.08, "sine", 0.3), _tone(880, 0.11, "sine", 0.32)]))
	_sfx["summon"] = _wav(_mix(_glide(170, 430, 0.22, "square", 0.3), _tone(0, 0.12, "noise", 0.12)))
	_sfx["coin"] = _wav(_cat([_tone(1175, 0.045, "square", 0.32), _tone(1568, 0.08, "square", 0.32)]))
	_sfx["buff"] = _wav(_cat([_tone(523, 0.06, "square", 0.3), _tone(784, 0.06, "square", 0.3), _tone(1047, 0.1, "square", 0.32)]))
	_sfx["debuff"] = _wav(_glide(470, 150, 0.2, "saw", 0.3))
	# crowd pop for the finisher cash-out: a rising fanfare over a cheer/noise wash
	_sfx["crowd"] = _wav(_mix(
		_cat([_tone(523, 0.09, "square", 0.34), _tone(784, 0.09, "square", 0.36), _tone(1047, 0.18, "square", 0.4)]),
		_glide(300, 900, 0.36, "noise", 0.22)))

# Trap-flavoured tracks: a dark 4-chord arp over a gliding 808 sub, with a half-time
# snare on beat 3 and rolling hi-hats. `aggr` (0..1) is the intensity dial — the harder
# the context, the more layers stack on (16th hats, roll fills, extra 808s, clap+ghost
# snares). Tempos sit in trap territory and climb with difficulty.
const TRACK_DEFS := {
	"menu":    {"prog": [261.63, 220.0, 174.61, 196.0], "bpm": 124.0, "lead": "sine",     "lvol": 0.12, "arp": [1.0, 1.5, 2.0, 1.5, 1.25, 1.5, 2.0, 3.0], "aggr": 0.18},
	"combat":  {"prog": [261.63, 220.0, 174.61, 196.0], "bpm": 130.0, "lead": "square",   "lvol": 0.14, "arp": [1.0, 1.25, 1.5, 2.0, 1.5, 1.25, 1.5, 2.0], "aggr": 0.42},
	"combat2": {"prog": [220.0, 174.61, 196.0, 261.63], "bpm": 136.0, "lead": "triangle", "lvol": 0.15, "arp": [2.0, 1.5, 1.25, 1.5, 2.0, 1.25, 1.0, 1.5], "aggr": 0.58},
	"elite":   {"prog": [246.94, 196.0, 164.81, 220.0], "bpm": 142.0, "lead": "square",   "lvol": 0.15, "arp": [1.0, 1.5, 1.25, 2.0, 1.5, 2.0, 1.25, 1.5], "aggr": 0.80},
	"boss":    {"prog": [164.81, 130.81, 196.0, 146.83], "bpm": 150.0, "lead": "square",  "lvol": 0.16, "arp": [1.0, 2.0, 1.5, 2.0, 3.0, 2.0, 1.5, 2.0], "aggr": 1.0},
}

func _build_tracks() -> void:
	for name in TRACK_DEFS:
		_tracks[name] = _build_track(TRACK_DEFS[name])

func _build_track(d: Dictionary) -> AudioStreamWAV:
	var beat: float = 60.0 / float(d.bpm)
	var bar_dur: float = beat * 4.0          # one 4/4 bar
	var eighth: float = beat / 2.0
	var arp: Array = d.arp
	var aggr: float = float(d.get("aggr", 0.0))
	var samples := PackedFloat32Array()
	for root in d.prog:
		var bar := PackedFloat32Array()
		bar.resize(int(bar_dur * RATE))
		# melodic arp across the bar (8 eighths)
		var melody := PackedFloat32Array()
		for k in arp:
			melody.append_array(_tone(float(root) * float(k), eighth, d.lead, d.lvol, true))
		_add(bar, melody, 0)
		# 808 sub-bass: root an octave down, gliding, ringing most of the bar
		_add(bar, _eight_o_eight(float(root) * 0.5, bar_dur * 0.9, 0.40), 0)
		if aggr >= 0.6:                       # a second 808 punch late in the bar
			_add(bar, _eight_o_eight(float(root) * 0.5, bar_dur * 0.4, 0.34), int(bar_dur * 0.625 * RATE))
		if aggr > 0.0:
			_add(bar, _trap_drums(bar_dur, aggr), 0)
		samples.append_array(bar)
	return _wav(samples, true)

# A trap drum bar (16-step grid): 808 kicks, a half-time snare/clap on beat 3, and
# rolling hi-hats. Layers stack with `aggr`.
func _trap_drums(bar_dur: float, aggr: float) -> PackedFloat32Array:
	var n := int(bar_dur * RATE)
	var bar := PackedFloat32Array()
	bar.resize(n)
	var sn := int((bar_dur / 16.0) * RATE)   # one sixteenth, in samples
	var kick := _glide(150.0, 46.0, min(0.18, bar_dur * 0.12), "sine", 0.9)
	var snare := _mix(_tone(0.0, 0.14, "noise", 0.5), _tone(185.0, 0.14, "triangle", 0.28))
	var clap := _tone(0.0, 0.10, "noise", 0.45)
	var hat := _tone(0.0, 0.028, "noise", 0.22)
	var ohat := _tone(0.0, 0.06, "noise", 0.20)
	# 808 kicks — syncopated, denser when angrier
	var kicks := [0, 10]
	if aggr >= 0.5:
		kicks.append(6)
	if aggr >= 0.8:
		kicks.append_array([3, 13])
	_overlay(bar, kick, kicks, sn, 0.78)
	# half-time backbeat: snare on beat 3 (step 8), with a clap stack + ghost snare when angry
	_overlay(bar, snare, [8], sn, 0.72)
	if aggr >= 0.6:
		_overlay(bar, clap, [8], sn, 0.55)
	if aggr >= 0.85:
		_overlay(bar, snare, [14], sn, 0.4)
	# hi-hats: eighths, upgrading to sixteenths, with accents
	var hats: Array = [0, 2, 4, 6, 8, 10, 12, 14]
	if aggr >= 0.4:
		hats = range(16)
	var hv: float = 0.38 + 0.3 * aggr
	for s in hats:
		_overlay(bar, hat, [s], sn, hv * (0.65 if int(s) % 2 == 1 else 1.0))
	if aggr >= 0.5:
		_overlay(bar, ohat, [15], sn, 0.5)   # open-hat lift into the next bar
	# the trap signature: hat rolls (sub-step bursts)
	if aggr >= 0.7:
		_roll(bar, hat, 12, 16, sn, 6, 0.5)
	if aggr >= 0.95:
		_roll(bar, hat, 4, 6, sn, 6, 0.45)
	return bar

# A gliding 808 sub: pitch slides down into the note, soft-saturated, long decay tail.
func _eight_o_eight(freq: float, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var glide_n: int = max(1, int(0.05 * RATE))   # 50 ms slide
	var atk: float = 0.005 * RATE
	var phase := 0.0
	for i in n:
		var f := freq
		if i < glide_n:
			f = lerp(freq * 1.7, freq, i / float(glide_n))
		phase = fmod(phase + f / RATE, 1.0)
		var s := tanh(sin(phase * TAU) * 1.5)     # warm sub saturation
		var env := 1.0
		if i < atk:
			env = i / atk
		else:
			env = pow(1.0 - (i - atk) / float(n - atk), 0.5)
		out[i] = s * vol * env
	return out

# Place `count` evenly-spaced hits across [start_step, end_step) — a hat/snare roll.
func _roll(into: PackedFloat32Array, hit: PackedFloat32Array, start_step: int, end_step: int, step_n: int, count: int, vol: float) -> void:
	var a := start_step * step_n
	var b := end_step * step_n
	for j in count:
		_add(into, hit, a + int((b - a) * j / float(count)), vol)

# Mix `src` into `into` starting at sample `offset`, scaled by `vol`, clamped.
func _add(into: PackedFloat32Array, src: PackedFloat32Array, offset: int, vol := 1.0) -> void:
	for i in src.size():
		var idx: int = offset + i
		if idx >= 0 and idx < into.size():
			into[idx] = clampf(into[idx] + src[i] * vol, -1.0, 1.0)

func _overlay(into: PackedFloat32Array, hit: PackedFloat32Array, steps: Array, step_n: int, vol: float) -> void:
	for s in steps:
		var off: int = s * step_n
		for i in hit.size():
			var idx: int = off + i
			if idx < into.size():
				into[idx] = clampf(into[idx] + hit[i] * vol, -1.0, 1.0)
