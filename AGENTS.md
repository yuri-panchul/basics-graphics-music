# Shell script style

In long shell code blocks, put `then` on its own line after `if` and `elif`
conditions instead of using `; then` on the condition line.

In Bash scripts, separate comment blocks from adjacent non-comment code with
an empty line. Exception: do not put an empty line between a single-line
comment and the single-line assignment or simple command it describes.
This exception does not apply to function definitions or bodies, `if`
statements, or loops. Keep consecutive comment lines together.

Put an empty line between a command and a following `if` statement or loop
(`for`, `while`, or `until`).
