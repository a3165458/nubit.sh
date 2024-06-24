#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

# 节点安装功能
function install_node() {
    install_nodejs_and_npm
    install_pm2

    echo "启动Nubit 节点安装..."


while [ $# -gt 0 ]; do
    if [[ $1 = "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

if [ "$(uname -m)" = "arm64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="darwin-arm64"
    MD5_NUBIT="0cd8c1dae993981ce7c5c5d38c048dda"
    MD5_NKEY="4045adc4255466e37d453d7abe92a904"
elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="darwin-x86_64"
    MD5_NUBIT="7ce3adde1d9607aeebdbd44fa4aca850"
    MD5_NKEY="84bff807aa0553e4b1fac5c5e34b01f1"
elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
    ARCH_STRING="linux-arm64"
    MD5_NUBIT="9de06117b8f63bffb3d6846fac400acf"
    MD5_NKEY="3b890cf7b10e193b7dfcc012b3dde2a3"
elif [ "$(uname -m)" = "x86_64" ]; then
    ARCH_STRING="linux-x86_64"
    MD5_NUBIT="650608532ccf622fb633acbd0a754686"
    MD5_NKEY="d474f576ad916a3700644c88c4bc4f6c"
elif [ "$(uname -m)" = "i386" -o "$(uname -m)" = "i686" ]; then
    ARCH_STRING="linux-x86"
    MD5_NUBIT="9e1f66092900044e5fd862296455b8cc"
    MD5_NKEY="7ffb30903066d6de1980081bff021249"
fi

if [ -z "$ARCH_STRING" ]; then
    echo "Unsupported arch $(uname -s) - $(uname -m)"
    exit 1
else
    cd $HOME
    FOLDER=nubit-node
    FILE=$FOLDER-$ARCH_STRING.tar
    FILE_NUBIT=$FOLDER/bin/nubit
    FILE_NKEY=$FOLDER/bin/nkey
    if [ -f $FILE ]; then
        rm $FILE
    fi
    OK="N"
    if [ "$(uname -s)" = "Darwin" ]; then
        if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5 -q "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5 -q "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
            OK="Y"
        fi
    else
        if ! command -v tar &> /dev/null; then
            echo "Command tar is not available. Please install and try again"
            exit 1
        fi
        if ! command -v ps &> /dev/null; then
            echo "Command ps is not available. Please install and try again"
            exit 1
        fi
        if ! command -v bash &> /dev/null; then
            echo "Command bash is not available. Please install and try again"
            exit 1
        fi
        if ! command -v md5sum &> /dev/null; then
            echo "Command md5sum is not available. Please install and try again"
            exit 1
        fi
        if ! command -v awk &> /dev/null; then
            echo "Command awk is not available. Please install and try again"
            exit 1
        fi
        if ! command -v sed &> /dev/null; then
            echo "Command sed is not available. Please install and try again"
            exit 1
        fi
        if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5sum "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5sum "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
            OK="Y"
        fi
    fi
    echo "Starting Nubit node..."
    if [ $OK = "Y" ]; then
        echo "MD5 checking passed. Start directly"
    else
        echo "Installation of the latest version of nubit-node is required to ensure optimal performance and access to new features."
        URL=http://nubit.sh/nubit-bin/$FILE
        echo "Upgrading nubit-node ..."
        echo "Download from URL, please do not close: $URL"
        if command -v curl >/dev/null 2>&1; then
            curl -sLO $URL
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- $URL
        else
            echo "Neither curl nor wget are available. Please install one of these and try again"
            exit 1
        fi
        tar -xvf $FILE
        if [ ! -d $FOLDER ]; then
            mkdir $FOLDER
        fi
        if [ ! -d $FOLDER/bin ]; then
            mkdir $FOLDER/bin
        fi
        mv $FOLDER-$ARCH_STRING/bin/nubit $FOLDER/bin/nubit
        mv $FOLDER-$ARCH_STRING/bin/nkey $FOLDER/bin/nkey
        rm -rf $FOLDER-$ARCH_STRING
        rm $FILE
        echo "Nubit-node update complete."
    fi

    sudo cp $HOME/nubit-node/bin/nubit /usr/local/bin
    sudo cp $HOME/nubit-node/bin/nkey /usr/local/bin
    echo "export store=$HOME/.nubit-light-nubit-alphatestnet-1" >> $HOME/.bash_profile
    
    cat <<EOL > ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "nubit-node",
      script: "./start.sh",
      cwd: "$HOME/nubit-node",
      interpreter: "/bin/bash",
      watch: false,
      env: {
        NODE_ENV: "production"
      },
      error_file: "$HOME/logs/nubit-node-error.log",
      out_file: "$HOME/logs/nubit-node-out.log",
      log_file: "$HOME/logs/nubit-node-combined.log",
      time: true
    }
  ]
};
EOL


    mkdir -p $HOME/logs

    echo "Downloading start.sh script..."
    curl -sL1 https://nubit.sh/start.sh -o $HOME/nubit-node/start.sh
    chmod +x $HOME/nubit-node/start.sh

    echo "Starting nubit node with PM2..."

    pm2 start ecosystem.config.js --env production
fi

    echo '====================== 安装完成,请退出脚本后执行 source $HOME/.bash_profile 以加载环境变量 ==========================='

}

# 查看Nubit 服务状态
function check_service_status() {
    pm2 list
}

# Nubit 节点日志查询
function view_logs() {
    pm2 logs nubit-node
}

# Nubit 节点日志查询
function check_address() {

 nubit state account-address  --node.store $store

}

function check_pubkey() {

nkey list --p2p.network nubit-alphatestnet-1 --node.type light

}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
        echo "============================nubit节点安装===================================="
        echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
        echo "节点社区 Discord 社群:https://discord.gg/GbMV5EcNWF"
        echo "退出脚本，请按键盘ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装节点"
        echo "2. 查看节点同步状态"
        echo "3. 查看当前服务状态"
        echo "4. 查看钱包地址"
        echo "5. 查看pubkey"
        read -p "请输入选项（1-3）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) check_service_status ;;
        3) view_logs ;;
        4) check_address ;;
        5) check_pubkey ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
    
}

# 显示主菜单
main_menu
