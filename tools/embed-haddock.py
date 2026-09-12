"""Embed the checked Hackage rendering, adapting only its hosting links."""
import argparse
import html
from functools import cache
from html.parser import HTMLParser
import pathlib
import re
import tarfile
from urllib.parse import unquote, urljoin, urlsplit

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('archive', type=pathlib.Path)
parser.add_argument('destination', type=pathlib.Path)
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
rendered = {}
with tarfile.open(args.archive) as archive:
    for member in archive.getmembers():
        if not member.isfile():
            continue
        parts = pathlib.PurePosixPath(member.name).parts
        assert len(parts) > 1 and '..' not in parts and not member.name.startswith('/')
        relative = pathlib.Path(*parts[1:])
        # Haddock includes extra-doc-files; MkDocs owns those Markdown pages.
        if relative.suffix == '.md':
            continue
        data = archive.extractfile(member).read()
        if relative.suffix == '.html':
            text = data.decode()
            package = parts[0].removesuffix('-docs')
            text = text.replace(f'href="/package/{package}"', 'href="index.html"')
            text = text.replace('href="/package/', 'href="https://hackage.haskell.org/package/')
            # Haddock emits orphan-instance self-links without target IDs.
            anchors = set(re.findall(r'\bid="([^"]+)"', text))
            for fragment in re.findall(r'<a href="#([^"]+)" class="selflink">', text):
                if not {fragment, unquote(fragment)} & anchors:
                    old = f'<a href="#{fragment}" class="selflink">'
                    text = text.replace(old, f'<a id="{fragment}" href="#{fragment}" class="selflink">', 1)
                    anchors.add(fragment)
            for fragment in re.findall(r'<p class="src"><a href="#([^"]+)">', text):
                if not {fragment, unquote(fragment)} & anchors:
                    old = f'<p class="src"><a href="#{fragment}">'
                    text = text.replace(old, f'<p class="src"><a id="{fragment}" href="#{fragment}">', 1)
                    anchors.add(fragment)
            data = text.encode()
        rendered[relative] = data
modules = sorted(p for p in rendered if len(p.parts) == 1 and re.fullmatch(r'[A-Z][\w-]+\.html', p.name))
assert len(modules) == 4, 'All four public module renderings must be present'
assert pathlib.Path('doc-index.html') in rendered
links = ''.join(f'<li><a href="{p.name}">{html.escape(p.stem.replace("-", "."))}</a></li>' for p in modules)
rendered[pathlib.Path('index.html')] = (
    '<!doctype html><html lang="en"><meta charset="utf-8">'
    '<title>tasty-bdd API</title><link rel="stylesheet" href="linuwial.css">'
    f'<body><h1>{html.escape(package)} API</h1><ul>{links}</ul>'
    '<p><a href="doc-index.html">Symbol index</a> · '
    '<a href="../api/" target="_top">Documentation</a></p></body></html>'
).encode()
for relative, expected in rendered.items():
    destination = args.destination / relative
    if args.check:
        assert destination.is_file(), f'Missing embedded Haddock: {relative}'
        assert destination.read_bytes() == expected, f'Stale embedded Haddock: {relative}'
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(expected)
if args.check:
    class Links(HTMLParser):
        def __init__(self, text):
            super().__init__()
            self.links, self.anchors = [], set()
            self.feed(text)

        def handle_starttag(self, tag, attrs):
            for key, value in attrs:
                if key in ('href', 'src') and value:
                    self.links.append(value)
                if key == 'id' and value:
                    self.anchors.add(value)

    @cache
    def document(path):
        return Links(path.read_text())

    for relative, data in rendered.items():
        if relative.suffix != '.html':
            continue
        for link in Links(data.decode()).links:
            target = urlsplit(urljoin('https://docs.invalid/haddock/' + relative.as_posix(), link))
            if target.scheme not in ('http', 'https') or target.netloc != 'docs.invalid':
                continue
            path = args.destination.parent / unquote(target.path).lstrip('/')
            if target.path.endswith('/'):
                path /= 'index.html'
            assert path.is_file(), f'Broken API link in {relative}: {link}'
            if target.fragment and path.suffix == '.html':
                anchors = document(path).anchors
                assert {target.fragment, unquote(target.fragment)} & anchors, f'Broken API anchor in {relative}: {link}'
print(f'{"Verified" if args.check else "Embedded"} {len(rendered)} Haddock files from {args.archive.name}')
