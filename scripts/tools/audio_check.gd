extends Node
## Dev QA: print loudness/clip stats for each synthesized music track, so audio can be
## sanity-checked headless (we can't hear it). Run: godot --headless scenes/tools/audio_check.tscn

func _ready() -> void:
	for name in ["menu", "combat", "combat2", "elite", "boss"]:
		var st: AudioStreamWAV = Audio._tracks.get(name)
		if st == null:
			print("%s: MISSING" % name)
			continue
		var data: PackedByteArray = st.data
		var n: int = data.size() / 2
		var peak := 0
		var clip := 0
		var nonzero := 0
		var sumsq := 0.0
		for i in n:
			var s := data.decode_s16(i * 2)
			var a: int = abs(s)
			if a > peak:
				peak = a
			if a >= 32767:
				clip += 1
			if s != 0:
				nonzero += 1
			sumsq += float(s) * float(s)
		var rms := sqrt(sumsq / max(1, n)) / 32768.0
		print("%-8s dur=%4.1fs  peak=%.2f  rms=%.3f  clip=%4.1f%%  nonzero=%3.0f%%" % [
			name, n / float(Audio.RATE), peak / 32768.0, rms, 100.0 * clip / max(1, n), 100.0 * nonzero / max(1, n)])
	get_tree().quit()
