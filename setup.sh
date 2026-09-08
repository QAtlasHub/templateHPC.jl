#!/bin/bash
# setup.sh — turn the template into your study. Run once, from the repository root.
#
#     ./setup.sh MyStudy            # rename the library only
#     ./setup.sh MyStudy FirstSweep # …and the example project with it
#
# Two things have to change before the copy is yours, and both are easy to forget:
#
#   1. the module name, which appears in the source, four Project.toml files and
#      the docs;
#   2. the UUIDs. The template ships placeholders (00000000-…), and every copy
#      that keeps them declares itself to be the same package as every other
#      copy. Pkg will resolve one of them into the other's place without saying
#      anything is wrong.
set -euo pipefail

NAME="${1:-}"
PROJECT="${2:-}"
if [ -z "$NAME" ]; then
    echo "usage: ./setup.sh <ModuleName> [ProjectName]" >&2
    exit 2
fi
if ! grep -q "MyModule" Project.toml 2>/dev/null; then
    echo "setup.sh: this repository has already been set up (no MyModule in Project.toml)." >&2
    echo "Re-running would rewrite names that are now yours. Refusing." >&2
    exit 1
fi

new_uuid() {
    if command -v uuidgen  >/dev/null 2>&1; then uuidgen | tr 'A-Z' 'a-z'
    elif command -v python3 >/dev/null 2>&1; then python3 -c 'import uuid;print(uuid.uuid4())'
    else julia -e 'using UUIDs; println(uuid4())'
    fi
}

# `sed -i` takes an argument on BSD and not on GNU; a backup suffix works on both.
subst() { sed -i.bak "$1" "$2" && rm -f "$2.bak"; }

echo "==> renaming MyModule -> $NAME"
git mv src/MyModule.jl "src/$NAME.jl" 2>/dev/null || mv src/MyModule.jl "src/$NAME.jl"
grep -rl "MyModule" . \
    --exclude-dir=.git --exclude-dir=out --exclude=setup.sh \
    | while read -r f; do subst "s/MyModule/$NAME/g" "$f"; done

echo "==> issuing fresh UUIDs"
for f in Project.toml projects/*/Project.toml projects/*/report/Project.toml; do
    [ -f "$f" ] || continue
    # `report/Project.toml` is an environment and carries no uuid; under
    # `pipefail` a non-matching grep would otherwise end the script here.
    old="$(grep -m1 '^uuid = ' "$f" | sed 's/uuid = "\(.*\)"/\1/' || true)"
    [ -n "$old" ] || continue
    new="$(new_uuid)"
    # the same UUID also names this package in every dependant's [deps]
    grep -rl "$old" . --exclude-dir=.git --exclude-dir=out --exclude=setup.sh \
        | while read -r g; do subst "s/$old/$new/g" "$g"; done
    echo "    $f  ->  $new"
done

if [ -n "$PROJECT" ]; then
    echo "==> renaming projects/ExampleSweep -> projects/$PROJECT"
    git mv "projects/ExampleSweep" "projects/$PROJECT" 2>/dev/null \
        || mv "projects/ExampleSweep" "projects/$PROJECT"
    # the project is a package too, so its module file carries the name as well
    git mv "projects/$PROJECT/src/ExampleSweep.jl" "projects/$PROJECT/src/$PROJECT.jl" 2>/dev/null \
        || mv "projects/$PROJECT/src/ExampleSweep.jl" "projects/$PROJECT/src/$PROJECT.jl"
    grep -rl "ExampleSweep" . --exclude-dir=.git --exclude-dir=out --exclude=setup.sh \
        | while read -r f; do subst "s/ExampleSweep/$PROJECT/g" "$f"; done
fi

echo "==> instantiating"
julia --project=. -e 'using Pkg; Pkg.instantiate()'
for p in projects/*/; do
    [ -f "$p/Project.toml" ] || continue
    julia --project="$p" -e 'using Pkg; Pkg.instantiate()'
done

cat <<EOF

Done. Next:

  julia --project=projects/${PROJECT:-ExampleSweep} \\
        projects/${PROJECT:-ExampleSweep}/scripts/compute.jl \\
        projects/${PROJECT:-ExampleSweep}/configs/smoke.toml

Then write $NAME.solve — it is the one function the sweep calls.
EOF
