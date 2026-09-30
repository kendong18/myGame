extends Node
## 저장 데이터 (자동 로드 싱글톤). 골드, 강화 단계, 해금 캐릭터, 최고 기록, 설정을 파일에 저장한다.

const PATH := "user://save.json"

var gold := 0
var upgrades: Dictionary = {}
var unlocked: Array = ["coco", "miyu"]
var best := {"time": 0.0, "kills": 0, "level": 0}
var wins := 0
var runs := 0
var selected_char := "coco"
var cleared: Dictionary = {}     # 스테이지 아이디 -> 최종 보스를 쓰러뜨린 가장 높은 위험도 (기록이 없으면 아직 클리어 전)
var selected_stage := "station"
var risk_tier := 0              # 다음 판에 도전할 위험도
var settings := {
	"sfx": 0.8, "music": 0.5,
	"damage_numbers": true, "screen_shake": true, "fullscreen": false,
	"window_size": 0, "vsync": true, "keys": {}, "language": "auto",
}
# 창 모드일 때 고를 수 있는 창 크기
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

# 자동 테스트(--autoplay) 중에는 실제 저장 파일을 건드리지 않는다
var persist := true

# 화면을 다시 만든 뒤 처음 보여줄 메뉴 화면 (언어를 바꾸면 메뉴를 다시 불러온다)
var pending_screen := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	persist = not ("--autoplay" in OS.get_cmdline_user_args())
	load_data()
	if not persist:
		# 테스트 전용: --gold=1234 로 골드를 임의로 지정 (저장되지 않음)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--gold="):
				gold = int(a.substr(7))
			elif a.begins_with("--lang="):
				settings["language"] = a.substr(7)    # 테스트 전용: ko 또는 en
			elif a.begins_with("--cleared="):
				# 테스트 전용: --cleared=station:0,greenhouse:2 처럼 클리어 기록을 지정
				for entry in a.substr(10).split(","):
					var kv := entry.split(":")
					if kv.size() == 2:
						cleared[kv[0]] = int(kv[1])
	apply_window()
	InputSetup.apply()
	Lang.setup()


func load_data() -> void:
	if not persist or not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return
	apply_dict(parsed)


## 저장 파일에서 읽은 내용을 적용한다 (옛 버전의 저장 파일도 여기서 새 형식으로 바꾼다)
func apply_dict(d: Dictionary) -> void:
	gold = int(d.get("gold", 0))
	upgrades = d.get("upgrades", {})
	unlocked = d.get("unlocked", ["coco", "miyu"])
	wins = int(d.get("wins", 0))
	runs = int(d.get("runs", 0))
	selected_char = str(d.get("selected_char", "coco"))
	var saved_cleared: Variant = d.get("cleared", null)
	if saved_cleared is Dictionary:
		for k: String in saved_cleared:
			if GameData.STAGES.any(func(st: Dictionary) -> bool: return st.id == k):
				cleared[k] = int(saved_cleared[k])
	else:
		# 스테이지가 생기기 전 저장 파일: 예전 위험도 기록은 첫 스테이지의 기록이다
		var old_tier := int(d.get("cleared_tier", -1))
		if not d.has("cleared_tier") and wins > 0:
			old_tier = 0    # 위험도 기능도 없던 시절에 이미 승리한 기록이 있으면 기본 난이도를 클리어한 것으로 본다
		if old_tier >= 0:
			cleared["station"] = old_tier
	selected_stage = str(d.get("selected_stage", "station"))
	if not is_stage_unlocked(selected_stage):
		selected_stage = "station"
	risk_tier = clampi(int(d.get("risk_tier", 0)), 0, max_tier())
	# 예전 버전의 캐릭터 아이디가 남아 있으면 정리
	unlocked = unlocked.filter(func(id: Variant) -> bool: return GameData.is_valid_character(str(id)))
	for base_id in ["coco", "miyu"]:
		if not (base_id in unlocked):
			unlocked.append(base_id)
	if not GameData.is_valid_character(selected_char):
		selected_char = "coco"
	var b: Dictionary = d.get("best", {})
	best = {"time": float(b.get("time", 0.0)), "kills": int(b.get("kills", 0)), "level": int(b.get("level", 0))}
	var s: Dictionary = d.get("settings", {})
	for k: String in settings:
		if s.has(k):
			settings[k] = s[k]


