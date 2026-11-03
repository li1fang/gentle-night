#!/usr/bin/env python3
"""Output-only silence fixture. Does not record or open a microphone."""
import json
import subprocess
import tempfile
import time
import wave
from pathlib import Path

exe = './.build/debug/GentleNight'
def query():
    return json.loads(subprocess.check_output([exe, '--diagnostics']))

before = query()
assert before['inputIdleSeconds'] >= 0, before
assert before['audioOutputActive'] is not None, 'Audio metadata unavailable'
with tempfile.TemporaryDirectory(prefix='gentle-night-audio-') as folder:
    path = Path(folder) / 'silence.wav'
    with wave.open(str(path), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(44100)
        stream.writeframes(bytes(44100 * 2 * 4))
    player = subprocess.Popen(['/usr/bin/afplay', str(path)])
    try:
        observed = False
        for _ in range(12):
            time.sleep(.15)
            if query()['audioOutputActive'] is True:
                observed = True
                break
        assert observed, 'Own output stream not observed'
    finally:
        player.terminate()
        player.wait(timeout=5)
print('AUDIO PASS: aggregate idle readable; output-state query available; silent output stream reports active (known heuristic limitation).')
