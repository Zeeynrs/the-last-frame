extends SceneTree

const SIDES = {"N":Vector2(16,-8),"S":Vector2(-16,8),"E":Vector2(16,8),"W":Vector2(-16,-8)}
var chapter
var room
var player
var cam
var result={"sha":"90da97014250b2ac89e41b38258e7b90f303c42c","objects":[],"views":[]}
var folder="res://sol_output"

func _initialize():
	call_deferred("run")

func vec(v):return [v.x,v.y]
func rect(r):return [r.position.x,r.position.y,r.size.x,r.size.y]
func snap(path):
	await RenderingServer.frame_post_draw
	var im=root.get_texture().get_image()
	assert(im.get_size()==Vector2i(640,360))
	assert(im.save_png(folder+"/"+path)==OK)
func draws(n):
	var a=[]
	for c in n.get_children():
		if c is Sprite2D and c.texture!=null and c.is_visible_in_tree():a.append(c)
		a.append_array(draws(c))
	return a
func chain(n):
	var a=[]
	while n is CanvasItem:
		a.append({"name":str(n.name),"z":n.z_index,"relative":n.z_as_relative,"ysort":n.y_sort_enabled if n is Node2D else false})
		n=n.get_parent()
	return a
func view(name,point):
	player.global_position=point
	player.visible=true
	cam.snap_now()
	await snap(name+".png")
	result.views.append({"name":name,"player":vec(point),"camera":vec(cam.position),"rect":rect(cam.view_rect()),"bounds":rect(cam.bounds)})

func run():
	assert(DisplayServer.get_name()!="headless")
	assert(ProjectSettings.get_setting("application/config/name")=="TLF Audit 069 90da970")
	assert(not OS.get_user_data_dir().ends_with("The Last Frame"))
	root.get_node("SaveService").save_root="user://sol069_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	print("SOL_WINDOWED display=",DisplayServer.get_name()," user_dir=",OS.get_user_data_dir()," viewport=640x360")
	chapter=load("res://scenes/chapters/ch01/Chapter01.tscn").instantiate()
	root.add_child(chapter)
	for i in range(10):await process_frame
	player=chapter.get_node("Player")
	var router=chapter.get_node("RoomRouter")
	room=router.current_room
	cam=router.camera
	assert(room!=null and cam!=null)
	chapter.process_mode=Node.PROCESS_MODE_DISABLED
	var ps=player.get_node("Sprite")
	ps.animation=&"idle_s"
	ps.frame=0
	ps.stop()
	if player.hud!=null:player.hud.hide()
	var diag=chapter.find_child("DialogueBox",true,false)
	if diag!=null:diag.hide()
	result["shape_bounds"]=rect(cam.bounds)
	result["outline"]=[]
	var shape=room.get_meta("room_shape")
	for p in shape.outline:result.outline.append(vec(p))
	result["hidden_floor_cells"]=[]
	for p in shape.hidden_floor_cells():result.hidden_floor_cells.append(vec(p))
	result["user_dir"]=OS.get_user_data_dir()
	await view("view_spawn",Vector2(160,224))
	await view("view_watch",Vector2(240,232))
	await view("view_pit",Vector2(512,288))
	await view("view_gate",Vector2(688,312))
	# Freeze a diagnostic F3 body so all four sides can be inspected without disappearance.
	var op=room.get_node("operator_sighting")
	op.visible=true
	op.get_node("FigureSprite").visible=true
	op.get_node("FigureSprite").frame=2
	op.get_node("GroundRing").visible=false
	await view("view_watch_operator_F3",Vector2(240,232))
	var groups={}
	for sprite in draws(room):
		var owner=sprite
		while owner!=room and not ("object_id" in owner and str(owner.object_id)!="") and owner.name!="operator_sighting":owner=owner.get_parent()
		if owner==room:owner=sprite
		var key=str(owner.object_id) if "object_id" in owner and str(owner.object_id)!="" else "visual:"+str(room.get_path_to(owner))
		if not groups.has(key):groups[key]={"owner":owner,"sprites":[]}
		groups[key].sprites.append(sprite)
	var keys=groups.keys()
	keys.sort()
	var index=0
	for key in keys:
		index+=1
		var g=groups[key]
		var path=str(room.get_path_to(g.owner))
		var anchor=g.owner.global_position
		# Fixture poses are taken around the wall contact, not in mid-air at the mount.
		if path=="Wall_Fixtures/Clock_2":anchor=Vector2(400,104)
		if path=="Wall_Fixtures/Clock_8":anchor=Vector2(592,200)
		if path=="Wall_Fixtures/DepartureBoard":anchor=Vector2(144,152)
		if path=="Wall_Fixtures/ClosedTrackNotice":anchor=Vector2(528,168)
		var rec={"index":index,"object_id":key,"path":path,"anchor":vec(anchor),"node_position":vec(g.owner.global_position),"visuals":[],"samples":{}}
		for s in g.sprites:
			rec.visuals.append({"path":str(room.get_path_to(s)),"texture":s.texture.resource_path,"position":vec(s.global_position),"rect":rect(s.get_rect()),"offset":vec(s.offset),"flip_h":s.flip_h,"scale":vec(s.global_scale),"chain":chain(s)})
		player.global_position=anchor
		cam.snap_now()
		rec["camera"]=vec(cam.position)
		rec["view_rect"]=rect(cam.view_rect())
		var prefix="%03d"%index
		player.visible=false
		await snap(prefix+"_baseline.png")
		for s in g.sprites:s.visible=false
		await snap(prefix+"_neither.png")
		var probes=SIDES.duplicate()
		if "n0" in path or path=="operator_sighting":
			probes["N_center"]=Vector2(0,-12)
			probes["S_center"]=Vector2(0,12)
		for side in probes:
			player.global_position=anchor+probes[side]
			player.visible=true
			for s in g.sprites:s.visible=true
			await snap(prefix+"_"+side+".png")
			for s in g.sprites:s.visible=false
			await snap(prefix+"_"+side+"_no_target.png")
			rec.samples[side]={"player":vec(player.global_position),"inside_shape":shape.contains_tile(Vector2i(floor((player.position.x-320)/32.0+(player.position.y-64)/16.0),floor((player.position.y-64)/16.0-(player.position.x-320)/32.0)))}
		player.visible=false
		for s in g.sprites:s.visible=true
		result.objects.append(rec)
		print("CAPTURE ",index,"/",keys.size()," ",key)
	var f=FileAccess.open(folder+"/manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	print("SOL_CAPTURE_COMPLETE objects=",result.objects.size())
	quit(0)
