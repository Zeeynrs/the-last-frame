"""Read-only review of exact-archive endpoint placements and committed PNG joins.

Usage: python endpoint_probe.py <exact-SHA archive>
Writes only proof images/measurements beside this review script.
"""
from pathlib import Path
import sys,json
from PIL import Image,ImageDraw

archive=Path(sys.argv[1])
sys.path.insert(0,str(archive/'tools/art/gen'))
import tlf068_shape_kit as kit
out=Path(__file__).parent
env=archive/'assets/environments/ch01'
def image(stem):return Image.open(env/(stem+'.png')).convert('RGBA')
def short(name):return 'ch01_env_wall_'+name+'_idle'
origin=(112,96)
def pt(face,u):return (u,0) if face=='N' else (0,u)
def ap(face,u):return kit._tile_to_px(*pt(face,u),origin)
def placements(face,length,start='corner',end='corner'):
    return kit.assemble_wall_run(face,(0,0),pt(face,length),start,end,origin)
def render(items):
    canvas=Image.new('RGBA',(256,160),(0,0,0,0))
    for stem,anchor,pivot,zb in sorted(items,key=lambda v:(v[1][1]+v[3],v[1][0])):
        canvas.alpha_composite(image(stem),(anchor[0]-pivot[0],anchor[1]-pivot[1]))
    return canvas
def corner(stem,face,u):return (short(stem),ap(face,u),(16,56),10)
def profile(im,x):
    ys=[y for y in range(im.height) if im.getpixel((x,y))[3]]
    return [min(ys),max(ys)] if ys else None
