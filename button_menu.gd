## Manages keyboard/gamepad focus navigation across a 2D grid of [BaseButton] nodes.
##
## Arrange child nodes in rows, with buttons as their children, to form a 2D navigable grid.
## Filler (non-[BaseButton]) nodes can be used to offset columns within a row.[br]
## [br]
## Example layout:
## [codeblock]
## ┖╴ButtonMenu
##     ┠╴Node # filler
##     ┃  ┖╴Button
##     ┠╴Node
##     ┃  ┠╴Button
##     ┃  ┠╴Button
##     ┃  ┖╴Button
##     ┖╴Node
##        ┠╴Button
##        ┠╴Node # filler
##        ┠╴Button
##        ┖╴Button
## [/codeblock]
## Navigate between buttons using the [code]ui_left[/code], [code]ui_right[/code],
## [code]ui_up[/code], and [code]ui_down[/code] input actions.
class_name ButtonMenu extends Control

## The button that receives focus when the scene is ready.[br]
## [br]
## If unset, no button receives focus automatically.
@export var starting_focus: BaseButton

## If [code]true[/code], navigating past the edge of a row or column wraps around to the opposite side.
@export var wrap_navigation: bool = true

## If [code]true[/code], filler slots are skipped entirely when navigating.[br]
## [br]
## If [code]false[/code], moving onto a filler slot instead searches the nearest row
## (up or down) at the same column for a valid button, without wrapping.
@export var skip_empty: bool = false

var selected: Vector2i

func _ready() -> void:
	if starting_focus:
		starting_focus.grab_focus()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_left"):
		move_focus(Vector2i(0, -1))
	if Input.is_action_just_pressed("ui_right"):
		move_focus(Vector2i(0, 1))
	if Input.is_action_just_pressed("ui_up"):
		move_focus(Vector2i(-1, 0))
	if Input.is_action_just_pressed("ui_down"):
		move_focus(Vector2i(1, 0))


## Returns the [BaseButton] at grid position [param pos], or [code]null[/code] if the slot is empty or occupied by a filler node.
func get_button_at(pos: Vector2i) -> BaseButton:
	var row_count := get_child_count()
	if pos.x < 0 or pos.x >= row_count:
		return null
	var row := get_child(pos.x)
	var col_count := row.get_child_count()
	if pos.y < 0 or pos.y >= col_count:
		return null
	var node := row.get_child(pos.y)
	if node is BaseButton:
		return node
	return null

## Moves focus one step in [param direction] and transfers UI focus to the button found there.[br]
## [br]
## [param direction] should be one of the four unit [Vector2i] values:
## [code](0, -1)[/code] for left, [code](0, 1)[/code] for right,
## [code](-1, 0)[/code] for up, or [code](1, 0)[/code] for down.[br]
## [br]
## Does nothing if no [BaseButton] in this [ButtonMenu] currently holds focus.
## The exact movement behaviour depends on [member wrap_navigation] and [member skip_empty].
func move_focus(direction: Vector2i) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if not focus:
		return

	# sync selected to actual focus owner if it has drifted
	if get_button_at(selected) != focus:
		var found := false
		for r in get_child_count():
			for c in get_child(r).get_child_count():
				if get_button_at(Vector2i(r, c)) == focus:
					selected = Vector2i(r, c)
					found = true
					break
			if found:
				break
		if not found:
			return  # focused node is not inside this ButtonMenu

	var row_count := get_child_count()
	var next := selected + direction

	# horizontal movement
	if direction.y != 0:
		var col_count := get_child(selected.x).get_child_count()

		if skip_empty:
			# walk in the given direction, wrapping if enabled, until we find a BaseButton
			var steps := 0
			var candidate := next
			while steps < col_count:
				if wrap_navigation:
					candidate.y = posmod(candidate.y, col_count)
				else:
					if candidate.y < 0 or candidate.y >= col_count:
						return
				var btn := get_button_at(candidate)
				if btn:
					selected = candidate
					btn.grab_focus()
					return
				candidate.y += direction.y
				steps += 1
			# no button found in entire row - stay put
		else:
			# wrap or clamp to a valid column index
			var target_col: int
			if wrap_navigation:
				target_col = posmod(next.y, col_count)
			else:
				target_col = clampi(next.y, 0, col_count - 1)

			# try the exact target slot first
			var btn := get_button_at(Vector2i(selected.x, target_col))
			if btn:
				selected = Vector2i(selected.x, target_col)
				btn.grab_focus()
			else:
				# filler: search up and down across rows (no wrap) for nearest button at target_col
				var lo := selected.x - 1
				var hi := selected.x + 1
				while lo >= 0 or hi < get_child_count():
					if lo >= 0:
						btn = get_button_at(Vector2i(lo, target_col))
						if btn:
							selected = Vector2i(lo, target_col)
							btn.grab_focus()
							return
						lo -= 1
					if hi < get_child_count():
						btn = get_button_at(Vector2i(hi, target_col))
						if btn:
							selected = Vector2i(hi, target_col)
							btn.grab_focus()
							return
						hi += 1
				# no button found at that column anywhere - stay put

	elif direction.x != 0: # vertical movement
		if skip_empty:
			# walk rows in the given direction; in each new row try to land on the same column
			# if that slot is a filler, skip the whole row
			var steps := 0
			var candidate_row := next.x
			while steps < row_count:
				if wrap_navigation:
					candidate_row = posmod(candidate_row, row_count)
				else:
					if candidate_row < 0 or candidate_row >= row_count:
						return
				# try same column, clamped to this row's width
				var col_count := get_child(candidate_row).get_child_count()
				var try_col := clampi(selected.y, 0, col_count - 1)
				var btn := get_button_at(Vector2i(candidate_row, try_col))
				if btn:
					selected = Vector2i(candidate_row, try_col)
					btn.grab_focus()
					return
				# row has no button at that slot - skip the entire row
				candidate_row += direction.x
				steps += 1
			# no suitable row found - stay put

		else:
			# wrap or clamp the target row
			if wrap_navigation:
				next.x = posmod(next.x, row_count)
			else:
				next.x = clampi(next.x, 0, row_count - 1)

			# try to land on the same column (clamped to this row's width)
			var col_count := get_child(next.x).get_child_count()
			var try_col := clampi(selected.y, 0, col_count - 1)
			var btn := get_button_at(Vector2i(next.x, try_col))
			if btn:
				selected = Vector2i(next.x, try_col)
				btn.grab_focus()
			else:
				# filler at that slot - walk outward from try_col to find nearest button
				var lo := try_col - 1
				var hi := try_col + 1
				while lo >= 0 or hi < col_count:
					if hi < col_count:
						btn = get_button_at(Vector2i(next.x, hi))
						if btn:
							selected = Vector2i(next.x, hi)
							btn.grab_focus()
							return
					if lo >= 0:
						btn = get_button_at(Vector2i(next.x, lo))
						if btn:
							selected = Vector2i(next.x, lo)
							btn.grab_focus()
							return
					lo -= 1
					hi += 1
				# no button in this row at all - stay put
