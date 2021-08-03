#!/bin/bash
#----------------------------------------------------------------------------------------------------------------------#
# this script requires the synocommunity inotify-tools package see: https://synocommunity.com/package/inotify-tools
# please check https://synocommunity.com/ Easy Install guidelines
#----------------------------------------------------------------------------------------------------------------------#

########################################################################################################################
# help
########################################################################################################################
show_help() {
  echo "Usage: $0 <directory> [-r <recursive>] [-q <quiet>] [-h <help>]" 1>&2;
  exit 1;
}

########################################################################################################################
# DEFAULT ARGUMENTS
########################################################################################################################
recursive=""    #
quiet=""        #

########################################################################################################################
# ARGUMENTS HANDLING
########################################################################################################################
if [ ! -d "$1" ]; then
  echo "source $1 does not exists"
  exit 1
fi

watch_directories=(
  "$1"
);

exclude_directories=(
  "@eaDir"
);

shift 1 # remove source argument from stack

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
while getopts "rqh" opt; do
    case $opt in
        r) recursive="-r";;
        q) quiet="-q";;
        h|*) show_help;;
    esac
done

inotifywait $recursive $quiet -m ${watch_directories[*]} --exclude ${exclude_directories[*]}  -e close_write,moved_to |
  while read dir action file; do
    #echo "The file '$file' appeared in directory '$dir' via '$action'"
    extension="${file##*.}"
    if [ "$extension" = "avi" ] || [ "$extension" = "mkv" ]; then
      filename="${file%.*}"
      if [ -f "$dir/$file" ]; then
        ./convert.sh "$dir/$file" $quiet
      fi
    fi
  done
