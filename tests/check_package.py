"""Regression test: omitting a DDS from either manifest must fail packaging."""
from pathlib import Path
import tempfile, shutil, subprocess, sys
root=Path(__file__).resolve().parents[1]
for extension in ('addon','txt'):
    with tempfile.TemporaryDirectory() as temp:
        p=Path(temp)
        shutil.copytree(root/'PBsTetris',p/'PBsTetris')
        (p/'scripts').mkdir()
        shutil.copy(root/'scripts/package.py',p/'scripts/package.py')
        manifest=p/f'PBsTetris/PBsTetris.{extension}'
        manifest.write_text(manifest.read_text().replace('assets/stone.dds\n',''))
        result=subprocess.run([sys.executable,str(p/'scripts/package.py'),'--check'],capture_output=True,text=True)
        assert result.returncode!=0 and 'assets/stone.dds' in result.stderr
        print(f'PASS missing DDS entry rejected in .{extension}')
