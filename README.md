This is a simple addon for **Godot(*v3.5.0 stable*)** that can help you to easily place ***PackedScene*** in **2D panel**.

**Current version: 0.5.6**

# Usage

Here is a simple instruction:

1. Add a ***Brush2D*** node in the editor scene tree and select it or its child.
2. Click the **Enable** button(or use shortcut `A` by default) to switch to the **Paint Mode**.
3. Select a ***PackedScene*** in the filesystem dock.
4. Now you can simply use the mouse **left button** to paint or **right button** to erase.

Additionally, there are also some other features:

1. Hold `Shift` (by default) so that you can paint or erase continuously. You can also switch the ***Click Only*** parameter to change this behavior.
2. If the **Paint Mode** is not enabled, you can press `C`(by default) to copy or `X`(by default) to cut the selected items. To clear the copied items, simply select nothing and press `C` again.
3. The ***grid*** is independent.
4. It's almost impossible to calculate the size of a ***PackedScene*** node, so you have to set it up manually. if the ***PackedScene*** node has the exported variables ***brush_border***(Rect2) and ***brush_offset***(Vector2) ,then the addon will use them as the "size" of this node, or the addon will use the ***Default Border*** and ***Default Offset*** parameters.

# Special Thanks

Get the selected items path in the filesystem dock: https://github.com/godotengine/godot-proposals/issues/3505

Get the main screen panel: https://github.com/godotengine/godot-proposals/issues/2081

Get the editor viewport2d: https://github.com/godotengine/godot-proposals/issues/1302
