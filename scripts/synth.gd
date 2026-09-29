class_name Synth
extends RefCounted
## 외부 파일 없이 효과음과 배경음악을 코드로 합성한다. (칩튠 스타일)

const RATE := 22050


static func wave(kind: String, phase: float) -> float:
	var p := phase - floorf(phase)
	match kind:
		"square":
			return 1.0 if p < 0.5 else -1.0
		"pulse":
			return 1.0 if p < 0.25 else -1.0
		"tri":
			return 4.0 * absf(p - 0.5) - 1.0
		"saw":
			return 2.0 * p - 1.0
		_:
			return sin(p * TAU)


static func new_buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## 음 하나를 buf 의 start(초) 위치에 더한다. slide 는 끝날 때까지 변하는 주파수 변화량(Hz)
static func add_tone(buf: PackedFloat32Array, start: float, dur: float, freq: float, kind: String, vol: float, slide: float = 0.0, attack: float = 0.004, decay: float = 2.5) -> void:
	var n := int(dur * RATE)
	var s0 := int(start * RATE)
	var phase := 0.0
	var size := buf.size()
	for i in n:
		if s0 + i >= size:
			break
		var u := float(i) / float(n)
		phase += (freq + slide * u) / RATE
		var env := minf(1.0, float(i) / (attack * RATE)) * pow(1.0 - u, decay)
		buf[s0 + i] += wave(kind, phase) * vol * env


## 잡음. alpha 가 작을수록 낮은 소리(저역 통과), highpass 면 날카로운 소리
static func add_noise(buf: PackedFloat32Array, start: float, dur: float, vol: float, alpha: float, highpass: bool = false, decay: float = 2.0) -> void:
	var n := int(dur * RATE)
	var s0 := int(start * RATE)
	var y := 0.0
	var size := buf.size()
	for i in n:
		if s0 + i >= size:
			break
		var x := randf() * 2.0 - 1.0
		y += alpha * (x - y)
		var v := (x - y) if highpass else y
		var u := float(i) / float(n)
		buf[s0 + i] += v * vol * pow(1.0 - u, decay)


