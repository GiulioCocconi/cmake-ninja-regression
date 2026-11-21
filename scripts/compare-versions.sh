#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
mkdir -p logs builds
: "${CMAKE_445:=}"
: "${CMAKE_450:=}"
: "${NINJA:=$(command -v ninja)}"
export CMAKE_445 CMAKE_450 NINJA
python3 - <<'PY'
import json, os, pathlib, shutil, subprocess
root = pathlib.Path.cwd()
results = []
for version, key in [('4.4.5', 'CMAKE_445'), ('4.5.0', 'CMAKE_450')]:
    exe = os.environ[key]
    build = root / 'builds' / ('basic-' + version)
    log = root / 'logs' / ('basic-' + version)
    if build.exists(): shutil.rmtree(build)
    item = {'requested_version': version, 'executable': exe or None, 'exit_status': None, 'status': 'not-run'}
    if exe and pathlib.Path(exe).is_file():
        actual = subprocess.run([exe, '--version'], capture_output=True, text=True)
        item['actual_version'] = actual.stdout.splitlines()[0] if actual.stdout else ''
        if actual.returncode == 0 and item['actual_version'] == 'cmake version ' + version:
            cmd = [exe, '-S', str(root / 'repro/basic'), '-B', str(build), '-G', 'Ninja', '--debug-trycompile', '-DCMAKE_MAKE_PROGRAM=' + os.environ['NINJA']]
            p = subprocess.run(cmd, capture_output=True, text=True)
            pathlib.Path(str(log) + '.stdout').write_text(p.stdout)
            pathlib.Path(str(log) + '.stderr').write_text(p.stderr)
            item.update(status='passed' if p.returncode == 0 else 'failed', exit_status=p.returncode, command=cmd)
        else: item['status'] = 'wrong-version'
    results.append(item)
    print(f"{version}: {item['status']} (exit {item['exit_status']})")
(root / 'logs/comparison.json').write_text(json.dumps(results, indent=2) + '\n')
raise SystemExit(0 if all(x['status'] == 'passed' for x in results) else 1)
PY
