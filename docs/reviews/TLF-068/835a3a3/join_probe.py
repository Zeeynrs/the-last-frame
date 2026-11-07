from pathlib import Path
from PIL import Image,ImageDraw
import json,sys

root=Path(sys.argv[1])
env=root/'assets/environments/ch01'
out=Path(__file__).parent
def image(name):return Image.open(env/('ch01_env_wall_'+name+'_idle.png')).convert('RGBA')
def panel(axis,offset):
    canvas=Image.new('RGBA',(240,150),(10,13,20,255))
    anchor=(112,112)
    corner=image('subterranean_corner_'+axis+'_turn_inner')
    straight=image('subterranean_'+axis)
    dx,dy=(16,8) if axis=='n' else (-16,8)
    def paste(img,x,y):canvas.alpha_composite(img,(x-16,y-56))
    for step in [offset,offset+2]:paste(straight,anchor[0]+dx*step,anchor[1]+dy*step)
    paste(corner,*anchor)
    d=ImageDraw.Draw(canvas)
    d.text((6,5),axis.upper()+' INNER: '+('metadata +1' if offset==1 else 'mockup +2'),fill='white')
    d.line((anchor[0]-3,anchor[1],anchor[0]+3,anchor[1]),fill='red')
    return canvas
sheet=Image.new('RGBA',(960,600),(10,13,20,255))
for row,axis in enumerate(('n','w')):
    for col,offset in enumerate((1,2)):
        p=panel(axis,offset)
        sheet.alpha_composite(p.resize((480,300),Image.Resampling.NEAREST),(col*480,row*300))
sheet.save(out/'inner-turn-mapping-comparison.png')

# Count tall wall pixels which refill the transparent area above the stepped corner.
findings={}
for axis in ('n','w'):
    c=image('subterranean_corner_'+axis+'_turn_inner')
    wall=image('subterranean_'+axis)
    count=0
    # Corner at (0,0); the first mapped module is one tile further on the tall leg.
    dx,dy=(16,8) if axis=='n' else (-16,8)
    for x in (range(16,26) if axis=='n' else range(6,16)):
        for y in range(64):
            wx,wy=x-dx,y-dy
            if 0<=wx<32 and 0<=wy<64 and c.getpixel((x,y))[3]==0 and wall.getpixel((wx,wy))[3]:
                count+=1
    findings[axis+'_turn_inner']={'opaque_wall_pixels_above_stepped_half':count,'metadata_first_module_delta':[dx,dy],'mockup_first_module_delta':[dx*2,dy*2]}
(out/'join-probe.json').write_text(json.dumps(findings,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(findings,indent=2))
