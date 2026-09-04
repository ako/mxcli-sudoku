# Project

<!-- mxcli-brain -->

Decisions that are not about one module. This file is loaded every
session, so it carries the tightest cap — see `mxcli brain show`.

## A non-idempotent statement must sort to the end of its MDL script. exec halts at the first error, so an 'alter page ... insert' in the middle of a file means every statement below it silently never runs from the second pass onward — the symptom is a page that stops matching its script while the error names a different page.

Anchors: none · id `ca9c9c` · 2026-09-04

## Coverage here is judged by mutation testing, not by test count. The suite reported 22/22 for weeks while 16 of those tests asserted nothing; a defect is only considered covered once a deliberate break in that code has been shown to turn a test red.

Anchors: none · id `f2317e` · 2026-09-04
