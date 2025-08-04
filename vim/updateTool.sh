#!/usr/bin/env bash

rm .vimrc || true
rm -rf .vim || true

if [ -f "$HOME/.vimrc" ]; then
    cp "$HOME/.vimrc" "./.vimrc"
else
    echo "未找到根目录下的 .vimrc 文件，跳过更新。"
fi

if [ -d "$HOME/.vim" ]; then
    if [ -f "$HOME/.vim/coc-settings.json" ]; then
        cp $HOME/.vim/coc-settings.json "./coc-settings.json"
    fi
fi
