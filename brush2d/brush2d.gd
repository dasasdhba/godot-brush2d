@tool
@icon("icon.png")
extends Node2D
class_name Brush2D

@export_category("Brush2D")
@export var grid: Vector2 = Vector2(16,16)
@export var default_border :Rect2 = Rect2(-16,-16,32,32)
@export var default_offset :Vector2 = Vector2(16,16)
@export var force_border :bool = false
@export var force_offset :bool = false

var preview :bool = true
var preview_alpha :float = 0.5
var preview_border :bool = true
var border_color :Color = Color(0.9,0.4,0.3,0.7)
var border_width :float = 2

const paint_button :int = MOUSE_BUTTON_LEFT
const erase_button :int = MOUSE_BUTTON_RIGHT
var copy_key :int = KEY_C
var cut_key :int = KEY_X
var click_restrict_key : int = KEY_SHIFT
var click_only :bool = true

var working :bool = false

var border :Rect2
var offset :Vector2

var copy_list :Array = []
var paint_restrict :bool = false
var erase_restrict :bool = false
var copy_restrict :bool = false
var cut_restrict :bool = false

var preview_res :Resource = null
var preview_node :Node
var preview_list :Array
var preview_rect :Rect2 = Rect2(Vector2.ZERO,Vector2.ZERO)

var brush_last = null
var mouse_last :Vector2 = Vector2(INF,INF)
var grid_last = null

func get_brush(node :Node) ->void:
	var param_node = null
	for i in node.get_children():
		if i.get("brush_param_hint") == true:
			param_node = i
			break

	if !force_border && param_node != null && param_node.enable_border:
		border = param_node.border
		var pos :Vector2 = border.position
		var end :Vector2 = border.end
		pos.x *= node.scale.x
		pos.y *= node.scale.y
		end.x *= node.scale.x
		end.y *= node.scale.y
		border = Rect2(pos, end - pos)
		if node.rotation != 0:
			var tl :Vector2 = border.position.rotated(rotation)
			var tr: Vector2 = Vector2(border.end.x,border.position.y).rotated(rotation)
			var bl: Vector2 = Vector2(border.position.x,border.end.y).rotated(rotation)
			var br: Vector2 = border.end.rotated(rotation)
			var xlist :Array = [tl.x,tr.x,bl.x,br.x]
			var ylist :Array = [tl.y,tr.y,bl.y,br.y]
			border.position.x = xlist.min()
			border.position.y = ylist.min()
			border.end.x = xlist.max()
			border.end.y = ylist.max()
			xlist.clear()
			ylist.clear()
	else:
		border = default_border
	
	if !force_offset && param_node != null && param_node.enable_offset:
		offset = param_node.offset
		offset.x *= node.scale.x
		offset.y *= node.scale.y
		offset.rotated(node.rotation)
	else:
		offset = default_offset
	
func get_list_brush(list :Array) ->void:
	var min_pos :Vector2 = Vector2(INF,INF)
	var max_pos :Vector2 = Vector2(-INF,-INF)
	var min_border :Vector2
	var first_offset = null
	for i in list:
		get_brush(i)
		if first_offset == null:
			first_offset = offset
		if min_pos.x > i.position.x+border.position.x:
			min_pos.x = i.position.x+border.position.x
			min_border.x = border.position.x
		if min_pos.y > i.position.y+border.position.y:
			min_pos.y = i.position.y+border.position.y
			min_border.y = border.position.y
		max_pos.x = max(max_pos.x,i.position.x+border.end.x)
		max_pos.y = max(max_pos.y,i.position.y+border.end.y)
	offset = list[0].position - min_pos
	border = Rect2(-offset,max_pos-min_pos)

func get_continus_grid_pos(grid_pos :Vector2, size :Vector2) ->Array[Vector2]:
	var result :Array[Vector2] = [grid_last]
	var len :float = (grid_pos - grid_last).length()
	var step :float = min(size.x, size.y)
	var current :float = step
	while current < len:
		var p :float = current / len
		var r :Vector2 = (1 - p) * grid_last + p * grid_pos
		r.x = floor(r.x/grid.x)*grid.x
		r.y = floor(r.y/grid.y)*grid.y
		result.append(r)
		current += step
	result.append(grid_pos)
	return result
	
func add_child_copy(list :Array, pos :Vector2) ->void:
	var fpos :Vector2 = list[0].position
	var editor_owner :Node = get_tree().get_edited_scene_root()
	for i in list:
		i.position += -fpos + pos
		add_child(i, true)
		i.set_owner(editor_owner)
		set_children_owner(i,editor_owner)
		
