"""번역 누락 검사 도구.

코드(scripts/*.gd)에 적힌 한글 문구를 모두 찾아서, scripts/translations.gd 의 영어 표에 없는 것을 알려 준다.
새 한글 문구를 추가한 뒤에 실행한다.

실행 (프로젝트 폴더에서):
    python tools/check_translations.py
"""
import glob
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HANGUL = re.compile("[가-힣]")
LITERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')

# 번역이 필요 없는 문구 (개발용 출력, 글꼴 이름 등)
SKIP_EXACT = {"맑은 고딕", "승리", "사망", "자동 / Auto", "한국어"}
SKIP_PREFIX = ("[bot]",)


def unescape(s):
    return s.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")


def table_keys():
    text = open(os.path.join(ROOT, "scripts", "translations.gd"), encoding="utf-8").read()
    keys = set()
    for line in text.split("\n"):
        line = line.strip()
        if not line.startswith('"'):
            continue
        m = LITERAL.match(line)
        if m:
            keys.add(unescape(m.group(1)))
    return keys


def code_strings():
    found = {}
    for path in sorted(glob.glob(os.path.join(ROOT, "scripts", "*.gd"))):
        name = os.path.basename(path)
        if name == "translations.gd":
            continue
        for line in open(path, encoding="utf-8").read().split("\n"):
            if line.strip().startswith("#"):
                continue
            for m in LITERAL.finditer(line):
                text = unescape(m.group(1))
                if HANGUL.search(text):
                    found.setdefault(text, name)
    return found


def main():
    keys = table_keys()
    missing = []
    for text, name in code_strings().items():
        if text in keys or text in SKIP_EXACT or text.startswith(SKIP_PREFIX):
            continue
        missing.append((name, text))
    print("번역표 항목: %d개" % len(keys))
    if not missing:
        print("번역이 빠진 문구가 없습니다.")
        return 0
    print("번역이 빠진 문구 %d개:" % len(missing))
    for name, text in missing:
        print("  [%s] %s" % (name, text.replace("\n", "\\n")))
    return 1


if __name__ == "__main__":
    sys.exit(main())
