class_name Lang
extends RefCounted
## 언어 설정. "auto" 는 컴퓨터 언어가 한국어면 한국어, 아니면 영어를 쓴다.

const OPTIONS := ["auto", "ko", "en"]


## 게임을 시작할 때 한 번 호출한다. 영어 번역표를 등록하고 현재 언어를 적용한다.
static func setup() -> void:
	var en := Translation.new()
	en.locale = "en"
	var table: Dictionary = Translations.EN
	for key: String in table:
		en.add_message(key, table[key])
	TranslationServer.add_translation(en)
	apply()


static func resolve() -> String:
	var pref := str(SaveData.settings.get("language", "auto"))
	if pref == "ko" or pref == "en":
		return pref
	return "ko" if OS.get_locale_language() == "ko" else "en"


static func apply() -> void:
	TranslationServer.set_locale(resolve())
