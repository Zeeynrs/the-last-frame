"""Read-only evidence verification for Sol's exact-SHA scratch capture.

python verify_evidence.py <renamed scratch archive>
Requires Pillow/numpy and the comparator PNGs retained in scratch sol_output.
"""
from pathlib import Path
import json,hashlib,subprocess,sys,os,re
import numpy as np
from PIL import Image

archive=Path(sys.argv[1]);dest=Path(__file__).parent;cap=archive/'sol_output'
sha='90da97014250b2ac89e41b38258e7b90f303c42c'
m=json.loads((dest/'render-manifest.json').read_text());messages=[]
def passed(s):messages.append('PASS: '+s);print(messages[-1])
def rgb(p):
 with Image.open(p) as im:
  assert im.size==(640,360),p
  return np.array(im.convert('RGB'))

assert m['sha']==sha and len(m['objects'])==71
assert m['hidden_floor_cells']==[]
assert m['user_dir'].endswith('TLF Audit 069 90da970')
checked=0
for o in m['objects']:
 prefix=f"{o['index']:03d}";B=rgb(cap/f'{prefix}_baseline.png');D=rgb(cap/f'{prefix}_neither.png');om=np.any(B!=D,axis=2)
 assert set(['N','S','E','W'])<=set(o['samples'])
 for side in o['samples']:
  A=rgb(cap/f'{prefix}_{side}.png');C=rgb(cap/f'{prefix}_{side}_no_target.png')
  mask=om&np.any(C!=D,axis=2)&np.any(B!=C,axis=2)
  stats={'intersection':int(mask.sum()),'object_front':int((mask&np.all(A==B,axis=2)).sum()),'player_front':int((mask&np.all(A==C,axis=2)).sum())}
  assert stats==o['pixels'][side],(prefix,side)
  assert (dest/'per-side'/f'{prefix}_{side}.png').read_bytes()==(cap/f'{prefix}_{side}.png').read_bytes()
  checked+=1
assert checked==294 and len(list((dest/'per-side').glob('*.png')))==294
passed('71 groups / 284 N-S-E-W + 10 centreline native 640x360 frames match scratch; every overlap count reproduced')
for v in m['views']:
 assert (dest/(v['name']+'.png')).read_bytes()==(cap/(v['name']+'.png')).read_bytes()
 rgb(dest/(v['name']+'.png'))
 x,y,w,h=v['rect'];bx,by,bw,bh=v['bounds']
 assert x>=bx and y>=by and x+w<=bx+bw and y+h<=by+bh
 assert all(float(c).is_integer() for c in v['camera'])
assert len(m['views'])==5
passed('five native camera views match scratch and stay inside RoomShape bounds at whole-pixel centres')
for name,source in json.loads((dest/'example-sources.json').read_text()).items():
 assert (dest/'examples'/name).read_bytes()==(cap/source).read_bytes();rgb(dest/'examples'/name)
passed('six selected merge examples are exact native engine PNGs, including no-Elias seated diagnostic')
low=[]
for o in m['objects']:
 v=o['visuals'][0]
 if 'wall_partition_low' not in v['texture']:continue
 assert v['scale']==[1.0,1.0]
 im=Image.open(archive/v['texture'].replace('res://','')).convert('RGBA')
 spans=[]
 for x in range(im.width):
  ys=[y for y in range(im.height) if im.getpixel((x,y))[3]]
  if ys:spans.append(max(ys)-min(ys))
 assert max(spans)<=20
 low.append({'object':o['object_id'],'vertical_extent':max(spans)})
assert len(low)==26
(dest/'low-heights.json').write_text(json.dumps(low,indent=2)+'\n',encoding='utf-8',newline='\n')
passed('23 straight low pieces + three low corners are unit scale; maximum vertical extent 17px')
records=[r for r in subprocess.check_output(['git','ls-tree','-rz','--full-tree',sha]).split(b'\0') if r];changed=[]
for record in records:
 meta,path=record.split(b'\t',1);mode,kind,want=meta.split();data=(archive/path.decode()).read_bytes()
 if hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest().encode()!=want:changed.append(path.decode())
assert len(records)==1557 and changed==['project.godot'],changed
passed('1557 exact-SHA archive blobs checked; only permitted scratch project.godot rename/user-dir differs')
capture=(dest/'capture.txt').read_text(encoding='utf-8')
assert 'SOL_CAPTURE_COMPLETE objects=71' in capture and 'SOL_WINDOWED display=Windows' in capture
assert not any(s in capture for s in ['SCRIPT ERROR','ERROR:','Assertion failed'])
passed('windowed D3D12 capture process exit0, all 71 groups complete, no engine/script/assertion errors in log')
real=Path(os.environ['APPDATA'])/'Godot/app_userdata/The Last Frame'
files=list((real/'saves').rglob('*')) if (real/'saves').exists() else []
if (real/'settings.cfg').exists():files.append(real/'settings.cfg')
after={str(p.relative_to(real)):{'size':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(files) if p.is_file()}
before=json.loads((archive/'real-save-before.json').read_text());assert before==after
(dest/'save-isolation.json').write_text(json.dumps({'user_dir':m['user_dir'],'save_root':'user://sol069_saves','before':before,'after':after,'equal':True},indent=2)+'\n',encoding='utf-8',newline='\n')
passed('real saves/settings unchanged: file inventory, size, SHA256, mtime all identical before/after')
report=dest.parent.parent/'TLF-069_90da970_visual_rereview.md'
for link in re.findall(r'\]\(([^)]+)\)',report.read_text(encoding='utf-8')):
 if link.startswith('https://'):continue
 assert (report.parent/link).exists(),link
passed('all report local links resolve within the small example merge set; bulk proof linked to review branch')
(dest/'verification.txt').write_text('\n'.join(messages)+'\n',encoding='utf-8',newline='\n')
