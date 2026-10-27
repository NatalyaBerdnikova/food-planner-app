import os, sys, json
from pathlib import Path
os.environ['HOME'] = '/Users/natalya/Work/food-planner/tools/_easyocr_home'
sys.path.insert(0, '/Users/natalya/Work/food-planner/tools/_ocr')
import easyocr

ocr_dir = Path('/Users/natalya/Work/food-planner/tools/arise-ocr')
text_dir = Path('/Users/natalya/Work/food-planner/tools/arise-text')
text_dir.mkdir(exist_ok=True)

# Only OCR likely recipe pages: 30-end (skip early intro if already done)
start = int(sys.argv[1]) if len(sys.argv) > 1 else 30
end = int(sys.argv[2]) if len(sys.argv) > 2 else 242

reader = easyocr.Reader(
    ['en'], gpu=False, verbose=False,
    model_storage_directory='/Users/natalya/Work/food-planner/tools/_easyocr_models',
    user_network_directory='/Users/natalya/Work/food-planner/tools/_easyocr_user',
    download_enabled=False,
)
print(f'OCR pages {start}-{end}', flush=True)
for pg in range(start, end+1):
    out = text_dir / f'{pg:03d}.txt'
    if out.exists() and out.stat().st_size > 0:
        print(f'skip {pg}', flush=True)
        continue
    png = ocr_dir / f'{pg:03d}.png'
    if not png.exists():
        print(f'missing png {pg}', flush=True)
        continue
    results = reader.readtext(str(png), detail=0, paragraph=True)
    text = '\n'.join(results)
    out.write_text(text, encoding='utf-8')
    print(f'done {pg} ({len(text)} chars)', flush=True)
print('ALL DONE', flush=True)
