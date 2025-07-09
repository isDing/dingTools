#!/usr/bin/env bash

rm .vimrc || true
rm -rf .vim || true

if [ -f "$HOME/.vimrc" ]; then
    cp "$HOME/.vimrc" "./.vimrc"
else
    echo "未找到根目录下的 .vimrc 文件，跳过更新。"
fi

if [ -d "$HOME/.vim" ]; then
    cp -rf $HOME/.vim "./.vim"
else
    echo "未找到根目录下的 .vim 文件夹，跳过更新。"
fi
