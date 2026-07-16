import urllib.request
import json
import random

grades_config = {
    '1': {'sp': '???', 'min_f': 5},
    '2': {'sp': '????', 'min_f': 5},
    '3': {'sp': '?????', 'min_f': 5},
    '4': {'sp': '??????', 'min_f': 2},
    '5': {'sp': '???????', 'min_f': 1},
    '6': {'sp': '????????', 'min_f': 0},
    '7': {'sp': '?????????', 'min_f': 0},
    '8': {'sp': '??????????', 'min_f': 0},
    '9': {'sp': '???????????', 'min_f': 0},
    '10': {'sp': '????????????', 'min_f': 0},
}

def jumble(word):
    chars = list(word)
    while True:
        random.shuffle(chars)
        jumbled = ''.join(chars)
        if jumbled != word or len(word) <= 1:
            return jumbled

words_dart = """import 'package:spelling_bee/models/word.dart';

final List<Word> mockWords = [
"""

word_id = 1

for grade, config in grades_config.items():
    print(f"Fetching words for Grade {grade}...")
    url = f"https://api.datamuse.com/words?sp={config['sp']}&md=d,p,f&max=1000"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching Grade {grade}: {e}")
        continue
    
    valid_words = []
    for item in data:
        word = item.get('word', '')
        if not word.isalpha():
            continue
        
        # Check frequency
        tags = item.get('tags', [])
        freq = 0
        pos = 'noun'
        for tag in tags:
            if tag.startswith('f:'):
                try:
                    freq = float(tag.split(':')[1])
                except:
                    pass
            if tag in ['n', 'v', 'adj', 'adv']:
                pos_map = {'n': 'noun', 'v': 'verb', 'adj': 'adjective', 'adv': 'adverb'}
                pos = pos_map[tag]
        
        if freq < config['min_f']:
            continue
            
        defs = item.get('defs', [])
        if not defs:
            continue
            
        # Get first definition, clean it
        first_def = defs[0].split('\t')[-1].replace("'", "\\'").replace('"', '\\"')
        
        valid_words.append({
            'word': word,
            'pos': pos,
            'def': first_def
        })
        
    # Shuffle and pick 100
    random.shuffle(valid_words)
    selected = valid_words[:100]
    print(f"Got {len(selected)} words for Grade {grade}")
    
    for w in selected:
        word_str = w['word']
        jumbled = jumble(word_str)
        words_dart += f"  const Word(id: 'w{word_id}', grade: '{grade}', spellingBritish: '{word_str}', spellingAmerican: '{word_str}', partOfSpeech: '{w['pos']}', meaning: '{w['def']}', jumbledLetters: '{jumbled}'),\n"
        word_id += 1

words_dart += "];\n"

with open('e:/Spelling_Bee/lib/data/mock_words.dart', 'w', encoding='utf-8') as f:
    f.write(words_dart)

print("Done generating mock_words.dart")
