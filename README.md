# Introduction

This is a simple addon for **Godot-v4.3.0-stable** that can help you to easily place **PackedScene** in **2D panel**.

**Current version: 0.8.0**

## Usage

Here is a simple instruction:

1. Add a `Brush2D` node in the editor scene tree and select it or its child.
2. Click the **Enable** button(or use shortcut `A` by default, you may change this in `tool_button.tscn`) to switch to the **Paint Mode**.
3. Select a **PackedScene** in the filesystem dock.
4. Now you can simply use the mouse **left button** to paint or **right button** to erase.

Other features:

1. Paint/Rectangle/Line tools.
2. You can select some children of `Brush2D` node, then press `C` or `X` by default to **copy** or **cut** them. 
3. Some editor settings that manage shortcut and preview behavior.

## Known Issue

1. Does not work in filesystem dock split mode, will be fixed in 4.3.1, see [this](https://github.com/godotengine/godot/pull/94703) for details. Alternately, you can still use the copy feature to use this plugin.
2. Line tool does not work as pixel perfect. (I don't exactly know how to implement this.)
