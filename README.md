# Introduction

This is a simple addon for **Godot-v4.6.x** that can help you to easily place **PackedScene** in **2D panel**. For older godot supports, you may check other branch.

**Current version: 0.9.0**

## Usage

Here is a simple instruction:

1. Add a `Brush2D` node in the editor scene tree and select it or its child.
2. Click the **Enable** button(or use shortcut `A` by default, you may change this in `tool_button.tscn`) to switch to the **Paint Mode**.
3. Select a **PackedScene** in the filesystem dock.
4. Now you can simply use the mouse **left button** to paint or **right button** to erase.

To customize the recognized size of a scene, you may open bottom `Brush2D` dock and change the `Rect` to cover your scene. There is also an `offset` parameter, which allows to shift the final placement.

Other features:

1. Paint/Rectangle/Line tools, you can hold `Shift` to limit the paint shape.
2. You can select some children of `Brush2D` node, then press `C` or `X` by default to **copy** or **cut** them. Note: `offset` will not work in copy mode.
3. Some editor settings that manage shortcut and preview behavior.

## Known issue

Since Godot does not expose `duplicate_from_editor`, copy mode may not work as expected, e.g., it may wrongly copy internal nodes, or lose some properties & signal connections.
