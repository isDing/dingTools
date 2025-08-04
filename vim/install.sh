#!/usr/bin/env bash

# 检查 vim 是否安装并更新到最新
if ! command -v vim &> /dev/null; then
    echo "vim 未安装，正在尝试安装..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y vim
    elif command -v yum &> /dev/null; then
        sudo yum install -y vim
    else
        echo "无法自动安装 vim，请手动安装。"
        exit 1
    fi
# else
#     echo "vim 已安装，尝试更新到最新版本..."
#     if command -v apt &> /dev/null; then
#         sudo apt install --only-upgrade -y vim
#     elif command -v yum &> /dev/null; then
#         sudo yum update -y vim
#     fi
fi
# 检查 nodejs 是否安装
if ! command -v node &> /dev/null; then
    echo "nodejs 未安装，正在尝试安装..."
    # Download and install nvm:
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    # in lieu of restarting the shell
    \. "$HOME/.nvm/nvm.sh"
    # Download and install Node.js:
    nvm install 22
fi

# 创建备份目录
BACKUP_DIR="$HOME/.dingTools/vim"
mkdir -p "$BACKUP_DIR"

# 备份与 vim 相关的配置文件
for file in "$HOME/.vimrc" "$HOME/.viminfo"; do
    if [ -e "$file" ]; then
        mv "$file" "$BACKUP_DIR/"
        echo "已备份 $file 到 $BACKUP_DIR"
    fi
done

# 拷贝当前目录下的 .vimrc 到 ~/
if [ -f ".vimrc" ]; then
    cp .vimrc "$HOME/.vimrc"
    echo "已将 .vimrc 拷贝到 ~/"
else
    echo "未找到当前目录下的 .vimrc 文件，跳过复制。"
fi

if ![ -d "$HOME/.vim" ]; then
    mkdir "$HOME/.vim"
fi
if [-f "coc-settings.json" ]; then
    cp coc-settings.json "$HOME/.vim/coc-settings.json"
fi

# # 拷贝当前目录下的 .vim 到 ~/
# if [ -d ".vim" ]; then
#     cp -rf .vim "$HOME/.vim"
#     echo "已将 .vim 拷贝到 ~/"
# else
#     echo "未找到当前目录下的 .vim 文件夹，跳过复制。"
# fi

echo "vim 配置完成。"

