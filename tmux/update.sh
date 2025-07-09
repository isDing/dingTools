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

# 拷贝当前目录下的 .tmux.conf 到用户根目录
if [ -f ".tmux.conf" ]; then
    cp .tmux.conf "$HOME/.tmux.conf"
    echo "已更新 ~/.tmux.conf"
else
    echo "未找到 .tmux.conf，退出。"
    exit 1
fi

# 重新加载 tmux 配置
tmux source-file "$HOME/.tmux.conf"
echo "已重新加载 ~/.tmux.conf"

# 安装插件并清理无用插件
TPM_PATH="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_PATH" ]; then
    echo "TPM 未安装，正在克隆..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
fi

# 安装 .tmux.conf 中声明的插件
"$TPM_PATH/bin/install_plugins"
"$TPM_PATH/bin/clean_plugins"
"$TPM_PATH/bin/update_plugins"
echo "已更新配置文件中的插件。"

