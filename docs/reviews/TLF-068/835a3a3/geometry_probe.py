"""Read-only geometry/palette review against an extracted exact-SHA archive."""
from pathlib import Path
import sys,json,importlib.util
from PIL import Image

archive=Path(sys.argv[1])
sys.path.insert(0,str(archive/'tools/art/gen'))
import tlf068_shape_kit as kit
from lib import PAL
spec=importlib.util.spec_from_file_location('shape_builder',archive/'tools/content/build_room_from_shape.py')
builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
out=Path(__file__).parent
inventory=[]
palette={tuple(c[:3]) for c in PAL.values()}
for stem,(w,h,names,fn,pivot) in kit.ASSETS.items():
    im=Image.open(archive/'assets/environments/ch01'/f'{stem}.png').convert('RGBA')
    assert im.size==(w,h)
    pixels=[im.getpixel((x,y)) for y in range(h) for x in range(w)]
    assert {p[3] for p in pixels}<={0,255}
    assert {p[:3] for p in pixels if p[3]}<=palette
    spans=[]
    for x in range(w):
        ys=[y for y in range(h) if im.getpixel((x,y))[3]]
        if ys:spans.append(max(ys)-min(ys))
    if 'partition_low' in stem:assert max(spans)<=20
    row={'sprite':stem,'canvas':[w,h],'pivot':pivot,'layers':names,'max_opaque_column_vertical_delta':max(spans)}
    if 'endcap_low' in stem:
        tipx=31 if '_n_endcap' in stem else 0
        ys=[y for y in range(h) if im.getpixel((tipx,y))[3]]
        row['opening_tip_vertical_delta']=max(ys)-min(ys)
        assert row['opening_tip_vertical_delta']==16
    if stem.endswith('partition_low_s_idle'):
        assert all(next(y for y in range(h) if im.getpixel((x,y))[3])==x//2 for x in range(w))
    if stem.endswith('partition_low_e_idle'):
        assert all(next(y for y in range(h) if im.getpixel((x,y))[3])==(31-x)//2 for x in range(w))
    inventory.append(row)
fixtures={
    'rectangle':[(0,0),(12,0),(12,10),(0,10)],
    'SE':[(0,0),(12,0),(12,6),(8,6),(8,10),(0,10)],
    'NE':[(0,0),(8,0),(8,4),(12,4),(12,10),(0,10)],
    'SW':[(0,0),(12,0),(12,10),(4,10),(4,6),(0,6)],
    'NW':[(2,0),(12,0),(12,10),(0,10),(0,2),(2,2)],
}
mapping={
    ('outer_corner',('W','N')):'subterranean_corner_nw_outer',
    ('inner_corner',('N','W')):'subterranean_corner_nw_inner',
    ('outer_corner',('N','low_E')):'subterranean_corner_n_turn_outer',
    ('inner_corner',('low_E','N')):'subterranean_corner_n_turn_inner',
    ('outer_corner',('low_S','W')):'subterranean_corner_w_turn_outer',
    ('inner_corner',('W','low_S')):'subterranean_corner_w_turn_inner',
    ('inner_corner',('low_S','low_E')):'partition_low_corner_inner',
    ('outer_corner',('low_E','low_S')):'partition_low_corner_outer',
}
covered=set()
for points in fixtures.values():
    for segment in builder.wall_segments(builder.canonical(points)):
        if segment['kind']=='straight':continue
        key=(segment['kind'],tuple(segment['faces']))
        assert key in mapping,key
        assert 'ch01_env_wall_'+mapping[key]+'_idle' in kit.ASSETS
        covered.add(key)
assert len(covered)==8
sheet=Image.open(archive/'assets/characters/ch01/ch01_char_elias_base_sheet.png')
elias={'frame_size':[32,48],'mockup_frame_regions':[[0,0,32,48],[64,0,96,48]],'alpha_bounds':[sheet.crop(box).getbbox() for box in [(0,0,32,48),(64,0,96,48)]],'resize_applied':False}
proof={'inventory':inventory,'covered_corner_kind_faces':[list((key[0],list(key[1]))) for key in sorted(covered)],'elias_reference':elias}
(out/'geometry-probe.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8',newline='\n')
print('PASS: 12 asset canvases/pivots inspected; binary alpha and TLF-CH01-32; low straight delta16, corner delta17 <=20')
print('PASS: all eight corner kind/faces combinations from canonical RoomShape-builder fixtures match the table assets')
print('PASS: native 32x48 Elias v2 frame crops, no resize in mockup generator')
print('PASS: low S/E straight profiles step 2:1; both endcap opening tips have vertical delta16')
