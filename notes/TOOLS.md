# Tools index

One line per kept tool. Status is what was actually run, with the date. Every tool reads
`PNP_REPO`, `PNP_SCRATCH`, `PNP_HANDLE` and no session path. Update this file the same day a
tool is added, changed or found broken.

## Works (run on real rows)

| Tool | Input, output | Covers | Status |
|---|---|---|---|
| `tools-norep-5x5/gen.py MASK NAME` | prints the proof file for `¬ RepSizeAtMost (5x5 mask) 10`; exit 2 if the method does not apply | 5 by 5 matrix lower-bound rows; exit 0 also shows the positive row of that mask is false | built for 5 masks, 20 s each, 2026-11-25; no file sent yet |
| `tools-norep-5x5/rep_sat.py MASK GATES SOLVER` | a representing circuit, or UNSAT | positive 5 by 5 rows | 11 gates in seconds, 9 gates UNSAT in minutes, 10 gates no answer in 25 min, 2026-11-25 |
| `tools-norep-5x5/small_fn_sat.py GATES NOT` | least AND/OR/NOT circuit for a function on few inputs (edit `f` and `n` at the top) | `HasCircuitSize n f s` existence rows up to 6 inputs | found the 10-gate at-least-3-of-5 circuit in 4 s, 2026-11-25 |
| `tools-norep-5x5/survey.py` | open rows grouped by title pattern | choosing which generator to build | run once, 2026-11-25 |
| `tools-lb9/gen9.py STATEMENT_FILE NAME` | proof file for `∀ t, HasCircuitSize 9 f t → B ≤ t`, or exit 2 | restriction tree; short by 1 to 3 gates on every row that stays open | two rebuilds of merged statements built 2026-11-25; use only as a fallback |
| `tools-lb9/gen9s.py STATEMENT_FILE NAME` | same rows, by a kernel-run circuit search with our own native search writing the table (engine of L_meta_1673); exit 2 out of reach; needs `g++` | 8 or 9 vertices, B up to 15, search under about 1.5 million nodes (26 of 30 sampled merged rows) | built L-meta-7384, 9433, 9725 (53 to 148 s), 10838 (13 min); L-meta-9433 MERGED 2026-11-25 |
| `tools-lb9/gen9c.py STATEMENT_FILE NAME` | same rows, by live-state closure certificates (engine of L_meta_11042); pure Python; re-checks its own output | same four open rows; files have one `structure`, no `inductive` | built 7384, 9433, 9725 (41 to 91 s), 10838 (10 min, MERGED), and merged 11042's graph with our data, 2026-11-25 |
| `tools-common/fetch_open.py OUT.json` | every open meta step (id, title, statement) from the data export, about 5,000 fetches in 3 minutes | finding all rows of a shape instead of the sampled `survey.py` | run 2026-11-25; the export lists rows the desk will not hand out |
| `tools-common/prices.py [HANDLE]` | paid points per merged proof from the data export: tiers, families, big payments per six hours, board top, our row | deciding what is worth a lease; takes no lease | run 2026-11-27 |
| `tools-common/save_notes.sh MESSAGE PATH...` | commits files under `$PNP_SCRATCH` to `notes` and `$PNP_SESSION_BRANCH` without a checkout, and pushes | saving notes and tools | used 2026-11-25 evening |
| `tools-rect/gen_rect.py STATEMENT_FILE NAME` | decides the true side of a rectangle-cover row and prints its proof; exit 3 if the statement is false, 2 if out of reach | NEG rows by weighting or a case tree; POS rows by a (weak) SAT cover search | 6 open NEG rows built in 31 to 146 s, 2026-11-25; larger matrices (21 by 21 and up) out of reach |
| `tools-onenot/gen_onenot.py STATEMENT_FILE NAME` | proof file for a positive `one NOT gate saves nothing` row, or exit 2 | about a third of the sparse open rows (9 to 11 edges), few of the dense ones | 3 open rows built (38 s to 8.5 min), 2026-11-25 |
| `tools-mono6/gen_mono.py STATEMENT_FILE NAME [OUT_DIR]` | writes AND BUILDS the proof of a 5 or 6 input `every AND/OR/NOT circuit has an AND/OR one no larger` row; exit 3 if false, 2 if out of reach | rows whose least AND/OR size is at most 9 in under a minute; size 10 in 4 to 7 minutes | L-meta-13307 sent 2026-11-25 (21 s end to end) |
| `tools-norep-5x5/autorow.sh` (running copy) | the desk loop with all four generators wired in | see the skill | ran all afternoon with fixed paths |

## Partly tested

| Tool | What is untested |
|---|---|
| `tools-norep-5x5/autorow.sh` | the saved copy takes its paths from the environment and was only syntax-checked; the copy that ran all afternoon had fixed paths. It checks rivals before keeping a row and, for six-input rows, commits and pushes the branch itself |

## Evidence scripts (kept beside the note they support, not tools)

