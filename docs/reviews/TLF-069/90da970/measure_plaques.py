from pathlib import Path
from PIL import Image,ImageDraw
import json,sys,numpy as np
root=Path(sys.argv[1]);cap=root/'sol_output';m=json.loads((cap/'manifest.json').read_text())
walls={axis:np.zeros((512,1024),dtype=bool) for axis in ['N','W']}
for o in m['objects']:
 for axis in ['N','W']:
  if not o['path'].startswith('YSort_Walls/Wall'+axis+'_'):continue
  v=o['visuals'][0];im=Image.open(root/v['texture'].replace('res://','')).convert('RGBA');a=np.array(im)[:,:,3]>0
  x=int(v['position'][0]+v['rect'][0]);y=int(v['position'][1]+v['rect'][1])
  walls[axis][y:y+a.shape[0],x:x+a.shape[1]]|=a
stats={}
for index,axis in [(14,'N'),(8,'N'),(9,'N'),(10,'N')]:
 o=m['objects'][index-1];v=o['visuals'][0];im=Image.open(root/v['texture'].replace('res://','')).convert('RGBA')
 x0=int(v['position'][0]+v['rect'][0]);y0=int(v['position'][1]+v['rect'][1]);above=below=outside=0
 for x in range(im.width):
  ys=np.where(walls[axis][:,x0+x])[0];assert len(ys)>0
  for y in range(im.height):
   if im.getpixel((x,y))[3]==0:continue
   wy=y0+y
   above+=int(wy<ys.min());below+=int(wy>ys.max());outside+=int(not walls[axis][wy,x0+x])
 stats[o['path']]={'world_rect':[x0,y0,im.width,im.height],'opaque_pixels_above_tall_wall':above,'opaque_pixels_below_tall_wall_foot':below,'opaque_pixels_outside_wall_mask':outside}
(Path(__file__).parent/'plaque-measurements.json').write_text(json.dumps(stats,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(stats,indent=2))
