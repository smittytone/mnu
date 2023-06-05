#!/usr/bin/env bash
cd ~/Desktop
u=$(cat $HOME/.pak)
$GIT/devscripts/packapp.zsh -s "$HOME/OneDrive/Programming/mnu/pkgscripts" -u "$u" MNU.app