`L-meta-2071-double-reread/rr.py`, `L-meta-1745-not-gates-small/enc.py`,
`L-meta-1735-ustar-small/ustar.py`, `L-meta-9303-no-ten-rectangles/dfs.py`: each reproduces
the table in its README. `enc.py` (least AND/OR/NOT size of a small graph's edge function) is
the most reusable of them.

## Wanted, largest open family first (survey of 2026-11-25)

1. `one NOT gate saves nothing`, dense rows (12 or more edges, most of the 299 open): the
   larger merged files (80 to 490 KiB) hold the stronger argument; `gen_onenot.py` does not.
2. Rectangle covers: a better cover search for the POS side, and the 21 by 21 and larger
   matrices for the NEG side.
2b. Six-input monotone rows whose least AND/OR size is 10 or more: `gen_mono.py` takes 4 to 7
   minutes there or does not reach; rivals take 3 to 5.
3. Smaller B = 16 certificates: `gen9s.py` proves the 9-vertex B = 16 rows but its files check
   in 11 to 19 minutes and 7 to 9 GB, at or over the checker's limits. And L-meta-8399
   (8 vertices, B = 15): neither generator reaches it; the larger form is 9-vertex only so far.
4. Pigeonhole refutation lengths (resolution, Res(+), cutting planes, clause learning): about
   45 open; nothing yet. A checked 567-line proof of the 89-line Res(+) bound is in
   `L-gct-270-and-L-pcx-175-false/L_pcx_176_draft.lean` as a starting point for counting bounds.
5. The other merged family for 5 by 5 rows (`L_meta_9224`, `9273`, `9399`, `9186`) for masks
   `gen.py` rejects.

## Templates

- `tools-common/existence_template.lean`: a whole proof of an existence row (`HasCircuitSize`,
  here at-least-3-of-5 in 10 gates): `refine ⟨⟨[gates], out⟩, ?_, ?_, ?_⟩`, the gate condition by
  `rcases ... <;> simp`, size and correctness by `decide`. The same shape proves
  `RepSizeAtMost` rows. Built 2026-11-25; never sent (rivals were ahead).
- `tools-common/brief_template.md`: the brief for a proof or generator subagent, with the file
  rules and the report items.
- `tools-common/draw.sh N QUERY x`: draws N steps and prints id, weight, title, statement head.

## What each family has turned out to be (2026-11-25; check before trusting)

| Title starts or contains | Which side has been true | What proves it |
|---|---|---|
| `Table 1a, 5 by 5, mask M: represented ... at most 10 gates` / `takes at least 11` | lower bound for every mask tried (7 of 7) | `gen.py` |
| `Table 2: 9 vertices ... needs at least B` / `False: 9 vertices ...` | the lower bound (about 150 merged, no `False:` side merged) | `gen9c.py` or `gen9s.py` up to B = 15; `gen9s.py` for B = 16 on 9 vertices (check with `gen9s/leanj.sh`, 11 to 19 minutes, 7 to 9 GB) |
| `one NOT gate saves nothing` / `It is false that: ...` | the positive side (54 merged, 0 of the negation) | generator being built |
| `An AND/OR circuit ... at most s gates computes the edge function of the listed graph` | s is the star value minus one (edges + cover - 1 - 1): a counterexample to the conjecture, none known | release |
| `Cycle family at k` positive | merged siblings prove 7k - 2 impossible up to k = 9 | release the positive side |
| `Rectangles: ...` both sides | depends on the matrix; decide by search first (plane of order 3: 10 is impossible, 11 works) | generator being built |
| `f g + 1 for two polynomials with at most k terms has at most N real roots` | false for k = 4 (13 roots) and k = 5 (16 roots): 4k - 3 are reachable | explicit pair and sign changes; drafts in notes |
| `Res(+) on PHP(5,4): some refutation has at most 89 lines` | false: 90 is the least by counting | draft in notes |
| `At least 3 of 5 inputs: no circuit of at most 10` | false: a 10-gate circuit exists | `existence_template.lean` |
| `A step toward: ...` with `reductions` true and three merged `R_` files, weight 90 or more | the open bound | release at the draw |

Desk behaviour seen: a step released with `other` is not offered again for an hour; one
released with `missing_lemma` or `statement_seems_false` was not offered again the same day;
the negated twin of a step is a neighbouring id (n - 1 or n + 1); after a row is released as
false its twin was never offered to us (7 tries); `no step is free that you have not already
looked at` means the desk has nothing new for this handle, not that it is empty.
`/desk/next?...&gap=<id>&have=proof` leases a named step when a proof is in hand, even while a
rival pull request waits; it answers `not open` for rows the export still lists as conjecture
(L-meta-7384, 9725, 9583). A rival pull request that is open for hours with one comment and no
merge did not win either time it was seen: ours merged for L-meta-9433 and L-meta-10838 and
the rivals were closed. Send ours, and tell the owner the rival exists. `tools/pnp.sh check` strips
comments before the guard: run `tidy` and the guard by hand (extract both Python blocks from
`tools/pnp.sh`; a comment line above `namespace` is refused otherwise).

## Before deep work on a row family

Read the `attack` list in the export map (`head.json` -> `files.map` -> `attack`): each line has
a `status`. Rows of a line marked `stopped` can still show as conjecture in the export while the
desk answers `not open` for every one of them, proof in hand or not. Lease ONE row of the family
with `gap=<id>&have=proof` only once a proof builds; if the desk says `not open`, the family is
closed to us and the generator is the only product.

`GET https://pequalnp.com/desk/step?gap=<id>`: a row's state (`open`, `leased`, `not_open`)
without taking a lease. Use it before deep work and before each build.
