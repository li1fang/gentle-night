#!/usr/bin/env python3
import json
import subprocess

subprocess.run(['xcrun', 'swift', 'build', '--product', 'gentle-night-preview'], check=True)
exe = './.build/debug/gentle-night-preview'
for mode in ['uniform', 'iris', 'probabilistic']:
    for minutes, progress in [(0, 0), (10, 0), (35, .5), (60, 1), (120, 1)]:
        result = json.loads(subprocess.check_output([exe, '--mode', mode, '--idle-minutes', str(minutes)]))
        assert result['progress'] == progress, result
        assert abs(result['recoverySeconds'] - .8 * progress) < 1e-12, result
        if progress == 0:
            assert result['untouchedFraction'] == 1, result
        if progress == 1:
            assert result['fullyBlackFraction'] == 1, result
for args in [['--idle-minutes', 'nan'], ['--width', '0'], ['--mode', 'oops'], ['--seed', '-1'], ['--height']]:
    assert subprocess.run([exe, *args], capture_output=True).returncode != 0, args
print('CLI PASS: three modes, five timeline checkpoints, invalid input rejection.')
