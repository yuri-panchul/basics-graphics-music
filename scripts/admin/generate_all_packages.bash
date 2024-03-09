#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

#-----------------------------------------------------------------------------

update_fpga_toolchain_var ()
{
    case $fpga_board in
        dk_dev_3c120n        | \
        de0                  )

            fpga_toolchain=quartus
            use_old_version_of_quartus=1
        ;;

        c5gx                 | \
        de0_cv               | \
        de0_nano             | \
        de0_nano_soc         | \
        de1_soc              | \
        de2_115              | \
        de10_lite            | \
        de10_lite_tm1638     | \
        de10_nano            | \
        omdazz               | \
        piswords6            | \
        qmtech_c4_starter    | \
        rzrd                 | \
        saylinx              | \
        step_max10           | \
        zeowaa               | \
        zeowaa_7_digit       )

            fpga_toolchain=quartus
            use_old_version_of_quartus=0
        ;;

        gowin_runber         | \
        tang_nano_1k         | \
        tang_nano_20k        | \
        tang_nano_4k         | \
        tang_nano_9k         | \
        tang_primer_20k_dock | \
        tang_primer_20k_dock_alt | \
        tang_primer_20k_lite )

            fpga_toolchain=gowin
        ;;

        arty_a7              | \
        arty_s7              | \
        basys3               | \
        cmod_a7              | \
        cmod_s7              | \
        nexys4               | \
        nexys4_ddr           | \
        nexys_a7             | \
        zybo_z7              )

            fpga_toolchain=xilinx
        ;;

        *)
            fpga_toolchain=none
        ;;
    esac
}

if [ -z "$GITHUB_TOKEN" ]; then
    echo ">> \$GITHUB_TOKEN variable is missing"
    exit 1
fi
if ! command -v zip &> /dev/null
then
    echo ">> zip command not found, installing..."
fi
if [ -z "$TARGET_ORG_NAME" ]; then
    echo ">> \$TARGET_ORG_NAME variable is missing"
    exit 1
fi

TARGET_REPO_NAME="basics-graphics-music"
TARGET_REPO_FULLNAME="${TARGET_ORG_NAME}/${TARGET_REPO_NAME}"
TEMPLATE_REPO="${TARGET_REPO_NAME}-template"
export USER=${USER:-root}

TEMP_DIR_PATH=$(mktemp -d)
echo "TEMP_DIR_PATH=$TEMP_DIR_PATH" >> ${GITHUB_ENV:-/dev/null}
cd "$TEMP_DIR_PATH"
mkdir "dist"

if [ ! -d "$TEMPLATE_REPO" ]; then
    git clone https://github.com/${TARGET_REPO_FULLNAME}.git "$TEMPLATE_REPO"
fi

available_fpga_boards=$(find "$TEMPLATE_REPO/boards" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tr "\r\n" " ")
fpga_board_id=0

for fpga_board in $available_fpga_boards
do
    ((++fpga_board_id))
    update_fpga_toolchain_var

    if [[ "$fpga_toolchain" != "quartus" ]] || [[ -z "$use_old_version_of_quartus" ]]; then
        echo ">> Generating is not available for $fpga_board"
        continue
    fi
    echo ">> Generating zip for $fpga_board"

    cp -r $TEMPLATE_REPO $TARGET_REPO_NAME
    cd $TARGET_REPO_NAME
    echo -e "$fpga_board_id\ny\n" | bash check_setup_and_choose_fpga_board.bash
    cd ..
    zip -r "./dist/$TARGET_REPO_NAME-$fpga_board.zip" "$TARGET_REPO_NAME"
    rm -rf $TARGET_REPO_NAME
done

# Create github release, moved to github workflow actions
# gh release create --repo ${TARGET_REPO_FULLNAME} --generate-notes --verify-tag ${PACKAGE_RELEASE_TAG} ./dist/*.zip
