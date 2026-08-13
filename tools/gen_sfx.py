#!/usr/bin/env python3
"""Synthesize the card sound effect.

    python3 tools/gen_sfx.py

A thrown card is a short broadband transient, which synthesizes convincingly:
lowpass-filtered noise with a fast attack and an exponential decay, highpassed
to strip the rumble so it sits above the music. Writes sound/sfx/card.wav.

Replace with a recorded sample if you find a better one -- the filename is all
the game cares about. TrickState varies the pitch per play, so one clip is
enough for the six cards in a hand not to sound mechanical.
"""

import array
import math
import os
import random
import wave

RATE = 22050
DURATION = 0.13
LOWPASS = 0.42      # one-pole coefficient; lower = softer, more papery
HIGHPASS = 0.93     # DC-blocker coefficient
ATTACK = 0.002
DECAY_TAU = 0.030
PEAK = 0.7


def main():
    random.seed(7)
    n = int(RATE * DURATION)
    out = array.array('h')

    lp = 0.0
    hp_prev_in, hp_prev_out = 0.0, 0.0
    samples = []
    for i in range(n):
        t = i / RATE
        white = random.uniform(-1.0, 1.0)
        lp += LOWPASS * (white - lp)
        hp_out = HIGHPASS * (hp_prev_out + lp - hp_prev_in)
        hp_prev_in, hp_prev_out = lp, hp_out

        if t < ATTACK:
            env = t / ATTACK
        else:
            env = math.exp(-(t - ATTACK) / DECAY_TAU)
        samples.append(hp_out * env)

    peak = max(abs(s) for s in samples) or 1.0
    for s in samples:
        out.append(int(max(-1.0, min(1.0, s / peak * PEAK)) * 32767))

    os.makedirs(os.path.join('sound', 'sfx'), exist_ok=True)
    path = os.path.join('sound', 'sfx', 'card.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(out.tobytes())
    print('%s  %.0fms  %d bytes' % (path, DURATION * 1000, os.path.getsize(path)))


if __name__ == '__main__':
    main()
