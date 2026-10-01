"""Verify that GitHub Pages serves the exact MkDocs build and commit."""
import pathlib
import sys
import time
import urllib.request

site, url, revision = pathlib.Path(sys.argv[1]), sys.argv[2].rstrip('/') + '/', sys.argv[3]
files = sorted(site.rglob('*.html')) + [site / 'assets/javascripts/mermaid.min.js']
for attempt in range(12):
    try:
        with urllib.request.urlopen(url + 'revision.txt', timeout=20) as response:
            assert response.read().decode().strip() == revision, 'stale deployed revision'
        for path in files:
            relative = path.relative_to(site).as_posix()
            with urllib.request.urlopen(url + relative, timeout=20) as response:
                assert response.read() == path.read_bytes(), f'stale or incorrect bytes: {relative}'
        print(f'Pages verified: {revision}; {len(files)} HTML/renderer files match the build.')
        break
    except (OSError, AssertionError) as error:
        if attempt == 11:
            raise
        print(f'Waiting for Pages: {error}', flush=True)
        time.sleep(5)
