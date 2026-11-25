#!/usr/bin/env bash
# Builds a throwaway repo with three stacks and checks gh-stack-ls output.
set -u
BIN="$(cd "$(dirname "$0")/.." && pwd)/gh-stack-ls"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fails=0
expect() {
  if [[ "$2" == "$3" ]]; then echo "ok   $1"; else
    fails=$((fails+1)); echo "FAIL $1"; diff <(echo "$2") <(echo "$3") | sed 's/^/     /'; fi
}

git init -q --bare "$T/remote.git"
git init -q -b develop "$T/repo" && cd "$T/repo"
git config user.email t@t && git config user.name t
git remote add origin "$T/remote.git"
git commit -q --allow-empty -m root
mk() { git checkout -q -b "$1" "$2"; git commit -q --allow-empty -m "$1 work"; }
mk a1 develop; mk a2 a1; mk b1 develop; mk c1 develop; mk c2 c1
git push -q origin a1 a2 b1 c1 c2 2>/dev/null
git checkout -q c1 && git commit -q --allow-empty -m "c1 more"   # c2 needs restack, c1 needs push
cat >"$(git rev-parse --git-common-dir)/gh-stack" <<'J'
{"schemaVersion":1,"stacks":[
 {"trunk":{"branch":"develop"},"branches":[{"branch":"a1","pullRequest":{"number":101}},{"branch":"a2","pullRequest":{"number":102}}]},
 {"trunk":{"branch":"develop"},"branches":[{"branch":"b1"}]},
 {"trunk":{"branch":"develop"},"branches":[{"branch":"c1"},{"branch":"c2"},{"branch":"gone"}]}]}
J
git checkout -q a2

expect "short tree" "$(cat <<'E'
◉      a2 (#102)
◯      a1 (#101)
│ ◯    b1
│ │ ◯  gone (missing locally)
│ │ ◯  c2 (needs restack)
│ │ ◯  c1
◯─┴─┘  develop
E
)" "$(NO_COLOR=1 "$BIN")"

expect "--reverse" "$(cat <<'E'
◯─┬─┐  develop
│ │ ◯  c1
│ │ ◯  c2 (needs restack)
│ │ ◯  gone (missing locally)
│ ◯    b1
◯      a1 (#101)
◉      a2 (#102)
E
)" "$(NO_COLOR=1 "$BIN" --reverse)"

expect "--stack shows only the current stack" "$(cat <<'E'
◉  a2 (#102)
◯  a1 (#101)
◯  develop
E
)" "$(NO_COLOR=1 "$BIN" --stack)"

long=$(NO_COLOR=1 "$BIN" --long --stack)
expect "--long lists each branch's own commits" "1" "$(grep -c 'a2 work' <<<"$long")"
expect "--long does not repeat parent commits under a2" "1" "$(grep -c 'a1 work' <<<"$long")"
expect "--long trunk line uses one space" "◯ develop" "$(tail -1 <<<"$long")"
git checkout -q c1
expect "--long flags unpushed work" "1" "$(NO_COLOR=1 "$BIN" --long --stack | grep -c 'c1 (needs push)')"

expect "no colour when piped" "0" "$("$BIN" | grep -c $'\e')"
colored=$(FORCE_COLOR=1 "$BIN")
expect "FORCE_COLOR uses Graphite's first column colour" "1" "$(grep -c $'\e\\[38;2;76;203;241m' <<<"$colored" | tr -d ' ' | sed 's/[1-9][0-9]*/1/')"
expect "NO_COLOR beats FORCE_COLOR" "0" "$(NO_COLOR=1 FORCE_COLOR=1 "$BIN" | grep -c $'\e')"

git checkout -q --detach
expect "detached HEAD with --stack fails clearly" "1" "$("$BIN" --stack >/dev/null 2>&1; echo $?)"

echo; [[ $fails -eq 0 ]] && echo "all passed" || { echo "$fails failed"; exit 1; }
