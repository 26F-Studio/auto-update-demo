from flask import Flask, abort, send_file
from pathlib import Path
from zipfile import ZipFile
from filecmp import cmp
from io import StringIO
from uuid import uuid4

app = Flask(__name__)

UUID = uuid4().hex

@app.route('/diff/<string:version>')
def generate_diff(version):
  dir = Path('versions') / version
  latest = Path('versions') / 'latest'
  if not dir.exists():
    abort(404)
  check_next()
  if latest.resolve() == dir.resolve():
    abort(404)
  data = Path('zips') / f'{version}.zip'
  if not data.exists():
    data.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(data, 'w') as zip:
      for file in latest.iterdir():
        if not file.is_file():
          continue
        relative_path = file.relative_to(latest)
        old_version = dir / relative_path
        if old_version.exists() and cmp(file, old_version, shallow=False):
          continue
        zip.write(file, Path('code') / relative_path)
      with StringIO() as f:
        written = False
        for file in dir.iterdir():
          if not file.is_file():
            continue
          relative_path = file.relative_to(dir)
          if not (latest / relative_path).exists():
            print(relative_path, file=f)
            written = True
        if written:
          zip.writestr('removed_file.txt', f.getvalue())
  return send_file(data, download_name=f'{UUID}-{version}.zip')

def check_next():
  file = Path('versions') / 'next'
  if not file.exists():
    return
  with file.open() as f:
    new_version = f.read().strip()
  file.unlink()
  assert '/' not in new_version
  assert new_version not in ('latest', 'next')
  assert (Path('versions') / new_version).exists()
  set_latest(new_version)

def set_latest(version):
  global UUID
  UUID = uuid4().hex
  file = Path('versions') / 'latest'
  if file.exists():
    file.unlink()
  file.symlink_to(version)
  zip_dir = Path('zips')
  if zip_dir.exists():
    for file in zip_dir.iterdir():
      file.unlink()

if __name__ == '__main__':
  app.run(debug=True)