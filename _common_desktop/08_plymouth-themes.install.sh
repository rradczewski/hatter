#!/bin/bash

set -xeuo pipefail

THEMES_DIR=/usr/share/plymouth/themes
WORK_DIR=/tmp/plymouth-themes

# --- evangelion-ui-plymouth ------------------------------------------------
EVANGELION_COMMIT=09e29886d212e2264192781b7a6bbd2ff0211b19
EVANGELION_SRC="$WORK_DIR/evangelion-ui-plymouth-${EVANGELION_COMMIT}"

curl -fsSLv "https://gitlab.com/lobstermane/evangelion-ui-plymouth/-/archive/${EVANGELION_COMMIT}/evangelion-ui-plymouth-${EVANGELION_COMMIT}.tar.gz" \
    | tar xz -C "$WORK_DIR"

mkdir -p "$THEMES_DIR/evangelion-ui"
sed 's|EVANGELION_UI_PATH|/usr|g' "$EVANGELION_SRC/evangelion-ui.plymouth" > "$THEMES_DIR/evangelion-ui/evangelion-ui.plymouth"
cp "$EVANGELION_SRC/evangelion-ui.script" "$THEMES_DIR/evangelion-ui/evangelion-ui.script"
tar xzf "$EVANGELION_SRC/images.tar.gz" -C "$THEMES_DIR/evangelion-ui"

# --- adi1090x/plymouth-themes ----------------------------------------------
# https://github.com/adi1090x/plymouth-themes
# pinned commit 5d8817458d764bff4ff9daae94cf1bbaabf16ede
# Downloads the full repo source once (one request instead of one per theme)
# and extracts only the theme directories listed below. Each is already a
# ready-to-use /usr/share/plymouth/themes/<name>/ tree (name.plymouth,
# name.script, images, LICENSE) - no install script, no path fixups needed.
ADI_COMMIT=5d8817458d764bff4ff9daae94cf1bbaabf16ede
ADI_PREFIX="plymouth-themes-${ADI_COMMIT}"
ADI_ARCHIVE="$WORK_DIR/plymouth-themes.tar.gz"

ADI_PACK_1="abstract_ring abstract_ring_alt alienware angular angular_alt black_hud blockchain circle circle_alt circle_flow circle_hud circuit colorful colorful_loop colorful_sliced connect cross_hud cubes cuts cuts_alt"
ADI_PACK_2="cyanide cybernetic dark_planet darth_vader deus_ex dna double dragon flame glitch glowing green_blocks green_loader hexagon hexagon_2 hexagon_alt hexagon_dots hexagon_dots_alt hexagon_hud hexagon_red"
ADI_PACK_3="hexa_retro hud hud_2 hud_3 hud_space ibm infinite_seal ironman liquid loader loader_2 loader_alt lone metal_ball motion optimus owl pie pixels polaroid"
ADI_PACK_4="red_loader rings rings_2 rog rog_2 seal seal_2 seal_3 sliced sphere spin spinner_alt splash square square_hud target target_2 tech_a tech_b unrap"

curl -fsSLv -o "$ADI_ARCHIVE" "https://github.com/adi1090x/plymouth-themes/archive/${ADI_COMMIT}.tar.gz"

ADI_MEMBERS=()
for theme in $ADI_PACK_1; do ADI_MEMBERS+=("${ADI_PREFIX}/pack_1/${theme}"); done
for theme in $ADI_PACK_2; do ADI_MEMBERS+=("${ADI_PREFIX}/pack_2/${theme}"); done
for theme in $ADI_PACK_3; do ADI_MEMBERS+=("${ADI_PREFIX}/pack_3/${theme}"); done
for theme in $ADI_PACK_4; do ADI_MEMBERS+=("${ADI_PREFIX}/pack_4/${theme}"); done

tar xzf "$ADI_ARCHIVE" -C "$THEMES_DIR" --strip-components=2 "${ADI_MEMBERS[@]}"
