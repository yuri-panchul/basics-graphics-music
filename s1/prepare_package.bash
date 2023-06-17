#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

#-----------------------------------------------------------------------------

script_path="$0"
script=$(basename "$script_path")
script_dir=$(dirname "$script_path")

run_dir="$PWD"
cd "$script_dir"

pkg_src_root=$(readlink -e ..)
pkg_src_root_name=$(basename "$pkg_src_root")

#-----------------------------------------------------------------------------

error ()
{
    printf "\n$script: ERROR: $*\n" 1>&2
    exit 1
}

#-----------------------------------------------------------------------------

f=$(git diff --name-status --diff-filter=R HEAD ..)

if [ -n "${f-}" ]
then
    error "there are renamed files in the tree."                            \
          "\nYou should check them in before preparing a release package."  \
          "\nSpecifically:\n\n$f"
fi

f=$(git ls-files --others --exclude-standard ..)

if [ -n "${f-}" ]
then
    error "there are untracked files in the tree."          \
          "\nYou should either remove or check them in"     \
          "before preparing a release package."             \
          "\nSpecifically:\n\n$f"                           \
          "\n\nYou can also see the file list by running:"  \
          "\n    git clean -d -n $pkg_src_root"             \
          "\n\nAfter reviewing (be careful!),"              \
          "you can remove them by running:"                 \
          "\n    git clean -d -f $pkg_src_root"             \
          "\n\nNote that \"git clean\" does not see"        \
          "the files from the .gitignore list."
fi

f=$(git ls-files --others ..)

if [ -n "${f-}" ]
then
    error "there are files in the tree, ignored by git,"                    \
          "based on .gitignore list."                                       \
          "\nThis repository is not supposed to have the ignored files."    \
          "\nYou need to remove them before preparing a release package."   \
          "\nSpecifically:\n\n$f"
fi

f=$(git ls-files --modified ..)

if [ -n "${f-}" ]
then
    error "there are modified files in the tree."                           \
          "\nYou should check them in before preparing a release package."  \
          "\nSpecifically:\n\n$f"
fi

#-----------------------------------------------------------------------------

# Search for the text files with DOS/Windows CR-LF line endings

# -r     - recursive
# -l     - file list
# -q     - status only
# -I     - Ignore binary files
# -U     - don't strip CR from text file by default
# $'...' - string literal in Bash with C semantics ('\r', '\t')

