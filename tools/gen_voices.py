#!/usr/bin/env python3
"""Generate the truco voice clips with the macOS `say` command.

    python3 tools/gen_voices.py

Writes 16-bit 22050Hz mono WAVs to sound/voices/player and sound/voices/ai,
trimming leading/trailing silence so the chained clips ("veintiseis" then
"son mejores") run together without a gap.

Swap either voice below; `say -v '?'` lists what is installed. Diego (es_AR)
is the natural pick for the player if it has been downloaded via
System Settings > Accessibility > Spoken Content > System Voice > Manage Voices.
"""

import array
import os
import subprocess
import sys
import wave

VOICES = {
    'player': 'Reed (Spanish (Spain))',
    'ai': 'Paulina',
}

RATE = 22050

PHRASES = {
    'envido': 'Envido',
    'real': 'Real envido',
    'falta': 'Falta envido',
    'truco': 'Truco',
    'retruco': 'Retruco',
    'vale4': 'Vale cuatro',
    'quiero': 'Quiero',
    'noquiero': 'No quiero',
    'flor': 'Flor',
    'contraflor': 'Contraflor',
    'resto': 'Contraflor al resto',
    'meachico': 'Me achico',
    'mazo': 'Me voy al mazo',
    'sonbuenas': 'Son buenas',
    'sonmejores': 'son mejores',
}

# envido runs 0-33, flor 20-38, so the union is 0-38
for n in range(0, 39):
    PHRASES['n%d' % n] = str(n)

SILENCE = 900      # 16-bit amplitude below which a sample counts as silence
PAD_MS = 15        # keep this much either side of the speech


def trim(path):
    with wave.open(path, 'rb') as w:
        channels, width, rate, frames = (
            w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes())
        raw = w.readframes(frames)
    if width != 2:
        return
    samples = array.array('h')
    samples.frombytes(raw)
    loud = [i for i, s in enumerate(samples) if abs(s) > SILENCE]
    if not loud:
        return
    pad = int(rate * channels * PAD_MS / 1000)
    start = max(0, loud[0] - pad)
    end = min(len(samples), loud[-1] + pad)
    with wave.open(path, 'wb') as w:
        w.setnchannels(channels)
        w.setsampwidth(width)
        w.setframerate(rate)
        w.writeframes(samples[start:end].tobytes())


def main():
    if sys.platform != 'darwin':
        sys.exit('needs macOS `say`')
    installed = subprocess.run(['say', '-v', '?'], capture_output=True, text=True).stdout
    for side, voice in VOICES.items():
        if voice.split(' (')[0] not in installed:
            sys.exit('voice not installed: %s' % voice)

    total = 0
    for side, voice in VOICES.items():
        outdir = os.path.join('sound', 'voices', side)
        os.makedirs(outdir, exist_ok=True)
        for key, text in PHRASES.items():
            path = os.path.join(outdir, key + '.wav')
            subprocess.run(['say', '-v', voice, '-o', path,
                            '--data-format=LEI16@%d' % RATE,
                            '--file-format=WAVE', text], check=True)
            trim(path)
            total += 1
        print('%-7s %-28s %d clips' % (side, voice, len(PHRASES)))

    size = sum(os.path.getsize(os.path.join(r, f))
               for r, _, fs in os.walk(os.path.join('sound', 'voices')) for f in fs)
    print('%d files, %.1f MB' % (total, size / 1e6))


if __name__ == '__main__':
    main()