func add_child_list(list :Array) ->void:
	var editor_owner :Node = get_tree().get_edited_scene_root()
	for i in list:
		add_child(i, true)
		i.set_owner(editor_owner)
		set_children_owner(i,editor_owner)
		
func remove_child_list(list :Array) ->void:
	for i in list:
		remove_child(i)
		
func set_children_owner(node :Node, new_onwer :Node) ->void:
	var children :Array = node.get_children()
	if children.is_empty():
		return
	for i in children:
		if i.owner == null:
			i.set_owner(new_onwer)
			set_children_owner(i,new_onwer)

func _brush_process(res :Resource, sel :Array, undo :EditorUndoRedoManager) ->void:
	var check :bool = false
	if res is PackedScene:
		var check_node: Node = res.instantiate()
		if check_node is CanvasItem:
			check = true
		check_node.queue_free()
	if !check && copy_list.is_empty():
		border = default_border
		offset = default_offset
		brush_last = null
	
	var pos :Vector2 = global_transform.affine_inverse() * get_global_mouse_position()
	
	var grid_pos :Vector2
	grid_pos.x = floor(pos.x/grid.x)*grid.x
	grid_pos.y = floor(pos.y/grid.y)*grid.y
	if (grid_last == null):
		grid_last = grid_pos
	
	# preview
	if preview:
		if copy_list.is_empty():
			if !preview_list.is_empty():
				for i in preview_list:
					if is_instance_valid(i):
						i.queue_free()
				preview_list.clear()
			if check:
				if preview_res != res:
					preview_res = res
					if is_instance_valid(preview_node):
						preview_node.queue_free()
					preview_node = res.instantiate()
					preview_node.name = "_Preview"
					add_child(preview_node)
				if !(brush_last is String) || brush_last != res:
					get_brush(preview_node)
					brush_last = res
				if is_instance_valid(preview_node):
					preview_node.position = grid_pos + offset
					preview_node.modulate.a = preview_alpha
					move_child(preview_node,get_child_count())
			else:
				free_preview()
		else:
			if is_instance_valid(preview_node):
				preview_node.queue_free()
				preview_res = null
			if preview_list.is_empty():
				for i in copy_list.size():
					var new :Node = copy_list[i].duplicate()
					new.name = "_Preview" + var_to_str(i)
					add_child(new)
					preview_list.append(new)
			if !(brush_last is Array):
				get_list_brush(copy_list)
				brush_last = copy_list
			var fpos :Vector2 = preview_list[0].position
			var child_count :int = get_child_count()
			for i in preview_list:
				i.position += -fpos + grid_pos + offset
				i.modulate.a = preview_alpha
				move_child(i,child_count)
	
	# paint
	if Input.is_mouse_button_pressed(paint_button) && !paint_restrict:
		if (!click_only && Input.is_key_pressed(click_restrict_key)) || (click_only && !Input.is_key_pressed(click_restrict_key)):
			paint_restrict = true
		if copy_list.is_empty():
			if check:
				if !preview && (!(brush_last is String) || brush_last != res):
					var temp :Node = res.instantiate()
					get_brush(temp)
					brush_last = res
					temp.queue_free()
				for c_pos in get_continus_grid_pos(grid_pos, border.size):
					var new :Node = res.instantiate()
					var new_pos :Vector2 = c_pos + offset
					var c1 :bool = new_pos.x + border.end.x <= mouse_last.x + border.position.x || new_pos.x + border.position.x >= mouse_last.x + border.end.x
					var c2 :bool = new_pos.y + border.end.y <= mouse_last.y + border.position.y || new_pos.y + border.position.y >= mouse_last.y + border.end.y
					if !(c1 || c2):
						new.queue_free()
					else:
						mouse_last = new_pos
						undo.create_action("brush2d_paint")
						undo.add_do_method(self, &"add_child", new, true)
						undo.add_do_method(new, &"set_owner", get_tree().get_edited_scene_root())
						undo.add_do_property(new, &"position", new_pos)
						undo.add_undo_method(self, &"remove_child", new)
						undo.commit_action()
		else:
			if !preview && !(brush_last is Array):
				get_list_brush(copy_list)
				brush_last = copy_list
			for c_pos in get_continus_grid_pos(grid_pos, border.size):
				var new_pos :Vector2 = c_pos + offset
				var c1 :bool = new_pos.x + border.end.x <= mouse_last.x + border.position.x || new_pos.x + border.position.x >= mouse_last.x + border.end.x
				var c2 :bool = new_pos.y + border.end.y <= mouse_last.y + border.position.y || new_pos.y + border.position.y >= mouse_last.y + border.end.y
				if c1 || c2:
					mouse_last = new_pos
					var new_list :Array = []
					for i in copy_list:
						new_list.append(i.duplicate())
					undo.create_action("brush2d_copy")
					undo.add_do_method(self, &"add_child_copy", new_list, new_pos)
					undo.add_undo_method(self, &"remove_child_list", new_list)
					undo.commit_action()
	else:
		mouse_last = Vector2(INF,INF)
		
	# erase
	if Input.is_mouse_button_pressed(erase_button) && !erase_restrict:
		if (!click_only && Input.is_key_pressed(click_restrict_key)) || (click_only && !Input.is_key_pressed(click_restrict_key)):
			erase_restrict = true
		var free_list :Array = []
		var gpos :Array[Vector2] = get_continus_grid_pos(grid_pos, grid)
		gpos.append(pos)
		for i in get_children():
			if i == preview_node || preview_list.has(i):
				continue
			get_brush(i)
			brush_last = null
			for cpos in gpos:
				var c1 :bool = cpos.x > i.position.x + border.position.x && cpos.x < i.position.x + border.end.x
				var c2 :bool = cpos.y > i.position.y + border.position.y && cpos.y < i.position.y + border.end.y
				if c1 && c2:
					free_list.append(i)
					break
		if !free_list.is_empty():
			var erase_list :Array = free_list.duplicate()
			undo.create_action("brush2d_erase")
			undo.add_do_method(self, &"remove_child_list", erase_list)
			undo.add_undo_method(self, &"add_child_list", erase_list)
			undo.commit_action()
			free_list.clear()
			
	# preview border
	if preview_border:
		preview_rect = Rect2(grid_pos+offset+border.position,border.size)
		queue_redraw()

	grid_last = grid_pos
	
