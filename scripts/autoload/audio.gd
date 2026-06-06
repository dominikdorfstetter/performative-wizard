extends Node
## Procedural audio — all SFX and the music loop are synthesized in code at boot
## (no asset files). Call Audio.play("hit") etc; music loops via play_music().

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
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
	_music.volume_db = -17.0
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
	p.volume_db = vol_db
	p.play()

## Switch to a named track (menu/combat/combat2/elite/boss). Re-calling with the
## track that's already playing is a no-op, so scenes can call it freely.
func play_music(track := "") -> void:
	if track == "":
		track = _current_track
	if music_muted:
		_current_track = track   # remember it for unmute
		return
	var s = _tracks.get(track)
	if s == null:
		return
	if _current_track == track and _music.playing:
		return
	_current_track = track
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

# Each track: a 4-chord arpeggio loop with bass and (optional) drums. Distinct
# progression / tempo / waveform / arp give every context its own mood.
const TRACK_DEFS := {
	"menu":    {"prog": [261.63, 220.0, 174.61, 196.0], "bpm": 96.0,  "lead": "sine",     "lvol": 0.13, "bass": "triangle", "bmult": 0.5, "drum": 0.0, "arp": [1.0, 1.5, 2.0, 1.5, 1.25, 1.5, 2.0, 3.0]},
	"combat":  {"prog": [261.63, 220.0, 174.61, 196.0], "bpm": 112.0, "lead": "square",   "lvol": 0.15, "bass": "saw",      "bmult": 0.5, "drum": 0.5, "arp": [1.0, 1.25, 1.5, 2.0, 1.5, 1.25, 1.5, 2.0]},
	"combat2": {"prog": [220.0, 174.61, 196.0, 261.63], "bpm": 120.0, "lead": "triangle", "lvol": 0.16, "bass": "saw",      "bmult": 0.5, "drum": 0.5, "arp": [2.0, 1.5, 1.25, 1.5, 2.0, 1.25, 1.0, 1.5]},
	"elite":   {"prog": [246.94, 196.0, 164.81, 220.0], "bpm": 128.0, "lead": "square",   "lvol": 0.15, "bass": "saw",      "bmult": 0.5, "drum": 0.62, "arp": [1.0, 1.5, 1.25, 2.0, 1.5, 2.0, 1.25, 1.5]},
	"boss":    {"prog": [164.81, 130.81, 196.0, 146.83], "bpm": 132.0, "lead": "square",  "lvol": 0.17, "bass": "saw",      "bmult": 1.0, "drum": 0.72, "arp": [1.0, 2.0, 1.5, 2.0, 3.0, 2.0, 1.5, 2.0]},
}

func _build_tracks() -> void:
	for name in TRACK_DEFS:
		_tracks[name] = _build_track(TRACK_DEFS[name])

func _build_track(d: Dictionary) -> AudioStreamWAV:
	var eighth: float = (60.0 / float(d.bpm)) / 2.0
	var arp: Array = d.arp
	var samples := PackedFloat32Array()
	for root in d.prog:
		var bar := PackedFloat32Array()
		for k in arp:
			var lead := _tone(float(root) * float(k), eighth, d.lead, d.lvol, true)
			var bass := _tone(float(root) * float(d.bmult), eighth, d.bass, 0.1, false)
			bar.append_array(_mix(lead, bass))
		if float(d.drum) > 0.0:
			bar = _mix(bar, _drum_bar(eighth, float(d.drum)))
		samples.append_array(bar)
	return _wav(samples, true)

# One bar of drums: kick on beats 1 & 3, snare on 2 & 4, closed hat on offbeats.
func _drum_bar(eighth: float, vol: float) -> PackedFloat32Array:
	var step_n := int(eighth * RATE)
	var bar := PackedFloat32Array()
	bar.resize(step_n * 8)
	var kick := _glide(150.0, 48.0, min(0.16, eighth * 1.6), "sine", 0.95)
	var snare := _mix(_tone(0.0, 0.13, "noise", 0.5), _tone(190.0, 0.13, "triangle", 0.3))
	var hat := _tone(0.0, 0.035, "noise", 0.28)
	_overlay(bar, kick, [0, 4], step_n, vol)
	_overlay(bar, snare, [2, 6], step_n, vol)
	_overlay(bar, hat, [1, 3, 5, 7], step_n, vol * 0.6)
	return bar

func _overlay(into: PackedFloat32Array, hit: PackedFloat32Array, steps: Array, step_n: int, vol: float) -> void:
	for s in steps:
		var off: int = s * step_n
		for i in hit.size():
			var idx: int = off + i
			if idx < into.size():
				into[idx] = clampf(into[idx] + hit[i] * vol, -1.0, 1.0)
