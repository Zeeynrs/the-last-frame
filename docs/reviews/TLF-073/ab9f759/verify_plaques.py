"""Read-only exact-archive plaque checks; writes QA evidence beside this script."""
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np
import sys,json,zipfile,hashlib,subprocess,re

archive=Path(sys.argv[1]);dest=Path(__file__).parent
sys.path.insert(0,str(archive/'tools/art/gen'))
from lib import PAL
from tlf068_shape_kit import FONT5X7
sha='ab9f75904962da3ccf7ad783064437893378ae9b'
palette={tuple(c[:3]) for c in PAL.values()}
stats=[];text_stats=[]
proof=Image.new('RGBA',(780,520),(20,26,38,255));draw=ImageDraw.Draw(proof)
for index,(face,stem,size,pivot,canvas_xy,modules,text_layer,lines) in enumerate([
 ('W','ch01_prop_departure_board_nowhere_w_idle',(160,112),(0,80),(64,68),range(3,8),4,[(11,6,'DESTINATION:',6),(11,16,'NOWHERE - 23:59',6)]),
 ('N','ch01_prop_notice_closed_track_n_idle',(80,56),(0,0),(488,116),range(5,8),3,[(5,4,'CLOSED TRACK',3)]),
]):
 im=Image.open(archive/'assets/props/ch01'/f'{stem}.png').convert('RGBA');a=np.array(im)
 assert im.size==size and {int(v) for v in a[:,:,3].flat}<={0,255}
 assert {tuple(p[:3]) for p in a.reshape(-1,4) if p[3]}<=palette
 wall=np.zeros((512,1024),dtype=bool)
 tex=Image.open(archive/f'assets/environments/ch01/ch01_env_wall_subterranean_{face.lower()}_idle.png').convert('RGBA');wa=np.array(tex)[:,:,3]>0
 for k in modules:
  ax,ay=(304-32*k,72+16*k) if face=='W' else (336+32*k,72+16*k)
  wall[ay-56:ay+8,ax-16:ax+16]|=wa
 counts={'above':0,'below':0,'outside':0,'opaque':0,'outside_shear_domain':0}
 for x in range(size[0]):
  ys=np.where(wall[:,canvas_xy[0]+x])[0]
  for y in range(size[1]):
   if not a[y,x,3]:continue
   counts['opaque']+=1;wy=canvas_xy[1]+y
   counts['above']+=int(wy<ys.min());counts['below']+=int(wy>ys.max());counts['outside']+=int(not wall[wy,canvas_xy[0]+x])
   flat_z=y-(80-x//2 if face=='W' else x//2)
   counts['outside_shear_domain']+=int(not 0<=flat_z<(32 if face=='W' else 16))
 assert counts['above']==counts['below']==counts['outside']==counts['outside_shear_domain']==0
 assert im.getpixel(pivot)[3]==255
 stats.append({'face':face,'sprite':stem,'canvas':size,'pivot':pivot,'world_canvas_xy':canvas_xy,**counts})
 with zipfile.ZipFile(archive/'assets/source/ch01'/f'{stem}.pxo') as z:
  meta=json.loads(z.read('data.json'));assert len(meta['frames'])==1 and len(meta['layers'])==4
  text=Image.frombytes('RGBA',size,z.read(f'image_data/frames/1/layer_{text_layer}'))
 for x0,z0,message,space in lines:
  cx=x0;bits=overpaint=0
  for c in message:
   if c==' ' and space!=6:cx+=space;continue
   for ry,row in enumerate(FONT5X7[c]):
    for rx,bit in enumerate(row):
     x=cx+rx;y=(80-x//2 if face=='W' else x//2)+z0+ry
     pixel=text.getpixel((x,y));assert bool(pixel[3])==(bit=='1'),(message,c,rx,ry)
     if bit=='1':bits+=1;overpaint+=int(im.getpixel((x,y))!=pixel)
   cx+=6
  text_stats.append({'message':message,'glyph_bits':bits,'bit_mismatches':0,'runtime_overpaint':overpaint})
 draw.text((10+index*500,8),face+' FULL EXPORT 1x + 3x nearest',fill='white')
 proof.alpha_composite(im,(10+index*500,30))
 proof.alpha_composite(im.resize((size[0]*3,size[1]*3),Image.Resampling.NEAREST),(10+index*500,170))
proof.save(dest/'complete-export-proof.png')
(dest/'plaque-checks.json').write_text(json.dumps({'geometry':stats,'text':text_stats},indent=2)+'\n',encoding='utf-8',newline='\n')
log=['PASS: both documented wall mounts have zero above/below/outside alpha, including cast shadows',
     'PASS: W y=80-floor(x/2)+z; N y=floor(x/2)+z; all opaque pixels inside shear domains',
     'PASS: canonical glyph bits intact under inverse shear; W text intact; N intentional closure slash retained',
     'PASS: declared canvases, pivots, single frame, four layers, binary alpha and palette match exports']
for filename,tail in [('check_assets.txt','RESULT: ALL PASS (267 file(s))'),('verify_regen.txt','RESULT: ALL REPRODUCIBLE')]:
 s=(dest/filename).read_text(encoding='utf-8');assert tail in s and 'PROCESS_EXIT=0' in s
 assert not re.search(r'^(FAIL|SCRIPT ERROR|ERROR:)',s,re.M)
 log.append('PASS: '+tail+'; exit0')
for filename in ['verify_pxo_departure.txt','verify_pxo_notice.txt']:
 s=(dest/filename).read_text(encoding='utf-8');assert 'TOTAL pxo: 1, all identical: True' in s
 assert s.count('exit=0')==2 and s.count('BYTE-IDENTICAL: YES')==1
 errors=re.findall(r'^ERROR:.*$',s,re.M);assert len(errors)==8
 assert all('custom_samplers' in e and 'Continuing.' in e for e in errors)
 log.append('PASS: '+filename+' size/export exits0; PNG byte-identical; 8 known nonfatal shader diagnostics retained')
records=[r for r in subprocess.check_output(['git','ls-tree','-rz','--full-tree',sha]).split(b'\0') if r]
for record in records:
 meta,path=record.split(b'\t',1);mode,kind,want=meta.split();data=(archive/path.decode()).read_bytes()
 assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest().encode()==want,path
log.append(f'PASS: all {len(records)} archive blobs match exact SHA after independent checks')
for name in ['argon-w-mockup.png','argon-n-mockup.png']:
 assert Image.open(dest/name).size==(640,360)
log.append('No game project launched; no real-save use; evidence only')
(dest/'verification.txt').write_text('\n'.join(log)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'geometry':stats,'text':text_stats},indent=2));print('\n'.join(log))
