extends Node
## Procedural audio — all SFX and the music loop are synthesized in code at boot
## (no asset files). Call Audio.play("hit") etc; music loops via play_music().

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _sfx := {}
var muted := false

func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -17.0
	add_child(_music)
	_build_sfx()
	_build_music()

func play(name: String, vol_db := -7.0) -> void:
	if muted:
		return
	var s = _sfx.get(name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.volume_db = vol_db
	p.play()

func play_music() -> void:
	if not muted and _music.stream != null and not _music.playing:
		_music.play()

func stop_music() -> void:
	_music.stop()

func set_muted(m: bool) -> void:
	muted = m
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

func _build_music() -> void:
	var beat := 60.0 / 112.0
	var eighth := beat / 2.0
	var prog := [261.63, 220.0, 174.61, 196.0]   # C  Am  F  G
	var samples := PackedFloat32Array()
	for root in prog:
		var notes := [root, root * 1.25, root * 1.5, root * 2.0, root * 1.5, root * 1.25, root * 1.5, root * 2.0]
		for nf in notes:
			var lead := _tone(nf, eighth, "square", 0.16, true)
			var bass := _tone(root * 0.5, eighth, "saw", 0.1, false)
			samples.append_array(_mix(lead, bass))
	_music.stream = _wav(samples, true)
