#!/bin/bash
[[ "$(setxkbmap -query | grep multix | wc -l)" = "1" ]] && setxkbmap us || setxkbmap ca multix
