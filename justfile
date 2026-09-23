# Fetch the licensed Berlingske Slab web fonts from the PRIVATE
# SteelCompendium/licensed-fonts repo into docs/fonts/licensed/ (gitignored — never
# commit them). This site hosts them for every steelcompendium.io site (SC-335; rules in
# the workspace ARCHITECTURE.md → "Licensed fonts"). Needs read access to that repo.
fonts:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d .licensed-fonts/.git ]; then
        git -C .licensed-fonts pull -q --ff-only
    else
        git clone -q --depth 1 git@github.com:SteelCompendium/licensed-fonts.git .licensed-fonts
    fi
    # Only the .woff2 files, by name (mirrors ci.yml) — never the rest of the private repo.
    rm -rf docs/fonts/licensed
    mkdir -p docs/fonts/licensed/berlingske-slab
    cp .licensed-fonts/web/berlingske-slab/*.woff2 docs/fonts/licensed/berlingske-slab/
    echo >&2 "[INFO] Licensed fonts installed in docs/fonts/licensed/"

# Preview locally (fetches the licensed fonts first; body falls back to Zilla Slab
# if the private repo is unreachable)
serve:
    @just fonts || echo >&2 "[WARN] licensed fonts unavailable; body text will render in Zilla Slab"
    mkdocs serve
