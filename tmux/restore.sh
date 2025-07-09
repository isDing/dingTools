#!/usr/bin/env bash

# 判断是否存在 tmux 会话
if tmux ls &> /dev/null; then
    echo "检测到正在运行的 tmux 会话，正在关闭所有会话..."
    tmux kill-server
fi

BACKUP_DIR="$HOME/.dingTools/tmux"

# 检查备份目录是否存在文件
if [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    echo "检测到备份文件，开始还原..."

    # 删除当前 ~/.tmux 文件夹（如果存在）
    if [ -d "$HOME/.tmux" ]; then
        rm -rf "$HOME/.tmux"
    fi

    # 删除当前 ~/.tmux.conf 文件（如果存在）
    if [ -f "$HOME/.tmux.conf" ]; then
        rm -f "$HOME/.tmux.conf"
    fi

    # 恢复备份文件
    if [ -d "$BACKUP_DIR/.tmux" ]; then
        mv "$BACKUP_DIR/.tmux" "$HOME/.tmux"
    fi

    if [ -f "$BACKUP_DIR/.tmux.conf" ]; then
        mv "$BACKUP_DIR/.tmux.conf" "$HOME/.tmux.conf"
    fi

    # 重新加载 tmux 配置
    if [ -f "$HOME/.tmux.conf" ]; then
        tmux source-file "$HOME/.tmux.conf"
    fi

    echo "还原完成。"
else
    echo "未检测到备份文件，无需还原。"
fi

