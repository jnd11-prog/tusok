"""Compatibility parse Luau source using Lua 5.3 (texluac); does not emulate Roblox."""
from pathlib import Path
import re,subprocess,tempfile
R=Path(__file__).resolve().parents[1]
files=sorted((R/'src').rglob('*.lua'))
assert len(files)==5
pat=re.compile(r'(?P<lhs>\b[A-Za-z_]\w*(?:\.[A-Za-z_]\w*|\[[^\]]+\])*)\s*(?P<op>\+|-)=(?P<rhs>[^;\n]+)')
with tempfile.TemporaryDirectory() as d:
 for source in files:
  original=source.read_text('utf-8')
  translated=pat.sub(lambda m:f'{m.group("lhs")} = {m.group("lhs")} {m.group("op")} ({m.group("rhs").strip()})',original)
  assert '+=' not in translated and '-=' not in translated,source
  out=Path(d)/(source.stem+'.lua')
  out.write_text(translated,'utf-8')
  p=subprocess.run(['texluac','-p',str(out)],capture_output=True,text=True)
  if p.returncode: raise AssertionError(f'{source}: {p.stderr}')
  print('PASS syntax:',source.relative_to(R))
print('PASS:',len(files),'script syntax checks (Lua-5.3 compatibility mode; Studio test still needed)')
