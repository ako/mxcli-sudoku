# mxcli-sudoku

A playable Sudoku app built in **Mendix 11.12.1**, authored entirely through
[`mxcli`](https://github.com/ako/mxcli) / MDL — no Studio Pro.

The toolchain that builds and runs it is set up by committed automation; see
[TOOLING.md](TOOLING.md).

## The app

| | |
|---|---|
| **Landing page** | `Sudoku.Home` — pick Easy / Medium / Hard |
| **Board** | `Sudoku.Game_Play` — 9x9 grid, number pad, live validation |
| **Module** | `Sudoku` (the scaffolded `MyFirstModule` is left untouched) |

**Playing.** Choose a difficulty and a fresh board is dealt. Select a square,
then tap a digit on the number pad. Entries that disagree with the solution turn
red immediately and the conflict counter updates; dealt squares are read-only.
`Hint` reveals one square, `Reset board` clears everything you filled in, and the
board flips to a solved banner once all 81 squares are correct.

### How boards are generated

`Sudoku.ACT_DealGame` produces boards that are valid, solvable, **and fully
determined** — exactly one solution.

1. **Build a complete grid** from the classic seed pattern

   ```
   base(r,c) = ((3*(r mod 3) + (r div 3) + c) mod 9) + 1
   ```

   then shuffle it with three transforms that preserve validity: rotate the rows
   inside each band, the columns inside each stack, and the digit alphabet —
   9 x 3^3 x 3^3 = 6,561 grids. Iterating band/row-in-band and stack/col-in-stack
   reads `r mod 3` and `r div 3` straight off the loop counters, so no integer
   division is needed (Mendix `div` returns a Decimal, tripping CE0117).

2. **Blank squares** in a strided pseudo-random order down to the difficulty's
   target. Any stride coprime with 81 walks every square exactly once.

3. **Repair until fully determined.** `Sudoku.ACT_SolveGrid` solves as far as
   logic allows using naked singles (one candidate left in a square) and hidden
   singles (a digit that fits only one square in a unit). Any square it cannot
   deduce is handed back as a given. Restoring every undetermined square at once
   massively over-restores, so the repair runs in four passes — returning a
   quarter, a third, a half, then the remainder — letting deductions cascade
   between passes. Because every blank that survives is recoverable by forced
   steps alone, the puzzle has **exactly one solution** by construction.

4. **Top up** if logic forced a sparser board than the tier wants. Revealing a
   square only adds information, so it never costs uniqueness.

The grid travels as an **81-character string** (`'0'` = empty), not as objects:
Mendix microflows have no arrays, and running the solver over 81 `Cell` rows
would put thousands of database operations in the middle of every deal. `Cell`
objects are created once, at the end, from the finished puzzle and solution.

Measured: a deal takes ~2-3s, and the ten most recent boards were each verified
straight out of PostgreSQL as a valid grid with exactly one solution.

**Difficulty ceiling.** The generator only emits puzzles solvable by singles, so
in Sudoku terms every board is gentle; Hard lands around 38-44 givens rather than
the mid-20s. Going lower needs a backtracking uniqueness checker, which is
impractical inside a microflow — that would be the job of a Java action.

### Domain model

```
Sudoku.Game  1 ──< Sudoku.Cell   (Cell_Game, delete cascades)
```

Each `Cell` stores the player's `Value` **and** its `SolutionValue`, so validating
a move is a direct comparison instead of a row/column/box scan. `CellClass` is
precomputed at deal time and carries the 3x3 box borders plus the given/open
state, keeping the page free of large inline expressions.

### Why a number pad instead of typing

Every move is a normal server-side microflow (`ACT_ApplyValue`) that commits the
cell and re-evaluates the board. Text inputs would leave edits sitting in
client-side state that a later microflow wouldn't see. A Mendix button can only
map object parameters — not literals — so each digit gets a thin wrapper
(`ACT_Set1`…`ACT_Set9`) delegating to the single copy of the move logic.

### Styling

Atlas-first, per the four-layer model:

- **Layer 1** — `theme/web/custom-variables.scss`: `--brand-primary` retuned to `#3b5bdb`.
- **Layer 2** — `theme/web/_sudoku.scss`: only what Atlas has no vocabulary for —
  the rule grid, digit treatment, number pad, difficulty cards.

## Source layout

MDL source lives in `Sudoku/mdlsource/` and is applied in order:

| Script | Contents |
|---|---|
| `01-domain-model.mdl` | Module, enumerations, `Game` + `Cell`, association |
| `02-microflows-core.mdl` | Logical solver, board generation, validation, hint, reset |
| `03-microflows-pad.mdl` | The nine number-pad wrappers |
| `04-page-play.mdl` | The board page |
| `05-home-and-nav.mdl` | New-game actions, landing page, back-link |
| `06-navigation.mdl` | Responsive profile → `Sudoku.Home` |

Re-apply any of them (each is `create or replace`):

```bash
cd Sudoku
./mxcli check mdlsource/02-microflows-core.mdl -p Sudoku.mpr --references
./mxcli exec  mdlsource/02-microflows-core.mdl -p Sudoku.mpr
```

## Running it

`scripts/run-app.sh` starts the app automatically at session start; to run it by
hand:

```bash
mxcli run --local --ensure-db --watch -p "$PWD/Sudoku/Sudoku.mpr"
```

The app serves at <http://127.0.0.1:8080/>. Set `MXCLI_HUB_SECRET` (and
optionally `MXCLI_HUB_URL`) in the environment to also register it with an
`mxcli tunnel-hub` for a public preview URL.

## Verification

`mx check` reports **0 errors**. Beyond that the app was driven with Playwright:
a board was dealt, a square selected, digits entered, erased and reset, and a
game played to completion (solved banner, 0 conflicts, no JS errors). The
generator was checked independently by reading every dealt board out of
PostgreSQL and asserting each row, column and 3x3 box contains 1-9 exactly once.

Known cosmetic lint findings, all informational: `MPR008` (MDL auto-positions
overlap on the Studio Pro canvas inside `ACT_DealGame`'s nested loops) and
`SEC001` (no entity access rules — project security level is `Off`, the Mendix
default for a prototype).
