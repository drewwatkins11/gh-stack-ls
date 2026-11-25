# gh-stack-ls

A `gt ls`-style tree of every stack that [`gh stack`](https://github.com/github/gh-stack) tracks in the current repository.

`gh stack view` shows only the stack you are on. `gh stack-ls` shows all of them at once:

```
◉       a2 (#102)
◯       a1 (#101)
│ ◯     b1 (sacramento)
│ │ ◯   c3
│ │ ◯   c2 (needs restack)
│ │ ◯   c1
◯─┴─┘   develop
```

## Install

```sh
gh extension install drewwatkins11/gh-stack-ls
gh stack-ls
```

Requires `git`, `python3`, and the `gh-stack` extension. macOS and Linux only.

## What it shows

- `◉` marks the branch you have checked out.
- `#123` is the stack's PR number, once `gh stack submit` has opened one.
- A worktree name means the branch is checked out in another worktree.
- `needs restack` means the branch no longer contains its parent's tip. Run `gh stack rebase`.
- `missing locally` means the stack lists a branch that no longer exists in this clone.

## How it works

It reads the state file `gh stack` keeps at `.git/gh-stack` and checks ancestry with `git merge-base`. It is read-only, makes no network calls, and stores nothing of its own.

That file is not a documented interface. The tool supports state `schemaVersion` 1 and exits with an error on any other version rather than guessing. If `gh stack` changes its format, please open an issue.

Only stacks that `gh stack` tracks appear. To adopt existing branches, run `gh stack init --base <trunk> <bottom> ... <top>`.

## License

MIT