func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"gold": gold, "upgrades": upgrades, "unlocked": unlocked, "best": best,
		"wins": wins, "runs": runs, "selected_char": selected_char, "settings": settings,
		"cleared": cleared, "selected_stage": selected_stage, "risk_tier": risk_tier,
	}, "\t"))


func apply_window() -> void:
	if "--autoplay" in OS.get_cmdline_user_args():
		return
	var full := bool(settings.fullscreen)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if not full:
		var idx := clampi(int(settings.window_size), 0, WINDOW_SIZES.size() - 1)
		var size: Vector2i = WINDOW_SIZES[idx]
		var screen := DisplayServer.screen_get_size()
		# 모니터보다 큰 크기는 쓰지 않는다
		if size.x <= screen.x and size.y <= screen.y and DisplayServer.window_get_size() != size:
			DisplayServer.window_set_size(size)
			DisplayServer.window_set_position((screen - size) / 2)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(settings.vsync) else DisplayServer.VSYNC_DISABLED)


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func buy_upgrade(item: Dictionary) -> bool:
	var lv := upgrade_level(item.id)
	if lv >= int(item.max):
		return false
	var cost := GameData.shop_cost(item, lv)
	if gold < cost:
		return false
	gold -= cost
	upgrades[item.id] = lv + 1
	save()
	return true


## 전체 환불: 쓴 골드를 모두 돌려받고 강화를 초기화
func refund_all() -> int:
	var total := 0
	for item: Dictionary in GameData.SHOP:
		var lv := upgrade_level(item.id)
		for i in lv:
			total += GameData.shop_cost(item, i)
	gold += total
	upgrades.clear()
	save()
	return total


## 그 스테이지에서 클리어한 가장 높은 위험도 (-1 이면 아직 클리어 전)
func cleared_tier_of(stage_id: String) -> int:
	return int(cleared.get(stage_id, -1))


## 지금 고를 수 있는 가장 높은 위험도 (한 단계 위까지 열려 있다). stage_id 를 안 주면 고른 스테이지 기준
func max_tier(stage_id: String = "") -> int:
	var id := selected_stage if stage_id == "" else stage_id
	return mini(GameData.RISK_TIERS.size() - 1, cleared_tier_of(id) + 1)


## 첫 스테이지는 처음부터 열려 있고, 그 다음부터는 바로 앞 스테이지를 한 번 클리어해야 열린다
func is_stage_unlocked(stage_id: String) -> bool:
	var idx := GameData.stage_index(stage_id)
	if GameData.STAGES[idx].id != stage_id:
		return false
	return idx == 0 or cleared_tier_of(str(GameData.STAGES[idx - 1].id)) >= 0


## 어느 스테이지든 클리어한 가장 높은 위험도
func best_cleared_tier() -> int:
	var best_tier := -1
	for k: String in cleared:
		best_tier = maxi(best_tier, int(cleared[k]))
	return best_tier


func is_unlocked(id: String) -> bool:
	return id in unlocked


func unlock_char(ch: Dictionary) -> bool:
	if is_unlocked(ch.id):
		return true
	var cost := int(ch.cost)
	if gold < cost:
		return false
	gold -= cost
	unlocked.append(ch.id)
	save()
	return true


## 한 판 결과 기록. 새 기록이면 true 반환
func record_run(time: float, kills: int, level: int, reward: int, won: bool, tier: int = 0, stage_id: String = "station") -> bool:
	runs += 1
	if won:
		wins += 1
		cleared[stage_id] = maxi(cleared_tier_of(stage_id), tier)
	gold += reward
	var record := time > float(best.time)
	if record:
		best.time = time
	best.kills = maxi(int(best.kills), kills)
	best.level = maxi(int(best.level), level)
	save()
	return record
