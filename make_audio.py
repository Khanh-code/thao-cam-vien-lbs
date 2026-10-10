"""Generate narration files offline, never inside a visitor request."""
import argparse
from pathlib import Path
from gtts import gTTS

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lang', choices=['vi', 'en'], required=True)
    parser.add_argument('--text-file', type=Path, required=True)
    parser.add_argument('--filename', required=True, help='Example: elephants.mp3')
    args = parser.parse_args()
    if Path(args.filename).name != args.filename or not args.filename.endswith('.mp3') or '\\' in args.filename:
        parser.error('filename must be a simple .mp3 basename')
    text = args.text_file.read_text(encoding='utf-8').strip()
    if not text:
        parser.error('Text file is empty')
    output = Path(__file__).resolve().parent / 'audio' / args.lang / args.filename
    output.parent.mkdir(parents=True, exist_ok=True)
    gTTS(text=text, lang=args.lang).save(str(output))
    print(output)

if __name__ == '__main__':
    main()
