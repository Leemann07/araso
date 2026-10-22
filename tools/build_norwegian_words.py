"""Norwegian (bokmål) + English words with how common they are, for the heuristic's Latin
model (the fork's english_words.txt).

Norwegian comes from the OpenSubtitles frequency list of hermitdave/FrequencyWords
(no_full.txt, CC BY-SA 4.0): a word's rank becomes a SCOWL-like level, 10 (the most common)
to 60. English keeps its SCOWL levels (build_english_words.py); a word in both lists takes the
lower level. Letters a–z, æ, ø, å only, lowercased; one-letter words only when listed in SHORT.

usage: python3 build_norwegian_words.py <no_full.txt> <english_words.txt> <out.txt>
Output: word<TAB>level, sorted by level then word.
"""
import re
import sys

no_path, en_path, out_path = sys.argv[1:4]
WORD = re.compile(r"^[a-zæøå]+$")
SHORT = {"i", "å", "e"}  # e: "e-post" fragments aside, the letter name; i, å are words
RANKS = [(1500, 10), (4000, 20), (10000, 35), (25000, 40), (50000, 50), (120000, 60)]
MIN_COUNT = 5

level: dict[str, int] = {}
rank = 0
for line in open(no_path, encoding="utf-8"):
    parts = line.split()
    if len(parts) != 2:
        continue
    w, count = parts[0].lower(), int(parts[1])
    if not WORD.match(w) or (len(w) == 1 and w not in SHORT):
        continue
    rank += 1
    if count < MIN_COUNT:
        break
    for limit, lv in RANKS:
        if rank <= limit:
            level[w] = min(level.get(w, 99), lv)
            break
norwegian = len(level)
for line in open(en_path, encoding="utf-8"):
    w, _, lv = line.rstrip("\n").partition("\t")
    if w and lv:
        level[w] = min(level.get(w, 99), int(lv))
with open(out_path, "w", encoding="utf-8") as out:
    for w, lv in sorted(level.items(), key=lambda kv: (kv[1], kv[0])):
        out.write(f"{w}\t{lv}\n")
print(f"{norwegian} Norwegian words, {len(level)} in all")
