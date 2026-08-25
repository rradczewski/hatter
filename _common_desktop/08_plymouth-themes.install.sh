#!/bin/bash
# Installs static Plymouth theme files from two pinned upstream sources. Neither
# upstream's own install script is ever run - files are downloaded into the
# tmpfs-mounted work dir and only the theme's static assets are copied into
# /usr/share/plymouth/themes/<name>/. Nothing here becomes the default theme;
# switch with `plymouth-set-default-theme` or preview with
# `plymouth-preview-theme` (see _common_desktop/08_plymouth-preview-theme.sh).

set -euo pipefail

THEMES_DIR=/usr/share/plymouth/themes
WORK_DIR=/tmp/plymouth-themes

# --- evangelion-ui-plymouth ------------------------------------------------
# https://gitlab.com/lobstermane/evangelion-ui-plymouth
# pinned commit 09e29886d212e2264192781b7a6bbd2ff0211b19
# WARNING: this theme's boot animation flashes rapidly - upstream's own README
# carries a seizure-risk warning.
EVANGELION_COMMIT=09e29886d212e2264192781b7a6bbd2ff0211b19
EVANGELION_SRC="$WORK_DIR/evangelion-ui-plymouth-${EVANGELION_COMMIT}"

curl -fsSL "https://gitlab.com/lobstermane/evangelion-ui-plymouth/-/archive/${EVANGELION_COMMIT}/evangelion-ui-plymouth-${EVANGELION_COMMIT}.tar.gz" \
    | tar xz -C "$WORK_DIR"

mkdir -p "$THEMES_DIR/evangelion-ui"
sed 's|EVANGELION_UI_PATH|/usr|g' "$EVANGELION_SRC/evangelion-ui.plymouth" > "$THEMES_DIR/evangelion-ui/evangelion-ui.plymouth"
cp "$EVANGELION_SRC/evangelion-ui.script" "$THEMES_DIR/evangelion-ui/evangelion-ui.script"
tar xzf "$EVANGELION_SRC/images.tar.gz" -C "$THEMES_DIR/evangelion-ui"

# --- adi1090x/plymouth-themes ----------------------------------------------
# https://github.com/adi1090x/plymouth-themes/releases/tag/v1.0
# pinned commit 5d8817458d764bff4ff9daae94cf1bbaabf16ede
# Every theme in this release is already a ready-to-use
# /usr/share/plymouth/themes/<name>/ tree (name.plymouth, name.script, images,
# LICENSE) - no install script, no path fixups needed.
ADI_RELEASE_TAG=v1.0
ADI_THEMES="
    abstract_ring abstract_ring_alt alienware angular angular_alt black_hud
    blockchain circle circle_alt circle_flow circle_hud circuit colorful
    colorful_loop colorful_sliced connect cross_hud cubes cuts cuts_alt
    cyanide cybernetic dark_planet darth_vader deus_ex dna double dragon
    flame glitch glowing green_blocks green_loader hexa_retro hexagon
    hexagon_2 hexagon_alt hexagon_dots hexagon_dots_alt hexagon_hud
    hexagon_red hud hud_2 hud_3 hud_space ibm infinite_seal ironman liquid
    loader loader_2 loader_alt lone metal_ball motion optimus owl pie pixels
    polaroid red_loader rings rings_2 rog rog_2 seal seal_2 seal_3 sliced
    sphere spin spinner_alt splash square square_hud target target_2 tech_a
    tech_b unrap
"

for theme in $ADI_THEMES; do
    curl -fsSL "https://github.com/adi1090x/plymouth-themes/releases/download/${ADI_RELEASE_TAG}/${theme}.tar.gz" \
        | tar xz -C "$THEMES_DIR"
done
