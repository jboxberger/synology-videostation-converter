#!/bin/bash
#----------------------------------------------------------------------------------------------------------------------#
# this script requires the synocommunity inotify-tools package see: https://synocommunity.com/package/inotify-tools
# please check https://synocommunity.com/ Easy Install guidelines
#----------------------------------------------------------------------------------------------------------------------#
current_dir="$(dirname "$(test -L "$0" && readlink "$0" || echo "$0")")"

########################################################################################################################
# help
########################################################################################################################
show_help() {
  echo "Usage: $0 <directory> [-r <recursive>] [-q <quiet>] [-s <scan>] [-h <help>]" 1>&2;
  echo " -r: scan directory recursive";
  echo " -q: no output to stdout";
  echo " -s: scan directory for unconverted files before watch";
  exit 1;
}

########################################################################################################################
# DEFAULT ARGUMENTS
########################################################################################################################
directory=""    #
recursive=""    #
quiet=""        #
scan=""         # scan directory and convert before watch

########################################################################################################################
# ARGUMENTS HANDLING
########################################################################################################################
if [ -z "$1" ] || [ "$1" = "-h" ]; then
  show_help
elif [ -d "$1" ]; then
  directory="$1"
  shift 1 # remove source argument from stack
else
  echo "source $1 does not exists"
  exit 1
fi

watch_directories=(
  "$directory"
);

exclude_directories=(
  "@eaDir"
);

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
while getopts "rqsh" opt; do
    case $opt in
        r) recursive="-r";;
        q) quiet="-q";;
        s) scan="1";;
        h|*) show_help;;
    esac
done

if [ ! -z "$scan" ]; then
  "$current_dir"/convert.sh "$directory" $quiet &
fi

inotifywait $recursive $quiet -m ${watch_directories[*]} --exclude ${exclude_directories[*]}  -e close_write,moved_to |
  while read dir action file; do
    #echo "The file '$file' appeared in directory '$dir' via '$action'"
    extension="${file##*.}"
    if [ "$extension" = "avi" ] || [ "$extension" = "mkv" ]; then
      filename="${file%.*}"
      if [ -f "$dir/$file" ]; then
        "$current_dir"/convert.sh "$dir/$file" $quiet
      fi
    fi
  done
