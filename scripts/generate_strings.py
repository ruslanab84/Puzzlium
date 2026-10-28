#!/usr/bin/env python3
"""Single source of truth for UI strings.

Generates, per module:
  - a typed Swift accessor file (L10n / CatalogStrings)
  - Localizable.xcstrings (String Catalog) with every supported language

Usage:  python3 scripts/generate_strings.py
Add a language: append its code to LANGUAGES and a column to each row.
Params are integers (%lld); multiple params use positional specifiers (%1$lld, %2$lld).
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KIT = ROOT / "Packages" / "PuzzliumKit" / "Sources"
LANGUAGES = ["en", "ru"]

# key, english, russian, [param names]
FEATURES = [
    ("tab.today", "Today", "Сегодня", []),
    ("tab.library", "Library", "Библиотека", []),
    ("tab.myPuzzles", "My puzzles", "Мои пазлы", []),

    ("common.retry", "Try again", "Повторить", []),
    ("common.close", "Close", "Закрыть", []),
    ("common.done", "Done", "Готово", []),
    ("common.loadFailed", "Couldn’t load puzzles.", "Не удалось загрузить пазлы.", []),

    ("home.dailyBadge", "Daily puzzle", "Пазл дня", []),
    ("home.play", "Play", "Играть", []),
    ("home.continueTitle", "Continue", "Продолжить", []),
    ("home.seeAll", "See all", "Все", []),
    ("home.newArrivals", "New in library", "Новое в библиотеке", []),
    ("home.continueEmpty", "Start a puzzle and it will wait for you here.", "Начните пазл — он будет ждать вас здесь.", []),
    ("home.dailySolved", "Solved today", "Собран сегодня", []),
    ("home.streak", "%lld-day streak", "Серия: %lld дн.", ["days"]),
    ("home.piecesAndTime", "%1$lld pieces · about %2$lld min", "%1$lld деталей · около %2$lld мин", ["pieces", "minutes"]),

    ("library.title", "Library", "Библиотека", []),
    ("library.searchPrompt", "Search puzzles", "Поиск пазлов", []),
    ("library.all", "All", "Все", []),
    ("library.empty", "Nothing found", "Ничего не найдено", []),
    ("library.badgeNew", "New", "Новое", []),
    ("library.pieceRange", "%1$lld–%2$lld pieces", "%1$lld–%2$lld деталей", ["minimum", "maximum"]),

    ("category.nature", "Nature", "Природа", []),
    ("category.flowers", "Flowers", "Цветы", []),
    ("category.kids", "Kids", "Детям", []),
    ("category.space", "Space", "Космос", []),
    ("category.cities", "Cities", "Города", []),
    ("category.art", "Art", "Искусство", []),
    ("category.landmarks", "Landmarks", "Достопримечательности", []),
    ("category.countries", "Countries", "Страны", []),

    ("status.completed", "Completed", "Пройден", []),
    ("status.inProgress", "In progress", "В процессе", []),

    ("my.title", "My puzzles", "Мои пазлы", []),
    ("my.inProgress", "In progress", "В процессе", []),
    ("my.completed", "Completed", "Завершённые", []),
    ("my.empty", "Puzzles you start will appear here.", "Здесь появятся начатые пазлы.", []),

    ("setup.title", "New puzzle", "Новый пазл", []),
    ("setup.pieces", "Pieces", "Детали", []),
    ("setup.minutes", "~%lld min", "~%lld мин", ["minutes"]),
    ("setup.rotation", "Rotate pieces", "Поворот деталей", []),
    ("setup.rotationHint", "Harder: pieces arrive turned. Tap a piece to rotate it.", "Сложнее: детали повёрнуты. Нажмите на деталь, чтобы повернуть её.", []),
    ("setup.table", "Table", "Стол", []),
    ("setup.start", "Start · %lld pieces", "Начать · %lld деталей", ["pieces"]),
    ("setup.resume", "Continue saved game", "Продолжить сохранённую игру", []),
    ("setup.offlineNote", "Progress is saved on this device, even offline.", "Прогресс сохраняется на устройстве, даже без интернета.", []),

    ("table.felt", "Green felt", "Зелёное сукно", []),
    ("table.walnut", "Walnut", "Орех", []),
    ("table.slate", "Slate", "Графит", []),
    ("table.linen", "Linen", "Лён", []),

    ("game.loading", "Cutting pieces…", "Режем детали…", []),
    ("game.loadFailed", "Couldn’t open this puzzle.", "Не удалось открыть пазл.", []),
    ("game.board", "Puzzle board", "Игровое поле", []),
    ("game.preview", "Preview", "Превью", []),
    ("game.shuffle", "Shuffle", "Перемешать", []),
    ("game.hint", "Hint · %lld", "Подсказка · %lld", ["count"]),
    ("game.filterAll", "All · %lld", "Все · %lld", ["count"]),
    ("game.filterEdges", "Edges · %lld", "Края · %lld", ["count"]),
    ("game.filterInner", "Inner · %lld", "Внутри · %lld", ["count"]),
    ("game.hintLabel", "Hint", "Подсказка", []),
    ("game.filterAllLabel", "All", "Все", []),
    ("game.filterEdgesLabel", "Edges", "Края", []),
    ("game.filterInnerLabel", "Inner", "Внутри", []),
    ("game.piece", "Piece %lld", "Деталь %lld", ["number"]),
    ("game.placePiece", "Place piece", "Поставить деталь", []),
    ("game.rotatePiece", "Rotate", "Повернуть", []),
    ("game.progress", "%1$lld of %2$lld pieces placed", "Собрано %1$lld из %2$lld", ["placed", "total"]),
    ("game.trayEmpty", "Every piece in this group is placed.", "Все детали этой группы на месте.", []),
    ("game.looseLeft", "Pieces left on the board: %lld", "Осталось на поле: %lld", ["count"]),

    ("done.badge", "Puzzle complete", "Пазл собран", []),
    ("done.saved", "Saved to My puzzles.", "Сохранено в «Мои пазлы».", []),
    ("done.time", "Time", "Время", []),
    ("done.pieces", "Pieces", "Детали", []),
    ("done.streak", "Streak", "Серия", []),
    ("done.streakValue", "%lld d", "%lld дн.", ["days"]),
    ("done.next", "Next puzzle", "Следующий пазл", []),
    ("done.share", "Share picture", "Поделиться", []),
    ("done.backToEvent", "Back to event", "К событию", []),

    ("event.badge", "Event", "Событие", []),
    ("event.levels", "%1$lld of %2$lld levels", "Уровни: %1$lld из %2$lld", ["done", "total"]),
    ("event.postcards", "Postcards", "Открытки", []),
    ("event.postcardCount", "%1$lld of %2$lld postcards", "Открытки: %1$lld из %2$lld", ["collected", "total"]),
    ("event.chapter", "Chapter %lld", "Глава %lld", ["number"]),
    ("event.level", "Level %lld", "Уровень %lld", ["number"]),
    ("event.pieces", "%lld pieces", "%lld деталей", ["pieces"]),
    ("event.locked", "Locked. Finish the previous level first.", "Закрыто. Сначала пройдите предыдущий уровень.", []),
    ("event.completed", "Completed", "Пройден", []),
    ("event.postcardLocked", "Finish chapter %lld to collect", "Пройдите главу %lld, чтобы получить", ["number"]),
    ("event.rewardTitle", "Postcard collected!", "Открытка получена!", []),
    ("event.rewardBody", "Finish every chapter to complete the set.", "Пройдите все главы, чтобы собрать коллекцию.", []),
    ("event.finishedTitle", "Event complete!", "Событие пройдено!", []),
    ("event.finishedBody", "Every postcard is yours.", "Все открытки ваши.", []),
]

CATALOG = [
    ("event.autumnTitle", "Autumn Trail", "Осенняя тропа", []),
    ("event.goldenWoods", "Golden Woods", "Золотой лес", []),
    ("event.lanternTown", "Lantern Town", "Город фонарей", []),
    ("event.firstFrost", "First Frost", "Первый иней", []),
    ("event.amberDunes", "Amber Dunes", "Янтарные дюны", []),
    ("event.mistyLake", "Misty Lake", "Туманное озеро", []),
    ("event.harvestGarden", "Harvest Garden", "Сад урожая", []),
    ("event.lanternStreet", "Lantern Street", "Улица фонарей", []),
    ("event.copperHills", "Copper Hills", "Медные холмы", []),
    ("event.twilightPond", "Twilight Pond", "Сумеречный пруд", []),
    ("event.rowanBloom", "Rowan Bloom", "Рябина", []),
    ("event.rainySquare", "Rainy Square", "Дождливая площадь", []),
    ("event.frostLake", "Frost Lake", "Озеро в инее", []),
]

SPEC = re.compile(r"%(?:(\d+)\$)?lld")


def swift_default(english: str, params: list[str]) -> str:
    counter = iter(range(len(params)))

    def repl(match: re.Match) -> str:
        index = int(match.group(1)) - 1 if match.group(1) else next(counter)
        return "\\(" + params[index] + ")"

    escaped = english.replace("\\", "\\\\").replace('"', '\\"')
    return SPEC.sub(repl, escaped)


def member(key: str) -> tuple[str, str]:
    group, name = key.split(".", 1)
    return group[0].upper() + group[1:], name


def accessor(key: str, english: str, params: list[str], name: str) -> str:
    value = f'String(localized: "{key}", defaultValue: "{swift_default(english, params)}", bundle: .module)'
    if not params:
        return f"static var {name}: String {{ {value} }}"
    signature = ", ".join(f"_ {p}: Int" for p in params)
    return f"static func {name}({signature}) -> String {{ {value} }}"


HEADER = "// Generated by scripts/generate_strings.py. Edit the table there, not this file.\nimport Foundation\n\n"


def grouped_swift(rows) -> str:
    groups: dict[str, list[str]] = {}
    for key, english, _, params in rows:
        group, name = member(key)
        groups.setdefault(group, []).append("        " + accessor(key, english, params, name))
    body = "\n\n".join(f"    enum {g} {{\n" + "\n".join(lines) + "\n    }" for g, lines in groups.items())
    return HEADER + "enum L10n {\n" + body + "\n}\n"


def flat_swift(rows, enum_name: str) -> str:
    lines = ["    " + accessor(key, english, params, member(key)[1]) for key, english, _, params in rows]
    return HEADER + f"enum {enum_name} {{\n" + "\n".join(lines) + "\n}\n"


def catalog(rows) -> str:
    strings = {}
    for key, *values, _params in rows:
        strings[key] = {
            "extractionState": "manual",
            "localizations": {
                lang: {"stringUnit": {"state": "translated", "value": value}}
                for lang, value in zip(LANGUAGES, values)
            },
        }
    return json.dumps({"sourceLanguage": "en", "strings": strings, "version": "1.0"}, ensure_ascii=False, indent=2) + "\n"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


write(KIT / "PuzzliumFeatures" / "Shared" / "L10n.swift", grouped_swift(FEATURES))
write(KIT / "PuzzliumFeatures" / "Resources" / "Localizable.xcstrings", catalog(FEATURES))
write(KIT / "PuzzliumData" / "Catalog" / "CatalogStrings.swift", flat_swift(CATALOG, "CatalogStrings"))
write(KIT / "PuzzliumData" / "Resources" / "Localizable.xcstrings", catalog(CATALOG))
print(f"{len(FEATURES)} feature strings, {len(CATALOG)} catalog strings")
