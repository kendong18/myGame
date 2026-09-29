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
var settings := {
	"sfx": 0.8, "music": 0.5,
	"damage_numbers": true, "screen_shake": true, "fullscreen": false,
}

# 자동 테스트(--autoplay) 중에는 실제 저장 파일을 건드리지 않는다
var persist := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	persist = not ("--autoplay" in OS.get_cmdline_user_args())
	load_data()
	if not persist:
		# 테스트 전용: --gold=1234 로 골드를 임의로 지정 (저장되지 않음)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--gold="):
				gold = int(a.substr(7))
	apply_window()


func load_data() -> void:
	if not persist or not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return
	var d: Dictionary = parsed
	gold = int(d.get("gold", 0))
	upgrades = d.get("upgrades", {})
	unlocked = d.get("unlocked", ["coco", "miyu"])
	wins = int(d.get("wins", 0))
	runs = int(d.get("runs", 0))
	selected_char = str(d.get("selected_char", "coco"))
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
	}, "\t"))


func apply_window() -> void:
	if "--autoplay" in OS.get_cmdline_user_args():
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


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
func record_run(time: float, kills: int, level: int, reward: int, won: bool) -> bool:
	runs += 1
	if won:
		wins += 1
	gold += reward
	var record := time > float(best.time)
	if record:
		best.time = time
	best.kills = maxi(int(best.kills), kills)
	best.level = maxi(int(best.level), level)
	save()
	return record
