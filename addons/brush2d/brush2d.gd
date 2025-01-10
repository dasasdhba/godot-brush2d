@tool
@icon("icon.png")
extends Node2D
class_name Brush2D

@export_category("Brush2D")
@export var grid: Vector2 = Vector2(32,32)
@export var default_border :Rect2 = Rect2(-16,-16,32,32)
@export var default_offset :Vector2 = Vector2(16,16)
@export var force_border :bool = false
@export var force_offset :bool = false

var preview :bool = true
var preview_alpha :float = 0.5
var preview_border :bool = true
var border_color :Color = Color(0.9,0.4,0.3,0.7)
var paint_color :Color = Color(1.0,1.0,1.0,0.2)
var erase_color :Color = Color(0.0,0.0,0.0,0.4)
var border_width :float = 2

const paint_button :int = MOUSE_BUTTON_LEFT
const erase_button :int = MOUSE_BUTTON_RIGHT
var copy_key :int = KEY_C
var cut_key :int = KEY_X

var border :Rect2
var offset :Vector2

var copy_list :Array = []
var copy_restrict :bool = false
var cut_restrict :bool = false

var preview_res :Resource = null
var preview_node :Node
var preview_list :Array = []
var preview_rect := Rect2(Vector2.ZERO, Vector2.ZERO)

var brush_last = null
var mouse_last := Vector2(INF, INF)
var grid_last = null

var working := false
var mode :int:
	get:
		return _mode
	set(value):
		if value != _mode:
			commit_paint_undo()
			commit_erase_undo()
			_mode = value

var _mode := 0

var undo :EditorUndoRedoManager

func clear_brush() ->void:
	border = default_border
	offset = default_offset

func get_brush(node :CanvasItem) ->void:
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
			var tr: Vector2 = Vector2(border.end.x, border.position.y).rotated(rotation)
			var bl: Vector2 = Vector2(border.position.x, border.end.y).rotated(rotation)
			var br: Vector2 = border.end.rotated(rotation)
			var xlist :Array = [tl.x, tr.x, bl.x, br.x]
			var ylist :Array = [tl.y, tr.y, bl.y, br.y]
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
	var min_pos :Vector2 = Vector2(INF, INF)
	var max_pos :Vector2 = Vector2(-INF, -INF)
	var min_border :Vector2
	var first_offset = null
	for i in list:
		if i is not CanvasItem:
			continue
		get_brush(i)
		if first_offset == null:
			first_offset = offset
		if min_pos.x > i.position.x + border.position.x:
			min_pos.x = i.position.x + border.position.x
			min_border.x = border.position.x
		if min_pos.y > i.position.y + border.position.y:
			min_pos.y = i.position.y + border.position.y
			min_border.y = border.position.y
		max_pos.x = max(max_pos.x, i.position.x + border.end.x)
		max_pos.y = max(max_pos.y, i.position.y + border.end.y)
	offset = list[0].position - min_pos
	border = Rect2(-offset,max_pos - min_pos)
	
func add_child_copy(list :Array, pos :Vector2) ->void:
	var fpos :Vector2 = list[0].position
	var editor_owner :Node = get_tree().get_edited_scene_root()
	for i in list:
		i.position += -fpos + pos
		add_child(i, true)
		i.set_owner(editor_owner)
		set_children_owner(i, editor_owner)

func add_child_erase(list :Array) ->void:
	var editor_owner :Node = get_tree().get_edited_scene_root()
	for i in list:
		add_child(i, true)
		i.visible = true
		i.set_owner(editor_owner)
		set_children_owner(i, editor_owner)
		
func add_child_list(list :Array) ->void:
	var editor_owner :Node = get_tree().get_edited_scene_root()
	for i in list:
		add_child(i, true)
		i.set_owner(editor_owner)
		set_children_owner(i, editor_owner)
		
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
			set_children_owner(i, new_onwer)

func preview_process(res :Resource, check :bool, grid_pos :Vector2) ->void:
	if copy_list.is_empty():
		free_preview_list()
		if check:
			if preview_res != res:
				preview_res = res
				if is_instance_valid(preview_node):
					preview_node.queue_free()
				preview_node = res.instantiate()
				preview_node.name = "_Preview"
				add_child(preview_node, false, INTERNAL_MODE_BACK)
			if !(brush_last is String) || brush_last != res:
				get_brush(preview_node)
				brush_last = res
			if is_instance_valid(preview_node):
				preview_node.position = grid_pos + offset
				preview_node.modulate.a = preview_alpha
		else:
			free_preview()
	else:
		free_preview_res()
		if preview_list.is_empty():
			for i in copy_list.size():
				var new :Node = copy_list[i].duplicate()
				new.name = "_Preview" + var_to_str(i)
				add_child(new, false, INTERNAL_MODE_BACK)
				preview_list.append(new)
		if !(brush_last is Array):
			get_list_brush(copy_list)
			brush_last = copy_list
		var fpos :Vector2 = preview_list[0].position
		for i in preview_list:
			i.position += -fpos + grid_pos + offset
			i.modulate.a = preview_alpha