def run_face_profile(im,x,face):
    # A turn's other leg can project below this run's base; inspect this face only.
    base=origin[1]+((x-origin[0])//2 if face=='N' else (origin[0]-1-x)//2)
    assert all(im.getpixel((x,y))[3] for y in range(base-48,base+1)),(face,x,base)
    return [base-48,base]
results={'inner_turns':{},'runs':[],'open_odd':{}}
calls=[]
original=kit.assemble_wall_run
def recording(*args,**kwargs):
    result=original(*args,**kwargs)
    calls.append({'args':args,'kwargs':kwargs,'placements':result})
    return result
kit.assemble_wall_run=recording
mockup=kit.build_l_room_mockup()
kit.assemble_wall_run=original
committed=Image.open(archive/'design/art/mockups/ch01_tlf068_l_room_shape_kit_mockup.png').convert('RGBA')
assert mockup.size==(640,360) and mockup.tobytes()==committed.tobytes()
assert len(calls)==12,len(calls)
results['mockup_helper_calls']=calls
results['mockup_pixels_match_committed']=True
for face,axis,length in [('N','n',5),('W','w',3)]:
    items=placements(face,length,'inner_turn')
    first=items[0]
    assert first[1]==ap(face,2),first
    c=image(short(f'subterranean_corner_{axis}_turn_inner'))
    wall=image(first[0]);dx=first[1][0]-origin[0];dy=first[1][1]-origin[1]
    added=0
    for x in (range(16,26) if face=='N' else range(6,16)):
        for y in range(64):
            wx,wy=x-dx,y-dy
            if 0<=wx<32 and 0<=wy<64 and not c.getpixel((x,y))[3] and wall.getpixel((wx,wy))[3]:added+=1
    assert added==0
    composed=render(items+[corner(f'subterranean_corner_{axis}_turn_inner',face,0)])
    # Two adjacent columns at the exact inner-corner/first-module seam.
    xs=(origin[0]+15,origin[0]+16) if face=='N' else (origin[0]-17,origin[0]-16)
    profiles=[profile(composed,x) for x in xs]
    assert all(p and p[1]-p[0]==48 for p in profiles),profiles
    assert abs(profiles[0][0]-profiles[1][0])==1 and abs(profiles[0][1]-profiles[1][1])==1
    results['inner_turns'][face]={'first_module_tile':pt(face,2),'refilled_step_pixels':added,'join_x':xs,'profiles':profiles}

for face,axis in [('N','n'),('W','w')]:
    for length,start,end in [(3,'corner','corner'),(4,'inner_turn','corner'),(4,'corner','endcap_low')]:
        run=placements(face,length,start,end)
        startstem='subterranean_corner_nw_outer' if start=='corner' else f'subterranean_corner_{axis}_turn_inner'
        items=run+[corner(startstem,face,0)]
        if end=='corner':items.append(corner(f'subterranean_corner_{axis}_turn_outer',face,length))
        composed=render(items)
        # Every screen column of the run's active-axis footprint has opaque art.
        xs=range(origin[0],origin[0]+16*length) if face=='N' else range(origin[0]-16*length,origin[0])
        assert all(profile(composed,x) for x in xs),(face,length,start,end)
        # Last full-height join before end corner/cap: the residual tile must be supplied.
        boundary=length-2 if end=='endcap_low' else length-1
        bx=origin[0]+16*boundary if face=='N' else origin[0]-16*boundary
        jxs=(bx-1,bx) if face=='N' else (bx-1,bx)
        profiles=[run_face_profile(composed,x,face) for x in jxs]
        assert all(p and p[1]-p[0]==48 for p in profiles),(face,length,profiles)
        assert abs(profiles[0][0]-profiles[1][0])==1 and abs(profiles[0][1]-profiles[1][1])==1
        results['runs'].append({'face':face,'length':length,'start':start,'end':end,'placements':run,'residual_seam_profiles':profiles,'empty_footprint_columns':0})

results.pop('open_odd')
results['uncornered_endcaps']=[]
proof=Image.new('RGBA',(1024,640),(10,13,20,255));draw=ImageDraw.Draw(proof)
for row,(face,axis) in enumerate([('N','n'),('W','w')]):
    for length in (3,4):
        canonical=placements(face,length,'corner','endcap_low')
        assert len(canonical)==2
        assert canonical[0][1]==ap(face,1)
        assert canonical[-1][0]==short(f'subterranean_{axis}_endcap_low')
        assert canonical[-1][1]==ap(face,length-1)
        for mode in ('endcap_low','open_odd'):
            run=placements(face,length,'corner',mode)
            assert run==canonical,(face,length,mode)
            wall=image(run[0][0]);cap=image(run[-1][0])
            dx=run[0][1][0]-run[-1][1][0];dy=run[0][1][1]-run[-1][1][1]
            refilled=0
            for x in (range(16,32) if face=='N' else range(16)):
                for y in range(64):
                    wx,wy=x-dx,y-dy
                    if 0<=wx<32 and 0<=wy<64 and cap.getpixel((x,y))[3]==0 and wall.getpixel((wx,wy))[3]:refilled+=1
            assert refilled==0,(face,length,mode,refilled)
            composed=render(run+[corner('subterranean_corner_nw_outer',face,0)])
            xs=range(origin[0],origin[0]+16*length) if face=='N' else range(origin[0]-16*length,origin[0])
            empty=sum(profile(composed,x) is None for x in xs)
            assert empty==0
            residual=range(origin[0]+16*(length-1),origin[0]+16*length) if face=='N' else range(origin[0]-16*length,origin[0]-16*(length-1))
            assert all(profile(composed,x) for x in residual)
            results['uncornered_endcaps'].append({'face':face,'length':length,'mode':mode,'placements':run,'empty_footprint_columns':empty,'refilled_step_pixels':refilled,'residual_interval':[length-1,length],'alias_equals_canonical':True})
            if length==3:
                col=0 if mode=='endcap_low' else 1
                proof.alpha_composite(composed.resize((512,320),Image.Resampling.NEAREST),(col*512,row*320))
                draw.text((col*512+10,row*320+8),face+' L=3: '+mode,fill='white')
                draw.text((col*512+10,row*320+25),'Tile 2..3 supplied; step preserved',fill=(120,220,180))
proof.save(out/'uncornered-endcaps.png')
(out/'endpoint-probe.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8',newline='\n')
print('PASS: P1 N/W inner turns at +2, zero refilled step pixels, 2:1 cornice/base seams')
print('PASS: six prior N/W short/residual/explicit-endcap assemblies have no empty columns or seam gaps')
print('PASS: eight uncornered N/W cases (L3/L4, endcap_low/open_odd) supply residual tile; zero empty columns and zero refilled step pixels')
print('PASS: open_odd equals canonical endcap_low placements for all four N/W length pairs')
print('PASS: L-room uses 12 documented helper calls; regenerated pixels match committed 640x360 mockup')
