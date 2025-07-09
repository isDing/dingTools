#!/usr/bin/env bash

if [ -f "$HOME/.tmux.conf" ]; then
    cp "$HOME/.tmux.conf" ./.tmux.conf
else
    echo "根目录下未找到 .tmux.conf 文件，跳过更新。"
fi

