#!/usr/bin/env bash
# Screenshot helper: region (default), output (active monitor), or window
MODE="${1:-region}"

case "$MODE" in
    region)  hyprshot -m region --raw | satty --filename - ;;
    output)  hyprshot -m output -m active --raw | satty --filename - ;;
    window)  hyprshot -m window --raw | satty --filename - ;;
    *)       hyprshot -m region --raw | satty --filename - ;;
esac
