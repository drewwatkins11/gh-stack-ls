# gh-stack-ls

A `gt ls`-style tree of every stack that [`gh stack`](https://github.com/github/gh-stack) tracks in the current repository.

`gh stack view` shows only the stack you are on. `gh stack-ls` shows all of them at once:

```
◉      a2 (#102)
◯      a1 (#101)
│ ◯    b1 (sacramento)
│ │ ◯  c3
│ │ ◯  c2 (needs restack)
│ │ ◯  c1
◯─┴─┘  develop
```

In a terminal, each stack gets its own column colour, using Graphite's palette and order. The output is meant to look the same as `gt ls`.

## Install

```sh
gh extension install drewwatkins11/gh-stack-ls
gh stack-ls
```

Requires `git`, `python3`, and the `gh-stack` extension. macOS and Linux only.

## Options

| Flag | Graphite equivalent | What it does |
|---|---|---|
| `-l`, `--long` | `gt log` | Adds each branch's age, its PR's number, state (Draft, Open, Merged, Closed), title and URL, and the branch's own commits (up to 20) |
| `--offline` | | With `--long`, skips GitHub and shows PR numbers only |
| `-s`, `--stack` | `gt ls --stack` | Shows only the current branch's stack. On a trunk, shows every stack on that trunk |
| `-r`, `--reverse` | `gt ls --reverse` | Prints the trunk first |

## What it shows

- `◉` marks the branch you have checked out.
- `#123` is the stack's PR number, once `gh stack submit` has opened one.
- A worktree name means the branch is checked out in another worktree.
- `needs restack` means the branch no longer contains its parent's tip. Run `gh stack rebase`.
- `missing locally` means the stack lists a branch that no longer exists in this clone.
- In `--long` only: `merged` or `closed` comes from the branch's PR on GitHub.
- In `--long` only: `needs push` means the branch differs from its upstream (or `origin/<branch>`); `not pushed` means it has no remote branch at all. Both are based on your last fetch.

Colour is on when stdout is a terminal. `NO_COLOR` turns it off, and `FORCE_COLOR` turns it on, for example when piping into `less -R`.

## How it works

It reads the state file `gh stack` keeps at `.git/gh-stack` and checks ancestry with `git merge-base`. It is read-only and stores nothing of its own.

The default view makes no network calls. `--long` makes one GraphQL request through `gh` for every branch shown. It looks a PR up by the number `gh stack` recorded, or else by branch name, which also finds PRs opened outside `gh stack`. If GitHub can't be reached, it warns on stderr and shows PR numbers only.

Text from GitHub is treated as untrusted: titles, links and error messages have terminal control characters stripped before printing, so a PR title can't inject escape sequences. A PR found by branch name only counts if its branch is in this repository, so a fork that reuses your branch name can't pose as your PR.

That file is not a documented interface. The tool supports state `schemaVersion` 1 and exits with an error on any other version rather than guessing. If `gh stack` changes its format, please open an issue.

Only stacks that `gh stack` tracks appear. To adopt existing branches, run `gh stack init --base <trunk> <bottom> ... <top>`.

## Development

```sh
test/smoke.sh
```

## License

MIT
