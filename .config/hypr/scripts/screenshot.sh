#!/bin/bash
WS=$(hyprctl activeworkspace -j | jq -r '.id')
MODE=$1

case $MODE in
    region)  bash -c 'hyprshot -m region --raw | satty --filename -' & ;;
    output)  bash -c 'hyprshot -m output -m eDP-1 --raw | satty --filename -' & ;;
    window)  bash -c 'hyprshot -m window --raw | satty -f -' & ;;
esac

# Počkáme na satty a přesuneme na aktuální workspace
for i in $(seq 1 30); do
    sleep 0.1
    ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class=="satty") | .address' | head -1)
    if [ -n "$ADDR" ]; then
        hyprctl dispatch movetoworkspace "$WS,address:$ADDR"
        break
    fi
done