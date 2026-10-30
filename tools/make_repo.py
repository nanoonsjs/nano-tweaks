#!/usr/bin/env python3
"""Builds a Sileo / Zebra / Cydia repo folder from .deb files.
usage: make_repo.py OUTDIR DEB [DEB ...]"""
import sys, os, io, tarfile, hashlib, gzip, bz2, shutil, lzma

def control_of(deb):
    data = open(deb, 'rb').read()
    assert data[:8] == b'!<arch>\n', deb
    pos = 8
    while pos < len(data):
        name = data[pos:pos+16].decode().strip().rstrip('/')
        size = int(data[pos+48:pos+58].decode().strip())
        body = data[pos+60:pos+60+size]
        pos += 60 + size + (size & 1)
        if name.startswith('control.tar'):
            if name.endswith('.xz'): body = lzma.decompress(body)
            elif name.endswith('.gz'): body = gzip.decompress(body)
            tf = tarfile.open(fileobj=io.BytesIO(body))
            for m in tf.getmembers():
                if m.name.lstrip('./') == 'control':
                    return tf.extractfile(m).read().decode().strip()
    raise SystemExit('no control in ' + deb)

out = sys.argv[1]
debs_dir = os.path.join(out, 'debs')
os.makedirs(debs_dir, exist_ok=True)
entries = []
for deb in sys.argv[2:]:
    base = os.path.basename(deb)
    dst = os.path.join(debs_dir, base)
    if os.path.abspath(deb) != os.path.abspath(dst): shutil.copy(deb, dst)
    blob = open(dst, 'rb').read()
    c = control_of(dst)
    c += '\nFilename: debs/%s\nSize: %d\nMD5sum: %s\nSHA1: %s\nSHA256: %s' % (
        base, len(blob), hashlib.md5(blob).hexdigest(), hashlib.sha1(blob).hexdigest(), hashlib.sha256(blob).hexdigest())
    if 'Depiction:' not in c: c += '\nDepiction: https://nanoonsjs.github.io/nano-repo/'
    entries.append(c)
pk = ('\n\n'.join(entries) + '\n').encode()
open(os.path.join(out, 'Packages'), 'wb').write(pk)
open(os.path.join(out, 'Packages.gz'), 'wb').write(gzip.compress(pk))
open(os.path.join(out, 'Packages.bz2'), 'wb').write(bz2.compress(pk))
open(os.path.join(out, 'Packages.xz'), 'wb').write(lzma.compress(pk))
rel = ['Origin: nano', 'Label: nano', 'Suite: stable', 'Version: 1.0', 'Codename: ios',
       'Architectures: iphoneos-arm iphoneos-arm64', 'Components: main', 'Description: Tweaks by nano']
for algo, key in (('md5', 'MD5Sum'), ('sha256', 'SHA256')):
    rel.append(key + ':')
    for f in ('Packages', 'Packages.gz', 'Packages.bz2', 'Packages.xz'):
        b = open(os.path.join(out, f), 'rb').read()
        rel.append(' %s %d %s' % (hashlib.new(algo, b).hexdigest(), len(b), f))
open(os.path.join(out, 'Release'), 'w').write('\n'.join(rel) + '\n')
print('repo with', len(entries), 'packages in', out)
