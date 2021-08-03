#!/bin/bash
#----------------------------------------------------------------------------------------------------------------------#
# this script requires the synocommunity ffmpeg package see: https://synocommunity.com/package/ffmpeg
# please check https://synocommunity.com/ Easy Install guidelines
# if you use other ffmpeg binaries, make sure hey are able to decode DTS, otherwise the ac3 audio track will remain silent
#----------------------------------------------------------------------------------------------------------------------#

ffmpeg_bin="/var/packages/ffmpeg/target/bin/ffmpeg"
if [ ! -f "$ffmpeg_bin" ]; then
  ffmpeg_bin="ffmpeg"
fi

ffprobe_bin="/var/packages/ffmpeg/target/bin/ffprobe"
if [ ! -f "$ffprobe_bin" ]; then
  ffprobe_bin="ffprobe"
fi

########################################################################################################################
# DEFAULT ARGUMENTS
########################################################################################################################
delete_original="0" # 0 | 1
stats="-nostats"    # -stats | -nostats
loglevel="fatal"    # see https://ffmpeg.org/ffmpeg.html
quiet="0"           #

########################################################################################################################
# help
########################################################################################################################
show_help() {
  echo "Usage: $0 <source> [-h <help>] [-d <delete original>] [-s <show stats>] [-v <verbose>] [-q <quiet>]" 1>&2;
  exit 1;
}

########################################################################################################################
# RESTORE IFS on EXIT
########################################################################################################################
save_ifs=$IFS
IFS=$(echo -en "\n\b")

function finish {
  IFS=$save_ifs
}
trap finish EXIT

########################################################################################################################
# ARGUMENTS HANDLING
########################################################################################################################
file_list=""
if [ -z "$1" ]; then
  show_help
elif [ -d "$1" ]; then
  file_list=$(find "$1" -type f -iname "*.avi" -o -iname "*.mkv"  -not -path "*/@eaDir*/*")
elif [ -f "$1" ]; then
  file_list=("$1")
else
  echo "source $1 does not exists"
  exit 1
fi
shift 1 # remove source argument from stack

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
while getopts "hdsvq" opt; do
    case $opt in
        d) delete_original="1";;
        s) stats="-stats";;
        v) loglevel="verbose";;
        q) quiet="1";;
        h|*) show_help;;
    esac
done

########################################################################################################################
# PROCESSING
########################################################################################################################
for f in $file_list; do

  if [ ! -z "$(command -v $ffprobe_bin)" ]; then
    has_dts=$("$ffprobe_bin" -loglevel "$loglevel" "$f" -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 | grep dts)
  else
    has_dts=$("$ffmpeg_bin" -i  "$f" 2>&1 | grep -i dts | grep -v "title")
  fi

  if [ ! -z "$has_dts" ]; then

    if [ "$quiet" = "0" ]; then
      printf '\033[1;34;40m'
      echo "Converting $f"
      printf '\033[0m'
    fi

    dirname=$(dirname -- "$f")
    filename=$(basename -- "$f")
    extension="${filename##*.}"
    filename="${filename%.*}"
    tmp_file="$dirname/$filename.tmp.$extension"

    "$ffmpeg_bin" -y -i "$f" \
      -map 0 -vcodec copy \
      -scodec copy \
      -acodec ac3 -b:a 640k \
      -loglevel "$loglevel" \
      $stats \
      "$tmp_file" \
      && \
      mv "$f" "$f.original" \
      && \
      mv "$tmp_file" "$f"

    if [ "$delete_original" = "1" ] && [ -f "$f.original" ] ; then
      rm -f "$f.original"
    fi

    if [ -f "$tmp_file" ] ; then
      rm -f "$tmp_file"
    fi

  fi

done

IFS=$save_ifs