func free_preview() ->void:
	free_preview_res()
	free_preview_list()
	free_preview_paint()

func free_preview_res() ->void:
	preview_res = null
	if is_instance_valid(preview_node):
		preview_node.queue_free()

func free_preview_list() ->void:
	for i in preview_list:
		if is_instance_valid(i):
			i.queue_free()
	preview_list.clear()

func free_preview_paint() ->void:
	for i in preview_paint_pool:
		if is_instance_valid(i):
			i.queue_free()
			
	preview_paint_pool.clear()

var preview_paint_pool :Array = []

func add_preview_paint(pos :Vector2) ->void:
	if copy_list.is_empty():
		var new :Node = paint_res.instantiate()
		new.name = "_PreviewPaint"
		new.position = pos
		new.modulate.a = preview_alpha
		preview_paint_pool.append(new)
		add_child(new, false, INTERNAL_MODE_BACK)
	else:
		var fpos :Vector2 = copy_list[0].position
		var r := Node2D.new()
		r.position = pos
		for s in copy_list:
			var i :Node = s.duplicate()
			i.position += -fpos
			i.name = "_PreviewCopy" + var_to_str(i)
			i.modulate.a = preview_alpha
			r.add_child(i)
		preview_paint_pool.append(r)
		add_child(r, false, INTERNAL_MODE_BACK)

class PaintUndoData:
	extends RefCounted
	var new: Node
	var new_pos :Vector2

class CopyUndoData:
	extends RefCounted
	var new_list: Array
	var new_pos :Vector2

var paint_undo_arr :Array = []

func is_paint_pos_valid_in_arr(arr :Array[Vector2], pos :Vector2) ->bool:
	for vec in arr:
		if !is_pos_out_border(pos, vec):
			return false
	return true

func is_paint_pos_valid(pos :Vector2) ->bool:
	for data in paint_undo_arr:
		if !is_pos_out_border(pos, data.new_pos):
			return false
	return true

func stack_paint_undo(res :Resource, new_pos: Vector2) ->void:
	var new = res.instantiate()
	var undo_data = PaintUndoData.new()
	undo_data.new = new
	undo_data.new_pos = new_pos
	paint_undo_arr.append(undo_data)
	if preview:
		add_preview_paint(new_pos)

func stack_copy_undo(new_pos: Vector2) ->void:
	var new_list = []
	for i in copy_list:
		new_list.append(i.duplicate())
	var undo_data = CopyUndoData.new()
	undo_data.new_list = new_list
	undo_data.new_pos = new_pos
	paint_undo_arr.append(undo_data)
	if preview:
		add_preview_paint(new_pos)

func commit_paint_undo() ->void:
	undo.create_action("brush2d_paint")
	if mode == 0:
		for data in paint_undo_arr:
			if data is PaintUndoData:
				undo.add_do_method(self, &"add_child", data.new, true)
				undo.add_do_method(data.new, &"set_owner", get_tree().get_edited_scene_root())
				undo.add_do_property(data.new, &"position", data.new_pos)
				undo.add_undo_method(self, &"remove_child", data.new)
			elif data is CopyUndoData:
				undo.add_do_method(self, &"add_child_copy", data.new_list, data.new_pos)
				undo.add_undo_method(self, &"remove_child_list", data.new_list)
	else:
		for p in paint_pos_arr:
			if copy_list.is_empty():
				var new :Node = paint_res.instantiate()
				undo.add_do_method(self, &"add_child", new, true)
				undo.add_do_method(new, &"set_owner", get_tree().get_edited_scene_root())
				undo.add_do_property(new, &"position", p + offset)
				undo.add_undo_method(self, &"remove_child", new)
			else:
				var new_list = []
				for i in copy_list:
					new_list.append(i.duplicate())
				undo.add_do_method(self, &"add_child_copy", new_list, p + offset)
				undo.add_undo_method(self, &"remove_child_list", new_list)
	undo.commit_action()
	paint_undo_arr.clear()
	paint_pos_arr.clear()
	free_preview_paint()

var erase_undo_arr :Array = []

func stack_erase_undo(list :Array) ->void:
	erase_undo_arr.append(list)

