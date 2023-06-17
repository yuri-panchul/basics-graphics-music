#!/usr/bin/env bash

#  The article about the settings below:
#  https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
#
#  The arguments against the article:
#  https://www.reddit.com/r/commandline/comments/g1vsxk/comment/fniifmk
#
#  Another idea:
#  http://redsymbol.net/articles/unofficial-bash-strict-mode
#
#  set -e           - Exit immediately if a command exits with a non-zero
#                     status.  Note that failing commands in a conditional
#                     statement will not cause an immediate exit.
#
#  set -o pipefail  - Sets the pipeline exit code to zero only if all
#                     commands of the pipeline exit successfully.
#
#  set -u           - Causes the bash shell to treat unset variables as an
#                     error and exit immediately.
#
#  set -x           - Causes bash to print each command before executing it.
#
#  set -E           - Improves handling ERR signals

set -Eeuo pipefail
# set -x

[ "$OSTYPE" = "linux-gnu" ] || exit 0

script=$(basename "$0")
script_dir=$(dirname "$0")

info ()
{
    printf "\n$script: $*\n" 1>&2
}

rules_dir=/etc/udev/rules.d
grep -q USB-Blaster $rules_dir/* && exit 0

rules_file="$script_dir/90-intel-fpga.rules"

if ! [ -f "$rules_file" ]; then
    rules_file="$script_dir/scripts/90-intel-fpga.rules"
fi

info "\nNo rules for USB Blaster detected in $rules_dir."                 \
     "Put it there and reboot"                                            \
     "before the first run of Intel FPGA Quartus:"                        \
     "\nsudo cp $rules_file $rules_dir"                                   \
     "\n\nНе вижу правил для программатора USB Blaster $rules_dir."       \
     "Положите их туда и перезагрузитесь"                                 \
     "перед первым запускам программы Intel FPGA Quartus:"                \
     "\nsudo cp $rules_file $rules_dir"                                   \
     "\n\nIf you want this script $script to do copying for you,"         \
     "you may be asked for your Linux user password."                     \
     "This is necessary to run sudo program on your behalf"               \
     "unless you have the root privileges already."                       \
     "This may not work if you are not in the system /etc/sudoers list."  \
     "Google or use Yandex about sudoers list in this case."              \
     "\n\nЕсли вы хотите, чтобы этот скрипт $script"                      \
     "выполнил копирование за вас,"                                       \
     "скрипт может спросить у вас пароль к вашему аккаунту на Linux."     \
     "Это нужно чтобы запустить от вашего лица программу sudo,"           \
     "кроме случая, когда у вас уже есть привилегии администратора."      \
     "Если вы не находитесь в списке /etc/sudoers системы,"               \
     "вызов sudo может не сработать."                                     \
     "Выясните в поисковике Google или Yandex, как это исправить."        \
     "\n\nWould you like the script to run"                               \
     "\"sudo cp $rules_file $rules_dir\" for you?"                        \
     "\n\nХотите ли вы вы, чтобы скрипт выполнил для вас"                 \
     "\"sudo cp $rules_file $rules_dir\" for you?"                        \

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

read -n 1 -r -p "[YyNnДдНн] "
printf "\n"

if ! [[ "$REPLY" =~ ^[YyДд]$ ]] ; then
    info "OK, no attempt to copy. Хорошо, не пробуем копировать"
    exit 0
fi

if ! sudo cp $rules_file $rules_dir ; then
    info "Was not able to copy the file with USB Blaster rules."         \
         "Копирование файла с правилами для USB Blaster не получилось."
    exit 0
fi

info "\nCopying was successful."                                    \
     "Reboot is needed so the new rules become effective."          \
     "\nКопирование получилось."                                    \
     "Чтобы система выполняла новые правила, нужно перезагрузить."

read -n 1 -r -p "Reboot? Перезагрузить? [YyNnДдНн] "
printf "\n"

sudo reboot
