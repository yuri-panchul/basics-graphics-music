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

## Bash parameter expansion and spacing

Explain non-obvious Bash parameter expansions with a comment immediately
above each assignment or command, describing the operator and its effect.
Keep each comment and its code together, separated from surrounding code by
empty lines. Do not add an empty line before a closing `fi`, `done`, `esac`,
or function brace just to separate such a pair.

Do not put an empty line immediately after an opening `then`, `do`, or
function `{`, even when the first item is a comment. This takes precedence
over the comment-separation rules above.

After a multiline `info`, `warning`, or `error` call, put an empty line before a
following single-line command or assignment.

Put an empty line after `fi`, `done`, or `esac` before a following `return`,
single-line command, or assignment.
