#!/usr/bin/env python3
"""Rebuilds the test repo (nano-repo/test) from the given .debs. usage: publish_test.py REPO_DIR DEB..."""
import sys, os, subprocess, gzip, bz2, lzma, hashlib, shutil
repo = sys.argv[1]; T = os.path.join(repo, 'test')
shutil.rmtree(os.path.join(T, 'debs'), ignore_errors=True)
subprocess.check_call([sys.executable, '-I', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'make_repo.py'), T] + sys.argv[2:])
os.chdir(T)
pk = open('Packages').read().replace('Depiction: https://nanoonsjs.github.io/nano-repo/\n', 'Depiction: https://nanoonsjs.github.io/nano-repo/test/\n').encode()
open('Packages', 'wb').write(pk)
open('Packages.gz', 'wb').write(gzip.compress(pk)); open('Packages.bz2', 'wb').write(bz2.compress(pk)); open('Packages.xz', 'wb').write(lzma.compress(pk))
rel = ['Origin: nano test', 'Label: nano (test)', 'Suite: stable', 'Version: 1.0', 'Codename: ios', 'Architectures: iphoneos-arm iphoneos-arm64', 'Components: main', 'Description: Test builds by nano']
for algo, key in (('md5', 'MD5Sum'), ('sha256', 'SHA256')):
    rel.append(key + ':')
    for f in ('Packages', 'Packages.gz', 'Packages.bz2', 'Packages.xz'):
        b = open(f, 'rb').read(); rel.append(' %s %d %s' % (hashlib.new(algo, b).hexdigest(), len(b), f))
open('Release', 'w').write('\n'.join(rel) + '\n')
print('test repo updated')
