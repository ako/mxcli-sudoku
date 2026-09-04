# Sudoku

<!-- mxcli-brain -->

Decisions anchored to the Sudoku module. Loaded when Sudoku is in play,
not otherwise.

## The Game owns the selection through Game_SelectedCell, which is what lets the keypad live in the Game's data context while its keys act on the selected square. Consequence for callers: ACT_SelectCell sets the selection on the Game it retrieves from the cell, so a caller holding an older handle sees no selection and ACT_ApplyValue silently does nothing.

Anchors: `@Sudoku.ACT_SelectCell`, `@Sudoku.ACT_ApplyValue` · id `1716c6` · 2026-09-04

## Counters are computed over squares that carry a solution, never over a constant 81. The Mix is 153 playable squares on a 225-square canvas, and the hardcoded 81 shipped as a negative empty count.

Anchors: `@Sudoku.ACT_Refresh` · id `2230ee` · 2026-09-04

## The Mix generator may apply only identity or transpose. A flip or a 180-degree rotation leaves each grid individually valid while moving the two overlapping corners apart, so the grids stop agreeing on the nine squares they share — a board that passes every per-grid check and is still unsolvable. Board space is 9! x 2, not 9! x 8.

Anchors: `@Sudoku.SUB_ShuffleSolutionMix` · id `251b07` · 2026-09-04

## RESET drops the undo history as well as the digits. A recorded move describes a square as it was before the board was emptied, so replaying one wrote a digit back onto a square the player had just cleared.

Anchors: `@Sudoku.ACT_ResetBoard`, `@Sudoku.ACT_Undo` · id `3cc625` · 2026-09-04

## Test assertions fold side effects into a value an assertion can read, because mxcli test asserts on what a microflow RETURNS and the move layer's whole job is side effects. SUB_ValidateGrid returns the first rule violation rather than a boolean so a failure arrives as a diagnosis, and it is itself tested against a grid it must reject.

Anchors: `@Sudoku.SUB_ValidateGrid`, `@Sudoku.TST_Play` · id `60ea4d` · 2026-09-04

## The Mix has its own page because Mendix caps gallery column counts at 12, which cannot express a 15-wide board. The layout comes from CSS instead, and the two corners no grid reaches are inert sd-void cells that hold their slots in the flow.

Anchors: `@Sudoku.Game_Mix` · id `77b4ad` · 2026-09-04

## One solver serves all four boards by taking the variant as parameters — a Diagonal flag adding two units, and a Regions map replacing the boxes when non-empty — rather than branching on a variant enum.

Anchors: `@Sudoku.ACT_SolveGrid`, `@Sudoku.ACT_DealGame` · id `7e3a1f` · 2026-09-04

## The grid travels through the engine as an 81-character string ('0' = empty), not as Cell rows. Mendix microflows have no arrays, and running the solver over 81 rows would put thousands of database operations inside every deal. Cell objects are created once, at the end.

Anchors: `@Sudoku.ACT_DealGame`, `@Sudoku.ACT_SolveGrid` · id `98a4eb` · 2026-09-04

## Row and column come from round(floor(i div 9)), not repeated subtraction. The floor is load-bearing: round alone sends index 32 to row 4 instead of row 3. Median deal 565ms to 236ms, worst case 1188ms to 602ms.

Anchors: `@Sudoku.ACT_SolveGrid` · id `afcebf` · 2026-09-04

## Keypad keys are containers with OnClick, not action buttons, because a button cannot hold the two stacked labels the design needs. A Mendix button can only map object parameters, not literals, so each digit gets a thin ACT_Set<n> wrapper delegating to one copy of the move logic.

Anchors: `@Sudoku.ACT_Set1`, `@Sudoku.ACT_ApplyValue` · id `c2fc1b` · 2026-09-04

## Pencil marks are nine booleans per cell, not one packed string: a widget cannot index into a string, and each mark needs its own visibility expression. Each is pinned to its slot with grid-area, or hidden marks collapse the grid and pack the visible ones top-left.

Anchors: `@Sudoku.ACT_ToggleNote` · id `d12159` · 2026-09-04

## The Mix deals a board solvable grid-by-grid, NOT one that requires reading across the overlap. Each grid is blanked and repaired independently and the shared squares are then reconciled, which can only add givens. A true Mix needs a solver that alternates between the grids.

Anchors: `@Sudoku.ACT_DealMix` · id `e6a28b` · 2026-09-04

## Toggling notes mode is a nanoflow, not a microflow. As a microflow it cost two /xas/ round trips and ~37KB because committing the Game with refresh made the gallery refetch all 81 squares. It deliberately does not commit: Mendix carries uncommitted client state into the next microflow that takes the object as a parameter.

Anchors: `@Sudoku.NF_ToggleNotes` · id `fa4e5f` · 2026-09-04
