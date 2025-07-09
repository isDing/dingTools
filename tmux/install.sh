#!/usr/bin/env bash

# 检查 tmux 是否安装
if ! command -v tmux &> /dev/null; then
    echo "tmux 未安装，正在尝试安装..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y tmux
    elif command -v yum &> /dev/null; then
        sudo yum install -y tmux
    else
        echo "无法自动安装 tmux，请手动安装。"
        exit 1
    fi
fi

# 判断是否存在 tmux 会话
if tmux ls &> /dev/null; then
    echo "检测到正在运行的 tmux 会话，正在关闭所有会话..."
    tmux kill-server
fi

# 创建 ~/.dingTools/ 文件夹（如果不存在）
if [ ! -d "$HOME/.dingTools" ]; then
    mkdir -p "$HOME/.dingTools"
fi

# 创建 ~/.dingTools/tmux/ 文件夹（如果不存在）
if [ ! -d "$HOME/.dingTools/tmux" ]; then
    mkdir -p "$HOME/.dingTools/tmux"
fi

# 移动 ~/.tmux 文件夹（如果存在）
if [ -d "$HOME/.tmux" ]; then
    mv "$HOME/.tmux" "$HOME/.dingTools/tmux/"
fi

# 移动 ~/.tmux.conf 文件（如果存在）
if [ -f "$HOME/.tmux.conf" ]; then
    mv "$HOME/.tmux.conf" "$HOME/.dingTools/tmux/"
fi

# 将当前目录下的 .tmux.conf 拷贝到 ~/
if [ -f ".tmux.conf" ]; then
    cp .tmux.conf "$HOME/.tmux.conf"
    tmux source-file "$HOME/.tmux.conf"
else
    echo "当前目录下未找到 .tmux.conf 文件，跳过拷贝与加载。"
fi

# 安装 tmux 插件
TPM_PATH="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_PATH" ]; then
    "$TPM_PATH/bin/install_plugins"
else
    echo "TPM (tmux plugin manager) 未安装，正在尝试克隆..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
    "$TPM_PATH/bin/install_plugins"
fi

echo "脚本执行完成。"

