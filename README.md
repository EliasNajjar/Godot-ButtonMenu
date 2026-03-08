# Godot-ButtonMenu

A lightweight Godot node that handles keyboard and gamepad focus navigation across a 2D grid of buttons - no manual focus neighbour setup required.

## Overview

`ButtonMenu' is a `Control` node that treats its children as rows and their children as columns, forming a navigable 2D grid. Navigation is driven by the built-in `ui_left`, `ui_right`, `ui_up`, and `ui_down` input actions, so it works out of the box with both keyboard and gamepad input.

Filler nodes (any non-`BaseButton` child) can be placed inside rows to offset columns, allowing non-rectangular layouts.

## Installation

1. Copy `button_menu.gd` into your project.
2. The `ButtonMenu` class will be available automatically via Godot's class system — no plugin setup required.

## Setup

Structure your scene tree with `ButtonMenu` as the root, a node per row as its children, and `BaseButton`-derived nodes (e.g. `Button`, `TextureButton`) as the row's children:

```
ButtonMenu
├── HBoxContainer  (row 0)
│   ├── Button     (0, 0)
│   └── Button     (0, 1)
├── HBoxContainer  (row 1)
│   ├── Button     (1, 0)
│   ├── Button     (1, 1)
│   └── Button     (1, 2)
└── HBoxContainer  (row 2)
    ├── Button     (2, 0)
    └── Button     (2, 1)
```

To offset a column, place a plain `Node` (or any non-`BaseButton` node) as a filler in that slot:

```
ButtonMenu
├── HBoxContainer  (row 0)
│   ├── Node       (filler)
│   └── Button     (0, 1)
├── HBoxContainer  (row 1)
│   ├── Button     (1, 0)
│   ├── Button     (1, 1)
│   └── Button     (1, 2)
└── HBoxContainer  (row 2)
    ├── Button     (2, 0)
    └── Button     (2, 1)
```