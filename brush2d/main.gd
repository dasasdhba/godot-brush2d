@tool
extends EditorPlugin

var button :HBoxContainer = null
var viewport :Viewport = null
var brush :Brush2D = null
var mouse_check_delay :bool = false

const setting_key = "brush_2d";
const editor_copy_key = setting_key + "/control/copy_key"
const editor_cut_key = setting_key + "/control/cut_key"
const editor_restrict_key = setting_key + "/control/switch_restrict_key"
const editor_restrict_mode = setting_key +"/control/restrict"

const editor_preview_enable = setting_key + "/preview/enable"
const editor_preview_alpha = setting_key + "/preview/alpha"
const editor_preview_border = setting_key + "/preview/draw_border"
const editor_preview_border_color = setting_key + "/preview/border_color"
const editor_preview_border_width = setting_key + "/preview/border_width"

const view_margin_top = 20
const view_margin_bottom = 16

func button_check() ->bool:
	return button != null && button.visible && button.get_node("ToolButton").button_pressed
	
func popup_check() ->bool:
	for i in get_editor_interface().get_base_control().get_children():
		if i is Window && i.visible:
			return true
	return false

func mouse_check() ->bool:
	var mouse_click :bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) || Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if mouse_check_delay:
		if mouse_click:
			return false
		mouse_check_delay = false
	var v2d :Viewport = EditorInterface.get_editor_viewport_2d()
	var canvas_pos :Vector2 = Vector2.ZERO
	var c :Node = v2d.get_parent()
	while c != null && c is Control:
		canvas_pos += c.position
		c = c.get_parent()
	var canvas_rect :Rect2 = Rect2(canvas_pos + view_margin_top * Vector2.ONE, v2d.get_parent().size - (view_margin_top + view_margin_bottom) * Vector2.ONE)
	if viewport == null:
		viewport = find_viewport_2d(self)
	var mouse_pos :Vector2 = viewport.get_mouse_position()
	var result :bool = canvas_rect.has_point(mouse_pos)
	if !result && mouse_click:
		mouse_check_delay = true
	return result

func select_update(_pressed :bool = false) ->void:
	var select :EditorSelection = EditorInterface.get_selection()
	if brush != null:
		select.clear()
		select.add_node(brush)

func add_editor_setting(key :String, hint :int, default) ->void:
	var setting :EditorSettings = EditorInterface.get_editor_settings()
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
	var setting :EditorSettings = EditorInterface.get_editor_settings()
	if setting.has_setting(key):
		setting.erase(key)

func apply_settings(brush :Brush2D) ->void:
	var setting :EditorSettings = EditorInterface.get_editor_settings()
	brush.copy_key = setting.get_setting(editor_copy_key)
	brush.cut_key = setting.get_setting(editor_cut_key)
	brush.click_restrict_key = setting.get_setting(editor_restrict_key)
	brush.click_only = setting.get_setting(editor_restrict_mode)
	brush.preview = setting.get_setting(editor_preview_enable)
	brush.preview_alpha = setting.get_setting(editor_preview_alpha)
	brush.preview_border = setting.get_setting(editor_preview_border)
	brush.border_color = setting.get_setting(editor_preview_border_color)
	brush.border_width = setting.get_setting(editor_preview_border_width)

func add_button() ->void:
	if button == null:
		button = load("res://addons/brush2d/tool_button.res").instantiate()
		var button_node :Button = button.get_node("ToolButton")
		if !button_node.is_connected("toggled",select_update):
			button_node.connect("toggled",select_update)

func _handles(object :Object) ->bool:
	if !button_check():
		return false
	return get_brush2d(object) != null
		
func _forward_canvas_gui_input(event :InputEvent) ->bool:
	if !button_check():
		return false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT || event.button_index == MOUSE_BUTTON_RIGHT:
			return true
	return false
	
func _enter_tree() ->void:
	add_button()
	add_editor_setting(editor_copy_key, PROPERTY_HINT_NONE, KEY_C)
	add_editor_setting(editor_cut_key, PROPERTY_HINT_NONE, KEY_X)
	add_editor_setting(editor_restrict_key, PROPERTY_HINT_NONE, KEY_SHIFT)
	add_editor_setting(editor_restrict_mode, PROPERTY_HINT_NONE, true)
	add_editor_setting(editor_preview_enable, PROPERTY_HINT_NONE, true)
	add_editor_setting(editor_preview_alpha, PROPERTY_HINT_NONE, 0.5)
	add_editor_setting(editor_preview_border, PROPERTY_HINT_NONE, true)
	add_editor_setting(editor_preview_border_color, PROPERTY_HINT_NONE, Color(0.9,0.4,0.3,0.7))
	add_editor_setting(editor_preview_border_width, PROPERTY_HINT_NONE, 2)

func _exit_tree() ->void:
	if is_instance_valid(button):
		button.queue_free()
	remove_editor_setting(editor_copy_key)
	remove_editor_setting(editor_cut_key)
	remove_editor_setting(editor_restrict_key)
	remove_editor_setting(editor_restrict_mode)
	remove_editor_setting(editor_preview_enable)
	remove_editor_setting(editor_preview_alpha)
	remove_editor_setting(editor_preview_border)
	remove_editor_setting(editor_preview_border_color)
	remove_editor_setting(editor_preview_border_width)

func _process(_delta) ->void:
	add_button()
	var path :Array = EditorInterface.get_selected_paths();
	var res :Resource = null
	if !path.is_empty() && FileAccess.file_exists(path.front()):
		res = load(path.front())
	brush = null
	var sel :Array = []
	if is_canvas_editor(self):
		sel = get_editor_interface().get_selection().get_selected_nodes()
		for i in sel:
			var b :Brush2D = get_brush2d(i)
			if b != null:
				brush = b
				break
	
	if brush != null:
		if !button.visible:
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU,button)
			button.visible = true
			select_update()
		if !popup_check():
			apply_settings(brush)
			brush._copy_process(res,sel,get_undo_redo())
			if button_check() && mouse_check():
				brush._brush_process(res,sel,get_undo_redo())
				brush.working = true
	elif button.visible:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU,button)
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

static func find_viewport_2d(plugin :EditorPlugin) ->Node:
	var k :Node = plugin.get_editor_interface().get_editor_main_screen()
	while k != null:
		if k is Viewport:
			return k
		k = k.get_parent()
	return null

static func is_canvas_editor(plugin :EditorPlugin) ->bool:
	return plugin.get_editor_interface().get_editor_main_screen().get_child(0).visible
