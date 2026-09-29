extends Node
## 사운드 관리 (자동 로드 싱글톤). 효과음은 여러 개를 동시에 재생하고, 음악은 한 곡만 반복한다.

const POOL_SIZE := 16
# 같은 소리가 너무 자주 겹치지 않도록 하는 최소 간격(밀리초)
const THROTTLE := {
	"hit": 45, "kill": 55, "shoot": 60, "whip": 70, "gem": 30, "coin": 50,
	"hurt": 120, "thunder": 80, "eshot": 100,
}
# 소리별 기본 음량(dB)
const GAIN := {"hit": -6.0, "kill": -6.0, "shoot": -8.0, "gem": -8.0, "eshot": -10.0, "whip": -6.0}

var _sfx: Dictionary = {}
var _tracks: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last: Dictionary = {}
var _music: AudioStreamPlayer
var _current := ""
var _wanted := ""
var _task_id := -1
var enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_sfx = Synth.build_sfx()
	# 음악은 합성에 1초 가까이 걸리므로 별도 스레드에서 만든다
	_task_id = WorkerThreadPool.add_task(_build_music_async)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -6.0
	add_child(_music)
	apply_settings()


func _build_music_async() -> void:
	var tracks := Synth.build_music()
	_on_music_ready.call_deferred(tracks)


func _exit_tree() -> void:
	# 종료 시 음악 합성 스레드가 남아 있으면 끝날 때까지 기다린다
	if _task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1


func _on_music_ready(tracks: Dictionary) -> void:
	if not is_inside_tree():
		return
	_tracks = tracks
	if _task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
	if _wanted != "":
		var t := _wanted
		_current = ""
		play_music(t)


func _setup_buses() -> void:
	for bus_name in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func apply_settings() -> void:
	_set_bus("SFX", float(SaveData.settings.sfx))
	_set_bus("Music", float(SaveData.settings.music))


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func play(sound: String, pitch_var: float = 0.0) -> void:
	if not enabled or not _sfx.has(sound):
		return
	var gap: int = THROTTLE.get(sound, 0)
	if gap > 0:
		var now := Time.get_ticks_msec()
		if _last.has(sound) and now - int(_last[sound]) < gap:
			return
		_last[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _sfx[sound]
	p.volume_db = GAIN.get(sound, -4.0)
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func play_music(track: String) -> void:
	_wanted = track
	if track == _current and _music.playing:
		return
	_current = track
	if not _tracks.has(track):
		_music.stop()    # 아직 만드는 중이면 완료 후 자동으로 재생됨
		return
	_music.stream = _tracks[track]
	_music.play()


func stop_music() -> void:
	_current = ""
	_wanted = ""
	_music.stop()
