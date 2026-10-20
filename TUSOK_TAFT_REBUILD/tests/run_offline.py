from pathlib import Path
import subprocess,tempfile,re
R=Path(__file__).resolve().parents[1]
pat=re.compile(r'(?P<lhs>\b[A-Za-z_]\w*(?:\.[A-Za-z_]\w*|\[[^\]]+\])*)\s*(?P<op>\+|-)=(?P<rhs>[^;\n]+)')
with tempfile.TemporaryDirectory() as directory:
 d=Path(directory)
 for name in ('CartConfig.lua','CartRules.lua'):
  content=(R/'src/ReplicatedStorage'/name).read_text('utf-8')
  fixed=pat.sub(lambda m:f'{m.group("lhs")} = {m.group("lhs")} {m.group("op")} ({m.group("rhs").strip()})',content)
  (d/name).write_text(fixed,'utf-8')
 p=subprocess.run(['texlua',str(R/'tests/test_rules.lua'),str(d)],capture_output=True,text=True)
 print(p.stdout,p.stderr)
 if p.returncode: raise SystemExit(p.returncode)
