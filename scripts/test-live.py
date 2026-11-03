#!/usr/bin/env python3
"""Explicit whole-display test, bounded to 55 seconds. Do not use in headless CI."""
import re
import subprocess
import time

app = 'dist/Gentle Night.app/Contents/MacOS/GentleNight'
process = subprocess.Popen([app, '--accelerated'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
try:
    time.sleep(2)
    during = subprocess.check_output(['pmset', '-g', 'assertions'], text=True)
    pattern = rf'pid\s+{process.pid}\('
    assert re.search(pattern, during), 'Temporary app power assertion not observed'
    output, _ = process.communicate(timeout=53)
    print(output, end='')
    assert process.returncode == 0, process.returncode
    assert 'actual idle reached black endpoint' in output, 'No full-black endpoint observed (user activity may have interrupted the test); do not retry automatically'
    after = subprocess.check_output(['pmset', '-g', 'assertions'], text=True)
    assert not re.search(pattern, after), 'Power assertion remained after exit'
    print('LIVE PASS: actual aggregate idle reached full black; bounded automatic exit; power assertion released.')
finally:
    if process.poll() is None:
        process.terminate()
        process.wait(timeout=5)
