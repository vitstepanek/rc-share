#!/bin/bash

# --dir <dir with wallpapers>

dir=
sleepsec=60

while [ -n "$1" ]; do
    param=$1
    shift
    case $param in
        "--dir")
            dir=$1
            shift
        ;;
        "--sleep")
            sleepsec=$1
            shift
        ;;
    esac
done

[ -d "$dir" ] || {
    echo "Use --dir <wallpapers> to identify where the wallpapers are!" >&2
    exit 1
}

[[ "$sleepsec" =~ ^[0-9]+$ ]] || {
    echo "Use --sleep <seconds> to set how long between wallpaper change." >&2
    exit 1
}

while :; do
    for wpfile in $( ls $dir )
    do
        basename=$(basename $wpfile)
        ext="${basename##*.}"
        [[ "$ext" == "jpg" ]] && {
            echo "Setting wallpaper to ${dir}$wpfile"
            gsettings set org.gnome.desktop.background picture-uri "file:///${dir}${wpfile}"
        }
        sleep $sleepsec
    done
    echo "Reached end, repeat again."
    sleep 1
done
