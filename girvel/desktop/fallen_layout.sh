#!/usr/bin/zsh

niri msg action spawn -- ghostty --working-directory=$HOME/workshop/fallen -e zsh -c 'sleep 0.1; nvim .; exec zsh'
sleep 0.1
niri msg action spawn -- ghostty --working-directory=$HOME/workshop/fallen_release -e zsh -c 'sleep 0.1; nvim .; exec zsh'
sleep 0.1
niri msg action spawn -- firefox
sleep 0.1
niri msg action spawn -- ldtk
