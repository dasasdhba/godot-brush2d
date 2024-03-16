This is a simple addon for **Godot(*v4.2.1 stable*)** that can help you to easily place ***PackedScene*** in **2D panel**.

**Current version: 0.7.0**

## Usage

Here is a simple instruction:

1. Add a ***Brush2D*** node in the editor scene tree and select it or its child.
2. Click the **Enable** button(or use shortcut `A` by default, you may change this in `tool_button.res`) to switch to the **Paint Mode**.
3. Select a ***PackedScene*** in the filesystem dock.
4. Now you can simply use the mouse **left button** to paint or **right button** to erase.

Additionally, there are also some other features:

1. Hold `Shift` (by default) so that you can paint or erase continuously. You can also switch the editor setting `brush_2d->control->restrict` to change this behavior.
2. If the **Paint Mode** is not enabled, you can press `C`(by default) to copy or `X`(by default) to cut the selected items. To clear the copied items, simply select nothing and press `C` again.
3. The ***grid*** is independent.
3. See **Editor Setting** for more options.
4. It's almost impossible to calculate the size of a ***PackedScene*** node, so you have to set it up manually. If the ***PackedScene*** node has a child ***BrushParam***, then the addon will use its parameters as the "size" of this node, or the addon will use the ***Default Border*** and ***Default Offset*** parameters.

## Known Issue

1. Currently copy a node will also copy its **Internal Children**(i.e. some internal tool children), which is not expected.
2. This is a pretty old plugin I've ever made, thus the code and performance may not very good.