func commit_erase_undo() ->void:
	undo.create_action("brush2d_erase")
	if mode == 0:
		for data in erase_undo_arr:
			undo.add_do_method(self, &"remove_child_list", data)
			undo.add_undo_method(self, &"add_child_erase", data)
	else:
		var free_list :Array = []
		for i in get_children():
			if i is not CanvasItem || !i.visible:
				continue
			get_brush(i)
			brush_last = null
			for cpos in erase_pos_arr:
				if !is_pos_out_border(cpos + offset, i.position):
					free_list.append(i)
					break
		if !free_list.is_empty():
			var erase_list :Array = free_list.duplicate()
			undo.add_do_method(self, &"remove_child_list", erase_list)
			undo.add_undo_method(self, &"add_child_list", erase_list)
			free_list.clear()
	undo.commit_action()
	erase_undo_arr.clear()
	erase_pos_arr.clear()

var paint_start = null
var paint_pos_arr :Array[Vector2] = []
var paint_res :Resource = null

func get_continuous_grid_pos(grid_pos :Vector2, size :Vector2) ->Array[Vector2]:
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

static func bresenham(p0 :Vector2i, p1 :Vector2i) ->Array[Vector2i]:
	var result :Array[Vector2i] = []
	var x0 := p0.x
	var y0 := p0.y
	var x1 := p1.x
	var y1 := p1.y
	var steep :bool = abs(y1 - y0) > abs(x1 - x0)
	if steep:
		var temp :int

		temp = x0
		x0 = y0
		y0 = temp

		temp = x1
		x1 = y1
		y1 = temp

	if x0 > x1:
		var temp :int

		temp = x0
		x0 = x1
		x1 = temp

		temp = y0
		y0 = y1
		y1 = temp

	var delta_x := x1 - x0
	var delta_y :int = abs(y1 - y0)
	var error :float = 0.0
	var delta_error :float = float(delta_y) / delta_x
	var yk := y0

	var y_step := 1 if y0 < y1 else -1

	for xk in range(x0, x1 + 1):
		if steep:
			result.append(Vector2i(yk, xk))
		else:
			result.append(Vector2i(xk, yk))

		error = error + delta_error
		if error >= 0.5:
			yk = yk + y_step
			error = error - 1.0
	return result

func get_line_pos(p1 :Vector2, p2 :Vector2) ->Array[Vector2]:
	var size = border.size
	size.x = ceil(size.x/grid.x)*grid.x
	size.y = ceil(size.y/grid.y)*grid.y

	var d := p2 - p1
	var r := Vector2i(floor(d.x/size.x), floor(d.y/size.y))
	if Input.is_key_pressed(KEY_SHIFT):
		var s :Vector2 = r
		var a = round(s.angle() / (PI / 4.0)) * (PI / 4.0)
		var f := Vector2.RIGHT.rotated(a)
		var l = s.dot(f)
		f *= l
		r = f
	var points := bresenham(Vector2i.ZERO, r)
	var result :Array[Vector2] = []
	for p in points:
		result.append(p1 + Vector2(size.x * p.x, size.y * p.y))
	return result

func get_rect_pos(p1 :Vector2, p2 :Vector2) ->Array[Vector2]:
	if Input.is_key_pressed(KEY_SHIFT):
		var dx = p2.x - p1.x
		var dy = p2.y - p1.y
		var m = min(abs(dx), abs(dy))
		p2.x = p1.x + m * sign(dx)
		p2.y = p1.y + m * sign(dy)

	var size = border.size
	size.x = ceil(size.x/grid.x)*grid.x * sign(p2.x - p1.x)
	size.y = ceil(size.y/grid.y)*grid.y * sign(p2.y - p1.y)

	var result :Array[Vector2] = []
	var x := p1.x
	while (p1.x < p2.x && x <= p2.x) || (p1.x > p2.x && x >= p2.x):
		var y := p1.y
		while (p1.y < p2.y && y <= p2.y) || (p1.y > p2.y && y >= p2.y):
			var r := Vector2(x, y)
			result.append(r)
			y += size.y
		x += size.x
	if result.is_empty():
		result.append(p1)
	return result

func is_pos_out_border(p1 :Vector2, p2 :Vector2) ->bool:
	var c1 :bool = p1.x + border.end.x <= p2.x + border.position.x || p1.x + border.position.x >= p2.x + border.end.x
	var c2 :bool = p1.y + border.end.y <= p2.y + border.position.y || p1.y + border.position.y >= p2.y + border.end.y
	return c1 || c2

func paint_process(res :Resource, grid_pos :Vector2) ->void:
	paint_res = res
	if mode == 0:
		for c_pos in get_continuous_grid_pos(grid_pos, grid):
			var new_pos :Vector2 = c_pos + offset
			if is_paint_pos_valid(new_pos):
				if copy_list.is_empty():
					stack_paint_undo(res, new_pos)
				else:
					stack_copy_undo(new_pos)
	else:
		if paint_start == null:
			paint_start = grid_pos
		if is_pos_out_border(grid_pos, mouse_last):
			mouse_last = grid_pos
			paint_pos_arr.clear()
			if mode == 1:
				paint_pos_arr = get_line_pos(paint_start, grid_pos)
			else:
				paint_pos_arr = get_rect_pos(paint_start, grid_pos)