if [ "$OSTYPE" = linux-gnu ] && grep -rqIU $'\r$' ../*
then
    grep -rlIU $'\r$' ../*

    error "there are text files with DOS/Windows CR-LF line endings." \
          "You can fix them by doing:" \
          "\ngrep -rlIU \$'\\\\r\$' \"$pkg_src_root\"/* | xargs dos2unix"
fi

if grep -rqI $'\t' ../*
then
    grep -rlI $'\t' ../*

    error "there are text files with tabulation characters." \
          "\nTabs should not be used." \
          "\nDevelopers should not need to configure the tab width" \
          " of their text editors in order to be able to read source code." \
          "\nPlease replace the tabs with spaces" \
          "before checking in or creating a package." \
          "\nYou can find them by doing:" \
          "\ngrep -rlI \$'\\\\t' \"$pkg_src_root\"/*" \
          "\nYou can fix them by doing the following," \
          "but make sure to review the fixes:" \
          "\ngrep -rlI \$'\\\\t' \"$pkg_src_root\"/*" \
          "| xargs sed -i 's/\t/    /g'"
fi

if grep -rqI '[[:space:]]\+$' ../*
then
    grep -rlI '[[:space:]]\+$' ../*

    error "there are spaces at the end of line, please remove them." \
          "\nYou can fix them by doing:" \
          "\ngrep -rlI '[[:space:]]\\\\+\$' \"$pkg_src_root\"/*" \
          "| xargs sed -i 's/[[:space:]]\\\\+\$//g'"
fi

#-----------------------------------------------------------------------------

# A workaround for a find problem when running bash under Microsoft Windows

find_to_run=find
true_find=/usr/bin/find

if [ -x "$true_find" ]
then
    find_to_run="$true_find"
fi

#-----------------------------------------------------------------------------

find_command="$find_to_run .. -name '[0-9][0-9]_*.bash' -not -path '../scripts/*'"
eval "$find_command"

# read:
#
# -n nchars return after reading NCHARS characters rather than waiting
#           for a newline, but honor a delimiter if fewer than
#           NCHARS characters are read before the delimiter
#
# -p prompt output the string PROMPT without a trailing newline before
#           attempting to read
#
# -r        do not allow backslashes to escape any characters
# -s        do not echo input coming from a terminal

read -n 1 -r -p "Are you sure to overwrite all the files above? "
printf "\n"

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    # vargs:
    #
    # -n max-args,  --max-args=max-args
    # -r,           --no-run-if-empty    (GNU extension)
    eval "$find_command" | xargs -n 1 -r cp local_redirect.bash.template
    eval "$find_command" | xargs -n 1 -r chmod +x
else
    printf "$script: nothing is copied\n" 1>&2
    exit 1
fi

#-----------------------------------------------------------------------------

tgt_pkg_dir=$(mktemp -d)
#package_generic=${pkg_src_root_name}_$(date '+%Y%m%d_%H%M%S')
package_generic=${pkg_src_root_name}_$(date '+%Y%m%d')

package_script_oriented=${package_generic}_script_oriented
package_gui_oriented=${package_generic}_gui_oriented

package_path_script_oriented="$tgt_pkg_dir/$package_script_oriented"
package_path_gui_oriented="$tgt_pkg_dir/$package_gui_oriented"

mkdir "$package_path_script_oriented"
mkdir "$package_path_gui_oriented"

cp -r ../* \
  "$package_path_script_oriented"

cp -r ../README* ../LICENSE* ../boards  \
  RUN_ME_ON_LINUX_BEFORE_THE_FIRST_QUARTUS_RUN.bash  \
  "$package_path_gui_oriented"

mkdir "$package_path_gui_oriented/scripts"
cp *-intel-fpga.rules "$package_path_gui_oriented/scripts"

cp RUN_ME_ON_LINUX_BEFORE_THE_FIRST_QUARTUS_RUN.bash  \
  "$package_path_gui_oriented/ВЫПОЛНИ_МЕНЯ_ПРИ_РАБОТЕ_ПОД_ЛИНУКСОМ_ПЕРЕД_ПЕРВЫМ_ЗАПУСКОМ_КВАРТУСА.bash"

$find_to_run "$package_path_script_oriented/boards" -name top.qsf  \
    | while read qsf_file
do
    echo "$qsf_file"
    dir="$(dirname $qsf_file)/run"
    mkdir -p "$dir"
    cp "$qsf_file" "$dir"
    touch "$dir/top.qpf"
done

$find_to_run "$package_path_gui_oriented" -name top.qsf  \
    | while read qsf_file
do
    echo "$qsf_file"
    dir="$(dirname $qsf_file)"
    rm -f "$dir"/*.bash
    touch "$dir/top.qpf"

    sed -i 's|\.\./||g'   "$dir"/*.qsf
    sed -i 's|\.\.|.|g'   "$dir"/*.qsf
    sed -i /SEARCH_PATH/d "$dir"/*.qsf
done

rm -rf "$package_path_gui_oriented"/boards/*/00_template

#-----------------------------------------------------------------------------

if ! command -v zip &> /dev/null
then
    printf "$script: cannot find zip utility"

    if [ "$OSTYPE" = "msys" ]
    then
        printf "\n$script: download zip for Windows from https://sourceforge.net/projects/gnuwin32/files/zip/3.0/zip-3.0-setup.exe/download"
        printf "\n$script: then add zip to the path: %s" '%PROGRAMFILES(x86)%\GnuWin32\bin'
    fi

    exit 1
fi

#-----------------------------------------------------------------------------

rm -rf ${pkg_src_root_name}_*.zip

cd "$tgt_pkg_dir"

zip -r "$run_dir/$package_script_oriented.zip" "$package_script_oriented"
zip -r "$run_dir/$package_gui_oriented.zip"    "$package_gui_oriented"