func _copy_process(res :Resource, sel :Array, undo :EditorUndoRedoManager) ->void:
	# copy
	if Input.is_key_pressed(copy_key) && !copy_restrict:
		copy_restrict = true
		copy_list.clear()
		brush_last = null
		if !preview_list.is_empty():
			for i in preview_list:
				if is_instance_valid(i):
					i.queue_free()
			preview_list.clear()
		for i in sel:
			if i.has_method("_brush_process") || !i is CanvasItem:
				continue
			copy_list.append(i.duplicate())
	
	# cut
	if Input.is_key_pressed(cut_key) && !cut_restrict:
		cut_restrict = true
		copy_list.clear()
		brush_last = null
		if !preview_list.is_empty():
			for i in preview_list:
				if is_instance_valid(i):
					i.queue_free()
			preview_list.clear()
		var free_list :Array = []
		for i in sel:
			if i.has_method("_brush_process") || !i is CanvasItem:
				continue
			copy_list.append(i.duplicate())
			free_list.append(i)
		if !free_list.is_empty():
			var erase_list :Array = free_list.duplicate()
			undo.create_action("brush2d_erase")
			undo.add_do_method(self, &"remove_child_list", erase_list)
			undo.add_undo_method(self, &"add_child_list", erase_list)
			undo.commit_action()
			free_list.clear()
			
func free_preview() ->void:
	preview_res = null
	if is_instance_valid(preview_node):
		preview_node.queue_free()
	if !preview_list.is_empty():
		for i in preview_list:
			if is_instance_valid(i):
				i.queue_free()
		preview_list.clear()
		
func _draw() ->void:
	if !Engine.is_editor_hint() || !preview_border || !working:
		return
	var r :Rect2 = preview_rect
	r.position -= border_width * Vector2.ONE
	r.size += 2 * border_width * Vector2.ONE
	draw_rect(r,border_color,false,border_width)
	
func _process(_delta):
	if !Engine.is_editor_hint():
		return
		
	if paint_restrict && !Input.is_mouse_button_pressed(paint_button):
		paint_restrict = false
		
	if erase_restrict && !Input.is_mouse_button_pressed(erase_button):
		erase_restrict = false
		
	if copy_restrict && !Input.is_key_pressed(copy_key):
		copy_restrict = false
		
	if cut_restrict && !Input.is_key_pressed(cut_key):
		cut_restrict = false
		
	if working:
		working = false
		if !preview:
			free_preview()
		if !preview_border:
			queue_redraw()
		return
		
	free_preview()
	queue_redraw()