var erase_start = null
var erase_last := Vector2(INF,INF)
var erase_pos_arr :Array[Vector2] = []

func erase_process(pos :Vector2, grid_pos :Vector2) ->void:
	if mode == 0:
		var free_list :Array = []
		var gpos :Array[Vector2] = get_continuous_grid_pos(grid_pos, grid)
		gpos.append(pos)
		for i in get_children():
			if i is not CanvasItem || !i.visible:
				continue
			get_brush(i)
			brush_last = null
			for cpos in gpos:
				if !is_pos_out_border(cpos, i.position):
					i.visible = false
					free_list.append(i)
					break
		if !free_list.is_empty():
			var erase_list :Array = free_list.duplicate()
			stack_erase_undo(erase_list)
			free_list.clear()
	else:
		clear_brush()
		if erase_start == null:
			erase_start = grid_pos
		if is_pos_out_border(grid_pos, erase_last):
			erase_last = grid_pos
			erase_pos_arr.clear()
			if mode == 1:
				erase_pos_arr = get_line_pos(erase_start, grid_pos)
			else:
				erase_pos_arr = get_rect_pos(erase_start, grid_pos)
			

func _brush_process(res :Resource) ->void:
	var check := false
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
		preview_process(res, check, grid_pos)
	else:
		free_preview()
	
	# paint
	if Input.is_mouse_button_pressed(paint_button):
		if copy_list.is_empty():
			if check:
				if !preview && (!(brush_last is String) || brush_last != res):
					var temp :Node = res.instantiate()
					get_brush(temp)
					brush_last = res
					temp.queue_free()
				paint_process(res, grid_pos)
		else:
			if !preview && !(brush_last is Array):
				get_list_brush(copy_list)
				brush_last = copy_list
			paint_process(res, grid_pos)
	else:
		mouse_last = Vector2(INF,INF)
		paint_start = null
		
	# erase
	if Input.is_mouse_button_pressed(erase_button):
		erase_process(pos, grid_pos)
	else:
		erase_last = Vector2(INF,INF)
		erase_start = null
			
	# preview border
	if preview_border:
		preview_rect = Rect2(grid_pos + offset + border.position, border.size)

	# submit undo
	if !Input.is_mouse_button_pressed(paint_button):
		commit_paint_undo()

	if !Input.is_mouse_button_pressed(erase_button):
		commit_erase_undo()

	grid_last = grid_pos
	working = true
	queue_redraw()
	
func _copy_process(sel :Array) ->void:
	# copy
	if Input.is_key_pressed(copy_key) && !copy_restrict:
		copy_restrict = true
		copy_list.clear()
		brush_last = null
		free_preview_list()
		for i in sel:
			if i.has_method("_brush_process") || !i is CanvasItem:
				continue
			copy_list.append(i.duplicate())
	
	# cut
	if Input.is_key_pressed(cut_key) && !cut_restrict:
		cut_restrict = true
		copy_list.clear()
		brush_last = null
		free_preview_list()
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

	# clear buffer
	if copy_restrict && !Input.is_key_pressed(copy_key):
		copy_restrict = false
		
	if cut_restrict && !Input.is_key_pressed(cut_key):
		cut_restrict = false

class BlockDraw:
	extends Node2D

	func _draw() ->void:
		var b := get_parent()
		if !b.working:
			return

		for p in b.paint_pos_arr:
			var pr := Rect2(p + b.offset + b.border.position, b.preview_rect.size)
			draw_rect(pr, b.paint_color)

		for p in b.erase_pos_arr:
			var er := Rect2(p + b.offset + b.border.position, b.border.size)
			draw_rect(er, b.erase_color)

	func _process(delta: float) -> void:
		queue_redraw()

const BLOCK_DRAW_NAME :String = "__Brush2DInternalBlockDraw"

func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		return

	if has_node(BLOCK_DRAW_NAME):
		get_node(BLOCK_DRAW_NAME).queue_free()
	
	var br :BlockDraw = BlockDraw.new()
	br.name = BLOCK_DRAW_NAME
	br.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	add_child(br, false, INTERNAL_MODE_BACK)

func _draw() ->void:
	if !Engine.is_editor_hint() || !preview_border || !working:
		return
	
	var r :Rect2 = preview_rect
	r.position -= border_width * Vector2.ONE
	r.size += 2 * border_width * Vector2.ONE
	draw_rect(r, border_color, false, border_width)

func clear_working() ->void:
	working = false
	free_preview()
	queue_redraw()