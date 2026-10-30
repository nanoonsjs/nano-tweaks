#!/usr/bin/env python3
"""Rebuilds the test repo (nano-repo/test) from the given .debs, with Sileo
depiction pages (description + changelog from each tweak's Tweak.x header).
usage: publish_test.py REPO_DIR DEB..."""
import sys, os, subprocess, gzip, bz2, lzma, hashlib, shutil, json, re
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.dirname(HERE)
DIRS = {'com.nano.musicpill': 'MusicPill', 'com.nano.photos26': 'Photos26', 'com.nano.control26': 'Control26', 'com.nano.lockstar': 'LockStar'}
BASE = 'https://nanoonsjs.github.io/nano-repo/test/'

def changelog(d):
    p = os.path.join(SRC, d, 'Tweak.x')
    if not os.path.exists(p): return []
    out, cur = [], None
    for line in open(p).read().splitlines()[:400]:
        if not line.startswith('//'): break
        m = re.match(r'//\s*(\d+\.\d+(?:\.\d+)?):\s*(.*)', line)
        if m:
            cur = [m.group(1), m.group(2).strip()]; out.append(cur)
        elif cur and re.match(r'//\s{3,}\S', line):
            cur[1] += ' ' + line[2:].strip()
        elif re.match(r'//\s*\S.*made by nano', line):
            continue
    return out

repo = sys.argv[1]; T = os.path.join(repo, 'test')
shutil.rmtree(os.path.join(T, 'debs'), ignore_errors=True)
subprocess.check_call([sys.executable, '-I', os.path.join(HERE, 'make_repo.py'), T] + sys.argv[2:])
os.chdir(T)
os.makedirs('depictions', exist_ok=True)
blocks = open('Packages').read().strip().split('\n\n')
new = []
for b in blocks:
    f = dict(l.split(': ', 1) for l in b.splitlines() if ': ' in l)
    pkg = f['Package']; d = DIRS.get(pkg)
    log = changelog(d) if d else []
    cl_views = []
    for ver, text in log[:30]:
        cl_views.append({'class': 'DepictionSubheaderView', 'title': 'Version ' + ver, 'useBoldText': True, 'useBottomMargin': False})
        cl_views.append({'class': 'DepictionMarkdownView', 'markdown': text[:1].upper() + text[1:], 'useSpacing': True})
        cl_views.append({'class': 'DepictionSeparatorView'})
    dep = {'minVersion': '0.1', 'class': 'DepictionTabView', 'tintColor': '#fa3d5f', 'headerImage': '', 'tabs': [
        {'tabname': 'Details', 'class': 'DepictionStackView', 'views': [
            {'class': 'DepictionMarkdownView', 'markdown': f.get('Description', '')},
            {'class': 'DepictionSeparatorView'},
            {'class': 'DepictionTableTextView', 'title': 'Version', 'text': f.get('Version', '')},
            {'class': 'DepictionTableTextView', 'title': 'Developer', 'text': 'nano'},
            {'class': 'DepictionTableTextView', 'title': 'Repo', 'text': 'nano (test)'},
        ]},
        {'tabname': 'Changelog', 'class': 'DepictionStackView', 'views': cl_views or [{'class': 'DepictionMarkdownView', 'markdown': 'No changelog yet.'}]},
    ]}
    json.dump(dep, open(os.path.join('depictions', pkg + '.json'), 'w'), indent=1)
    lines = [l for l in b.splitlines() if not l.startswith('Depiction: ') and not l.startswith('SileoDepiction: ')]
    lines.append('SileoDepiction: ' + BASE + 'depictions/' + pkg + '.json')
    new.append('\n'.join(lines))
pk = ('\n\n'.join(new) + '\n').encode()
open('Packages', 'wb').write(pk)
open('Packages.gz', 'wb').write(gzip.compress(pk)); open('Packages.bz2', 'wb').write(bz2.compress(pk)); open('Packages.xz', 'wb').write(lzma.compress(pk))
rel = ['Origin: nano test', 'Label: nano (test)', 'Suite: stable', 'Version: 1.0', 'Codename: ios', 'Architectures: iphoneos-arm iphoneos-arm64', 'Components: main', 'Description: Test builds by nano']
for algo, key in (('md5', 'MD5Sum'), ('sha256', 'SHA256')):
    rel.append(key + ':')
    for fn in ('Packages', 'Packages.gz', 'Packages.bz2', 'Packages.xz'):
        bb = open(fn, 'rb').read(); rel.append(' %s %d %s' % (hashlib.new(algo, bb).hexdigest(), len(bb), fn))
open('Release', 'w').write('\n'.join(rel) + '\n')
print('test repo updated')
