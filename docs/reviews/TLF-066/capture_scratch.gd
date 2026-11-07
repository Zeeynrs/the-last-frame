extends SceneTree

const ROOMS = ["arrival_platform", "concourse_west", "maintenance_bay", "security_crossing", "waiting_lounge", "signal_control", "upper_vestibule", "vestibule_niche", "station_atrium", "street_exit"]
const SIDES = {"N": Vector2(16,-8), "S": Vector2(-16,8), "E": Vector2(16,8), "W": Vector2(-16,-8)}
var out_dir = "res://audit_output"
var results = []
var chap
var player

func _initialize():
	call_deferred("_run")

func image_now():
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func screenshot(path):
	var im = await image_now()
	assert(im.get_size() == Vector2i(640,360))
	assert(im.save_png(path) == OK)

func vec(v):
	return [v.x,v.y]

func drawables(node):
	var arr = []
	for ch in node.get_children():
		if ch is Sprite2D and ch.texture != null:
			arr.append(ch)
		elif ch is Polygon2D and ch.polygon.size() > 0:
			arr.append(ch)
		arr.append_array(drawables(ch))
	return arr

func owner_for(s, room):
	var n = s
	while n != room and n != null:
		if "object_id" in n and str(n.object_id) != "":
			return [str(n.object_id), n]
		if n.name == "operator_sighting":
			return ["ch01.arrival_platform.operator_sighting", n]
		n = n.get_parent()
	return ["visual:" + str(room.get_path_to(s)), s]

func chain(s):
	var arr=[]
	var n=s
	while n is CanvasItem:
		arr.append({"name":str(n.name),"z":n.z_index,"relative":n.z_as_relative,"ysort":n.y_sort_enabled if n is Node2D else false,"position":vec(n.position) if n is Node2D else []})
		n=n.get_parent()
	return arr

func _run():
	assert(DisplayServer.get_name() != "headless")
	assert(ProjectSettings.get_setting("application/config/name") == "TLF Audit 066 9ca9759")
	assert(not OS.get_user_data_dir().ends_with("The Last Frame"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var save = root.get_node_or_null("SaveService")
	if save != null: save.save_root = "user://tlf066_saves"
	print("AUDIT_WINDOWED display=",DisplayServer.get_name()," user_dir=",OS.get_user_data_dir()," viewport=640x360")
	for room_name in ROOMS:
		chap=load("res://scenes/chapter/ChapterRoot.tscn").instantiate()
		chap.process_mode=Node.PROCESS_MODE_DISABLED
		root.add_child(chap)
		player=chap.get_node("Player")
		player.z_index=10
		var ps=player.get_node("Sprite")
		ps.animation=&"idle_s"
		ps.frame=0
		ps.stop()
		if player.hud != null: player.hud.hide()
		var room=load("res://scenes/chapters/ch01/rooms/"+room_name+".tscn").instantiate()
		chap.get_node("RoomContainer").add_child(room)
		# Render conditionally visible Operator in his authored F3 state, without playing approach events.
		var op=room.get_node_or_null("operator_sighting")
		if op != null:
			op.visible=true
			op.get_node("FigureSprite").visible=true
			op.get_node("FigureSprite").frame=2
			if op.get_node_or_null("GroundRing") != null: op.get_node("GroundRing").visible=false
		await process_frame
		var folder=out_dir+"/"+room_name
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
		player.visible=false
		await screenshot(folder+"/baseline.png")
		var grouped={}
		var hidden=[]
		for s in drawables(room):
			if not s.is_visible_in_tree():
				hidden.append(str(room.get_path_to(s)))
				continue
			var pair=owner_for(s,room)
			if not grouped.has(pair[0]): grouped[pair[0]]={"node":pair[1],"visuals":[]}
			grouped[pair[0]]["visuals"].append(s)
		var room_result={"room":room_name,"objects":[],"hidden_drawables":hidden,"nonvisual_ids":[]}
		for node in room.find_children("*","Node2D",true,false):
			if "object_id" in node and str(node.object_id) != "" and not grouped.has(str(node.object_id)):
				room_result.nonvisual_ids.append({"id":str(node.object_id),"pos":vec(node.global_position),"node":str(room.get_path_to(node))})
		var keys=grouped.keys()
		keys.sort()
		var index=0
		for key in keys:
			index+=1
			var obj=grouped[key]
			if "--procedural" in OS.get_cmdline_user_args() and not obj.node is Polygon2D:
				continue
			if "--centerline" in OS.get_cmdline_user_args():
				if not obj.visuals[0] is Sprite2D or not "ch01_char_statue" in obj.visuals[0].texture.resource_path:
					continue
			var rec={"object_id":key,"index":index,"path":str(room.get_path_to(obj.node)),"anchor":vec(obj.node.global_position),"visuals":[],"samples":{}}
			if obj.node is Polygon2D:
				var bounds=Rect2(obj.node.to_global(obj.node.polygon[0]), Vector2.ZERO)
				for pt in obj.node.polygon: bounds=bounds.expand(obj.node.to_global(pt))
				rec["node_anchor"]=rec.anchor
				rec.anchor=vec(Vector2(bounds.get_center().x, bounds.end.y))
			for s in obj.visuals:
				var v={"path":str(room.get_path_to(s)),"global":vec(s.global_position),"chain":chain(s),"kind":s.get_class()}
				if s is Sprite2D:
					v.merge({"sprite":s.texture.resource_path,"offset":vec(s.offset),"centered":s.centered,"flip_h":s.flip_h,"flip_v":s.flip_v,"scale":vec(s.global_scale),"rect":[s.get_rect().position.x,s.get_rect().position.y,s.get_rect().size.x,s.get_rect().size.y]})
				else:
					v["sprite"]="procedural:Polygon2D"
					v["polygon"]=[]
					for pt in s.polygon: v["polygon"].append(vec(s.to_global(pt)))
				rec.visuals.append(v)
			var prefix=folder+"/%03d"%index
			for s in obj.visuals: s.visible=false
			await screenshot(prefix+"_no_target_no_player.png")
			var probe_sides=SIDES
			if "--centerline" in OS.get_cmdline_user_args(): probe_sides={"N_center":Vector2(0,-12),"S_center":Vector2(0,12)}
			for side in probe_sides:
				player.global_position=Vector2(rec.anchor[0],rec.anchor[1])+probe_sides[side]
				player.visible=true
				for s in obj.visuals:s.visible=true
				await screenshot(prefix+"_"+side+".png")
				for s in obj.visuals:s.visible=false
				await screenshot(prefix+"_"+side+"_no_target.png")
				rec.samples[side]={"player":vec(player.global_position),"file":"%03d_%s.png"%[index,side]}
			player.visible=false
			for s in obj.visuals:s.visible=true
			room_result.objects.append(rec)
			print("CAPTURE ",room_name," ",index,"/",keys.size()," ",key)
		results.append(room_result)
		var manifest_name="manifest-procedural.json" if "--procedural" in OS.get_cmdline_user_args() else "manifest.json"
		if "--centerline" in OS.get_cmdline_user_args(): manifest_name="manifest-centerline.json"
		var jf=FileAccess.open(out_dir+"/"+manifest_name,FileAccess.WRITE)
		jf.store_string(JSON.stringify({"sha":"9ca9759","display":DisplayServer.get_name(),"user_dir":OS.get_user_data_dir(),"sides":"room axes: N(+16,-8),S(-16,+8),E(+16,+8),W(-16,-8)","rooms":results},"\t"))
		jf.close()
		chap.queue_free()
		await process_frame
	print("AUDIT_CAPTURE_COMPLETE rooms=",results.size())
	quit(0)
