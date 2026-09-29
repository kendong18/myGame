class_name T
extends RefCounted
## 번역 도우미. 한국어 문구를 원문으로 쓰고, 영어일 때는 표(translations.gd)에서 찾아 바꾼다.
## 표에 없는 문구는 그대로(한국어) 나온다.

## 문구 하나를 현재 언어로 바꾼다
static func t(msg: String) -> String:
	return String(TranslationServer.translate(msg))


## %d, %s 같은 자리가 있는 문구를 번역한 뒤 값을 채운다
static func f(msg: String, args: Array) -> String:
	return String(TranslationServer.translate(msg)) % args
