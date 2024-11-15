@tool
extends EditorPlugin

var button :HBoxContainer = null

var brush :Brush2D:
	get:
		return _brush
	set(value):
		if value == null && _brush != null:
			_brush.clear_working()
		_brush = value

var _brush :Brush2D = null

const setting_key = "brush_2d";
const editor_copy_key = setting_key + "/control/copy_key"
const editor_cut_key = setting_key + "/control/cut_key"

const editor_preview_enable = setting_key + "/preview/enable"
const editor_preview_alpha = setting_key + "/preview/alpha"
const editor_preview_border = setting_key + "/preview/draw_border"
const editor_preview_border_width = setting_key + "/preview/border_width"
const editor_preview_border_color = setting_key + "/preview/border_color"
const editor_preview_paint_color = setting_key + "/preview/paint_color"
const editor_preview_erase_color = setting_key + "/preview/erase_color"

func try_add_button() ->void:
	if button == null:
		button = load("res://addons/brush2d/tool_button.tscn").instantiate()
		var button_node :Button = button.get_node("ToolButton")
		if !button_node.is_connected("toggled",select_update):
			button_node.connect("toggled",select_update)

func button_check() ->bool:
	return button != null && button.visible && button.get_node("ToolButton").button_pressed

func select_update(_pressed :bool = false) ->void:
	var select := EditorInterface.get_selection()
	if brush != null && button_check():
		select.clear()
		select.add_node(brush)

func add_editor_setting(key :String, hint :int, default) ->void:
	var setting := EditorInterface.get_editor_settings()
	if setting.has_setting(key):
		return
	setting.set_setting(key, default)
	setting.set_initial_value(key, default, false)
	setting.add_property_info({
		"name" : key,
		"type" : typeof(default),
		"hint" : hint
	})

func remove_editor_setting(key :String) ->void:
	var setting := EditorInterface.get_editor_settings()
	if setting.has_setting(key):
		setting.erase(key)

func apply_settings(p_brush :Brush2D) ->void:
	var setting := EditorInterface.get_editor_settings()
	p_brush.undo = get_undo_redo()
	p_brush.mode = button.get_mode()
	p_brush.copy_key = setting.get_setting(editor_copy_key)
	p_brush.cut_key = setting.get_setting(editor_cut_key)
	p_brush.preview = setting.get_setting(editor_preview_enable)
	p_brush.preview_alpha = setting.get_setting(editor_preview_alpha)
	p_brush.preview_border = setting.get_setting(editor_preview_border)
	p_brush.border_color = setting.get_setting(editor_preview_border_color)
	p_brush.border_width = setting.get_setting(editor_preview_border_width)
	p_brush.paint_color = setting.get_setting(editor_preview_paint_color)
	p_brush.erase_color = setting.get_setting(editor_preview_erase_color)

func _enter_tree() ->void:
	try_add_button()
	add_editor_setting(editor_copy_key, PROPERTY_HINT_NONE, KEY_C)
	add_editor_setting(editor_cut_key, PROPERTY_HINT_NONE, KEY_X)
	add_editor_setting(editor_preview_enable, PROPERTY_HINT_NONE, true)
	add_editor_setting(editor_preview_alpha, PROPERTY_HINT_NONE, 0.5)
	add_editor_setting(editor_preview_border, PROPERTY_HINT_NONE, true)
	add_editor_setting(editor_preview_border_width, PROPERTY_HINT_NONE, 2)
	add_editor_setting(editor_preview_border_color, PROPERTY_HINT_NONE, Color(0.9,0.4,0.3,0.7))
	add_editor_setting(editor_preview_paint_color, PROPERTY_HINT_NONE, Color(1.0,1.0,1.0,0.2))
	add_editor_setting(editor_preview_erase_color, PROPERTY_HINT_NONE, Color(0.0,0.0,0.0,0.4))

func _exit_tree() ->void:
	if is_instance_valid(button):
		button.queue_free()
	remove_editor_setting(editor_copy_key)
	remove_editor_setting(editor_cut_key)
	remove_editor_setting(editor_preview_alpha)
	remove_editor_setting(editor_preview_border)
	remove_editor_setting(editor_preview_border_width)
	remove_editor_setting(editor_preview_border_color)
	remove_editor_setting(editor_preview_paint_color)
	remove_editor_setting(editor_preview_erase_color)


func _handles(object :Object) ->bool:
	brush = get_brush2d(object)
	return brush != null
		
func _forward_canvas_gui_input(event :InputEvent) ->bool:
	plugin_process()

	if !button_check():
		return false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT || event.button_index == MOUSE_BUTTON_RIGHT:
			return true
	return false

func plugin_process() ->void:
	try_add_button()

	var path := EditorInterface.get_selected_paths();
	var res :Resource = null
	if !path.is_empty() && FileAccess.file_exists(path[0]):
		res = load(path[0])
	
	if brush != null:
		if !button.visible:
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, button)
			button.visible = true
			select_update()

		apply_settings(brush)
		if button_check():
			brush._brush_process(res)
		else:
			brush.clear_working()
	elif button.visible:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, button)
		button.visible = false

var sel :Array = []

func _process(delta: float) -> void:
	sel = EditorInterface.get_selection().get_selected_nodes()
	if sel.is_empty():
		return
	
	brush = get_brush2d(sel[0])
	if brush != null:
		if !button.visible:
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, button)
			button.visible = true
			select_update()

		apply_settings(brush)
		brush._copy_process(sel)
	elif button.visible:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, button)
		button.visible = false

static func get_brush2d(object :Object) ->Object:
	if !object.has_method("get_parent"):
		return null
	if object is Brush2D:
		return object
	var i :Node = object.get_parent()
	var root :Node = object.get_tree().get_edited_scene_root().get_parent()
	while i != root:
		if i is Brush2D:
			return i
		i = i.get_parent()
	return null