static func to_stream(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = buf.size()
	return s


static func midi(n: int) -> float:
	return 440.0 * pow(2.0, (float(n) - 69.0) / 12.0)


static func arpeggio(buf: PackedFloat32Array, notes: Array, step: float, dur: float, kind: String, vol: float) -> void:
	for i in notes.size():
		add_tone(buf, step * i, dur, float(notes[i]), kind, vol)


# ─────────────────────────────────────────────
# 효과음
# ─────────────────────────────────────────────
static func build_sfx() -> Dictionary:
	var out := {}
	var b: PackedFloat32Array

	b = new_buf(0.10)
	add_noise(b, 0.0, 0.08, 0.5, 0.45, false, 2.5)
	add_tone(b, 0.0, 0.07, 190.0, "sine", 0.45, -90.0)
	out["hit"] = to_stream(b)

	b = new_buf(0.14)
	add_tone(b, 0.0, 0.12, 220.0, "square", 0.28, -140.0)
	add_noise(b, 0.0, 0.10, 0.25, 0.3, false, 2.0)
	out["kill"] = to_stream(b)

	b = new_buf(0.10)
	add_tone(b, 0.0, 0.08, 800.0, "tri", 0.35, 350.0)
	out["shoot"] = to_stream(b)

	b = new_buf(0.18)
	add_noise(b, 0.0, 0.15, 1.6, 0.85, true, 1.5)
	out["whip"] = to_stream(b)

	b = new_buf(0.10)
	add_tone(b, 0.0, 0.09, 1300.0, "sine", 0.45, 450.0)
	out["gem"] = to_stream(b)

	b = new_buf(0.22)
	add_tone(b, 0.0, 0.07, 1320.0, "square", 0.25)
	add_tone(b, 0.06, 0.14, 1760.0, "square", 0.25)
	out["coin"] = to_stream(b)

	b = new_buf(0.26)
	add_tone(b, 0.0, 0.22, 170.0, "saw", 0.45, -100.0)
	add_noise(b, 0.0, 0.12, 0.3, 0.4)
	out["hurt"] = to_stream(b)

	b = new_buf(0.5)
	arpeggio(b, [523.0, 659.0, 784.0, 1047.0], 0.07, 0.2, "square", 0.3)
	out["levelup"] = to_stream(b)

	b = new_buf(0.22)
	add_tone(b, 0.0, 0.08, 880.0, "tri", 0.4)
	add_tone(b, 0.05, 0.14, 1320.0, "tri", 0.35)
	out["select"] = to_stream(b)

	b = new_buf(0.08)
	add_tone(b, 0.0, 0.06, 600.0, "tri", 0.35)
	out["click"] = to_stream(b)

	b = new_buf(0.9)
	arpeggio(b, [392.0, 523.0, 659.0, 784.0, 1047.0, 1319.0], 0.09, 0.3, "square", 0.28)
	out["chest"] = to_stream(b)

	b = new_buf(0.45)
	add_noise(b, 0.0, 0.4, 0.8, 0.10, false, 1.5)
	add_tone(b, 0.0, 0.3, 95.0, "saw", 0.35, -45.0)
	out["thunder"] = to_stream(b)

	b = new_buf(0.7)
	add_noise(b, 0.0, 0.65, 0.9, 0.06, false, 1.6)
	add_tone(b, 0.0, 0.5, 75.0, "sine", 0.8, -45.0)
	out["boom"] = to_stream(b)

	b = new_buf(0.35)
	add_tone(b, 0.0, 0.11, 660.0, "sine", 0.4)
	add_tone(b, 0.08, 0.22, 990.0, "sine", 0.4)
	out["heal"] = to_stream(b)

	b = new_buf(1.3)
	for i in 3:
		add_tone(b, 0.38 * i, 0.3, 440.0, "saw", 0.3, -200.0)
	out["warning"] = to_stream(b)

	b = new_buf(1.3)
	add_tone(b, 0.0, 1.2, 300.0, "saw", 0.4, -260.0, 0.01, 1.5)
	add_noise(b, 0.0, 0.8, 0.3, 0.3)
	out["death"] = to_stream(b)

	b = new_buf(1.3)
	arpeggio(b, [523.0, 659.0, 784.0, 1047.0, 784.0, 1047.0, 1319.0], 0.14, 0.4, "square", 0.28)
	out["victory"] = to_stream(b)

	b = new_buf(0.16)
	add_tone(b, 0.0, 0.13, 300.0, "tri", 0.3, 220.0)
	out["eshot"] = to_stream(b)

	b = new_buf(0.22)
	add_tone(b, 0.0, 0.14, 1500.0, "tri", 0.4, -1000.0)
	add_tone(b, 0.0, 0.09, 2300.0, "square", 0.12, -1600.0)
	add_noise(b, 0.0, 0.1, 0.35, 0.8, true, 2.0)
	out["react"] = to_stream(b)

	b = new_buf(0.5)
	add_tone(b, 0.0, 0.4, 330.0, "tri", 0.4, 330.0)
	add_tone(b, 0.1, 0.35, 495.0, "tri", 0.3, 300.0)
	out["evolve"] = to_stream(b)

	return out


# ─────────────────────────────────────────────
# 배경음악
# ─────────────────────────────────────────────
## 16분음표 64칸(4마디)짜리 반복곡을 만든다.
## chords: 마디별 코드 음(MIDI 번호) 4개 / lead: 64칸 멜로디(0이면 쉼)
static func _make_track(bpm: float, chords: Array, lead: Array, lead_kind: String, drums: bool, bass_vol: float, lead_vol: float) -> AudioStreamWAV:
	var step := 60.0 / bpm / 4.0
	var b := new_buf(step * 64.0)
	for s in 64:
		var t := s * step
		var chord: Array = chords[s / 16]
		var root: int = chord[0]
		if s % 4 == 0 or s % 16 == 14:
			add_tone(b, t, step * 3.0, midi(root - 24), "square", bass_vol, 0.0, 0.005, 1.8)
		if s % 2 == 0:
			add_tone(b, t, step * 1.8, midi(int(chord[(s / 2) % 3]) + 12), "tri", 0.10, 0.0, 0.004, 2.0)
		var note: int = lead[s]
		if note > 0:
			add_tone(b, t, step * 3.0, midi(note), lead_kind, lead_vol, 0.0, 0.006, 1.6)
		if drums:
			if s % 4 == 2:
				add_noise(b, t, 0.05, 0.10, 0.85, true, 2.0)
			if s % 8 == 0:
				add_tone(b, t, 0.13, 130.0, "sine", 0.45, -80.0, 0.002, 2.0)
	return to_stream(b, true)


static func build_music() -> Dictionary:
	var tracks := {}
	# 게임: 경쾌한 C장조 (C Am F G)
	tracks["game"] = _make_track(138.0, [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]], [
		76, 0, 79, 0, 76, 0, 74, 0, 72, 0, 74, 76, 0, 0, 0, 0,
		81, 0, 79, 0, 76, 0, 79, 0, 76, 0, 74, 0, 72, 0, 0, 0,
		72, 0, 76, 0, 79, 0, 76, 0, 74, 0, 72, 0, 69, 0, 72, 0,
		74, 0, 79, 0, 83, 0, 79, 0, 74, 0, 71, 0, 74, 0, 0, 0,
	], "pulse", true, 0.16, 0.07)
	# 보스: 더 빠르고 어두운 D단조 (Dm Bb C A)
	tracks["boss"] = _make_track(168.0, [[50, 53, 57], [46, 50, 53], [48, 52, 55], [45, 49, 52]], [
		74, 74, 0, 77, 0, 74, 0, 72, 74, 0, 77, 0, 81, 0, 79, 77,
		70, 70, 0, 74, 0, 70, 0, 69, 70, 0, 74, 0, 77, 0, 74, 70,
		72, 72, 0, 76, 0, 72, 0, 71, 72, 0, 76, 0, 79, 0, 76, 72,
		69, 0, 73, 0, 76, 0, 73, 0, 81, 0, 79, 0, 76, 0, 73, 0,
	], "saw", true, 0.18, 0.05)
	# 메뉴: 느리고 몽글몽글한 곡 (드럼 없음)
	tracks["menu"] = _make_track(84.0, [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]], [
		0, 0, 0, 0, 79, 0, 0, 0, 0, 0, 0, 0, 76, 0, 0, 0,
		0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 0, 79, 0, 0, 0,
		0, 0, 0, 0, 77, 0, 0, 0, 0, 0, 0, 0, 76, 0, 74, 0,
		0, 0, 0, 0, 74, 0, 0, 0, 0, 0, 71, 0, 67, 0, 0, 0,
	], "tri", false, 0.12, 0.16)
	return tracks
