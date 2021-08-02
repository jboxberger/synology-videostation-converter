#!/bin/bash

########################################################################################################################
# DEFAULT ARGUMENTS
########################################################################################################################
directory="**"
delete_original="0" # 0 | 1
stats="-nostats"    # -stats | -nostats
loglevel="fatal"    # see https://ffmpeg.org/ffmpeg.html
quiet="0"    # see https://ffmpeg.org/ffmpeg.html

########################################################################################################################
# help
########################################################################################################################
show_help() {
  echo "Usage: $0 <directory> [-h <help>] [-d <delete original>] [-s <show stats>] [-v <verbose>] [-q <quiet>]" 1>&2;
  exit 1;
}

########################################################################################################################
# ARGUMENTS HANDLING
########################################################################################################################
if [ ! -z "$1" ]; then
  if [ ! -d "$1" ]; then
    echo "directory $1 does not exists"
    exit 1
  fi
  directory="$1"
  shift 1 # remove argument from stack
else
  show_help
fi

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
file_list=$(find $directory -type f -iname "*.avi" -o -iname "*.mkv")

for f in $file_list; do

  has_dts=$(ffprobe -loglevel "$loglevel" "$f" -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 | grep dts)
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

    ffmpeg -y -i "$f" \
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