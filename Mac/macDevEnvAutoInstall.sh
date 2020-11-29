#!/bin/bash
# Operating System：Mac 10.11.6



############ Your Config Start ############
# HomeBrew 安装路径
HOMEBREW_PREFIX="/usr/local"

# Git 全局配置
YOUR_GIT_NAME="EisenHao"
YOUR_GIT_EMAIL="ei13911468370@gmail.com"

# SSH
YOUR_SSHGEN_EMAIL="ei13911468370@gmail.com"

# Golang
YOUR_GO_ROOT="xxxxxx/xxxx"
############  Your Config End  ############



############  Default Config Start (Don't change following code if you don't know what you do) ############
CHOWN="/usr/sbin/chown"
CHGRP="/usr/bin/chgrp"
# GROUP="$(groups $USER |awk '{print $1}')"
GROUP="admin"
NOW_HOME="/Users/$(whoami)"
NOW_TIME="$(date "+%Y_%m_%d_%H_%M_%S")"

# HomeBrew 安装路径
HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
# HomeBrew 本地缓存路径
HOMEBREW_CACHE="${NOW_HOME}/Library/Caches/Homebrew"
# HomeBrew 下载源1（中科大）
USER_BREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
USER_BREW_GIT=https://mirrors.ustc.edu.cn/brew.git
USER_BREW_GIT_CORE=https://mirrors.ustc.edu.cn/homebrew-core.git
USER_BREW_GIT_CASK=https://mirrors.ustc.edu.cn/homebrew-cask.git

# HomeBrew 下载源2（清华）
# USER_BREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
# USER_BREW_GIT=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
# USER_BREW_GIT_CORE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
# USER_BREW_GIT_CASK=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git
# USER_CASK_FONTS_GIT=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask-fonts.git
# USER_CASK_DRIVERS_GIT=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask-drivers.git

# # HomeBrew 下载源3（腾讯）
# USER_BREW_BOTTLE_DOMAIN=https://mirrors.cloud.tencent.com/homebrew-bottles
# USER_BREW_GIT=https://mirrors.cloud.tencent.com/homebrew/brew.git 
# USER_BREW_GIT_CORE=https://mirrors.cloud.tencent.com/homebrew/homebrew-core.git
# USER_BREW_GIT_CASK=https://mirrors.cloud.tencent.com/homebrew/homebrew-cask.git
############  Default Config Start ############


###################  Func Define Start  #########################
# 判断上步操作是否成功
# @param1 上步操作命令
# @param2 是否退出脚本("out"触发退出脚本)
judgeSuccess() {
    if [ $? -ne 0 ];then
        echo '\033[1;31m此步骤失败 '$1'\033[0m'
        if [[ "$2" == 'out' ]]; then
            exit 0
        fi
    else
        echo "\033[1;32m此步骤成功\033[0m"
    fi
}

# 判断是否有 sudo 权限（会尝试获取，第一次需手动输入密码）
# @describe 将是否有sudo权限暂存 HAVE_SUDO_ACCESS 变量中
have_sudo_access() {
    if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
        /usr/bin/sudo -l mkdir &>/dev/null
        HAVE_SUDO_ACCESS="$?"
    fi
    if [[ "$HAVE_SUDO_ACCESS" -ne 0 ]]; then
        echo "\033[1;31m开机密码输入错误，获取权限失败!\033[0m"
    fi
    return "$HAVE_SUDO_ACCESS"
}

# 退出脚本，并打印消息
# @param 待打印的消息
# @return 1
abort() {
    printf "%s\n" "$1"
    exit 1
}

# 打印命令字符串
# @param... 待打印的命令（可包含空格）
printCommand() {
    local arg
    printf "%s" "$1"
    shift
    for arg in "$@"; do
        printf " "
        printf "%s" "${arg// /\ }"
    done
}

# 以当前用户执行命令
# @param 待执行命令
# @return 1 -- 若命令执行失败；
execute() {
    if ! "$@"; then
        abort "$(printf "\033[1;31m此命令运行失败（再次运行脚本或者手动运行此命令测试权限）:sudo %s\033[0m" "$(printCommand "$@")")"
    fi
}

# 以管理员权限运行命令
# @param 待执行命令
# @return 1 -- 若命令执行失败；
execute_sudo() {
    # local -a args=("$@")
    # if [[ -n "${SUDO_ASKPASS-}" ]]; then
    #   args=("-A" "${args[@]}")
    # fi
    if have_sudo_access; then
        execute "/usr/bin/sudo" "$@"
    else
        execute "sudo" "$@"
    fi
}

# 改变文件夹（及其子文件夹）权限
# @param1 文件夹路径
# @param2 文件夹要增加的权限 eg. a+rx
changePermission() {
    execute_sudo "/bin/chmod" "-R" "$2" "$1"
    execute_sudo "$CHOWN" "$USER" "$1"
    execute_sudo "$CHGRP" "$GROUP" "$1"
}

# 创建文件夹
# @param1 文件夹路径
# @param2 文件夹要增加的权限 eg. a+rx
createFolder() {
    echo '-> 创建文件夹' $1
    execute_sudo "/bin/mkdir" "-p" "$1"
    judgeSuccess
    changePermission $1 $2
}

# 删除文件夹（若存在会先备份到桌面）
# @param1 文件夹路径
delDirWithBackup() {
    if [[ -d $1 ]]; then
        echo '   ---备份要删除的文件夹到系统桌面....'
        if ! [[ -d ${NOW_HOME}/Desktop/Old_Dir/${NOW_TIME}/$1 ]]; then
            mkdir -p ${NOW_HOME}/Desktop/Old_Dir/${NOW_TIME}/$1
        fi
        cp -rf $1 ${NOW_HOME}/Desktop/Old_Dir/${NOW_TIME}/$1
        echo "   ---$1 备份完成"
        sudo rm -rf $1
    fi
}

# 重新创建文件夹（若存在会先备份到桌面）
# @param1 文件夹路径
# @param2 文件夹要增加的权限 eg. a+rx
reMkDirWithBackup() {
    delDirWithBackup $1
    createFolder $1 $2
}

# 要求 curl 忽略证书校验，绕开 curl 60 证书错误问题(为安全性，后需手动恢复)
ignoreSslCertificateProblem() {
    # 设置 git 禁用证书校验
    git config --global http.sslVerify false

    # 增加 curl 配置文件，添加禁止证书校验的参数
    if [[ ! -f ${NOW_HOME}/.curlrc ]]; then
        echo "--insecure" >> ${NOW_HOME}/.curlrc
    fi
}

# 要求 curl 恢复对证书的校验
restoreSslCertificateChecking() {
    # 设置 git 恢复证书校验
    git config --global http.sslVerify true

    # 删除 curl 配置文件，添加禁止证书校验的参数
    if [[ -f ${NOW_HOME}/.curlrc ]]; then
        rm -f ${NOW_HOME}/.curlrc
    fi
}

# 打印脚本描述头
printScriptDesHead() {
    local SCRIPT_RUNNING_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    local OS_VER=$(/usr/bin/sw_vers -productVersion)
echo '
        \033[1;32m开始执行 "自动配置 Mac 开发环境脚本"
                    version: v1.0
                    author : eisenhao
                    blog   : https://eisenhao.cn
        run time: ['$SCRIPT_RUNNING_TIME'], your macOS: ['$OS_VER']
\033[0m'
}

#################################################################
# 只安装命令行工具Command Line Tools, 不用完整安装xcode(eg.大约几个G)）
#################################################################
myFuncInstallXcodeSelect() {
    local ret=$(git --version)
    if [[ $? -eq 0 ]] && [[ -d /Library/Developer/CommandLineTools ]]; then
        echo '\033[1;36m 已安装命令行工具Command Line Tools，无需再安装
        \033[0m'
        return 0
    fi
    echo '
    ==> install 命令行工具Command Line Tools
    '
    if [[ -d /Library/Developer/CommandLineTools ]]; then
        sudo rm -rf /Library/Developer/CommandLineTools/
    fi
    echo '\033[1;36m安装命令行工具Command Line Tools\033[0m后再运行此脚本，\033[1;31m在系统弹窗中点击“安装”按钮
    若安装失败，需要自己登录：https://developer.apple.com/download/more/，搜索适合macOS的"Command Line Tools"版本下载安装即可\033[0m'
    # 只装命令行工具（不用完整安装xcode(大约几个G)）
    xcode-select --install
    exit 0
}

#################################################################
# 安装 HomeBrew
# @depend git
# 参考：cunkai.wang  https://zhuanlan.zhihu.com/p/111014448
#################################################################
myFuncInstallHomeBrew() {
    local ret=$(brew -v)
    if [[ $? -eq 0 ]]; then
        echo '\033[1;36m 已安装HomeBrew，无需再安装
        \033[0m'
        return 0
    fi
    echo '
    ==> install HomeBrew
    '
    # 删除 HomeBrew 缓存文件夹（会备份到桌面）
    delDirWithBackup ${NOW_HOME}/Library/Caches/Homebrew/
    delDirWithBackup ${NOW_HOME}/Library/Logs/Homebrew/
    # 创建 HomeBrew 文件夹
    reMkDirWithBackup ${HOMEBREW_REPOSITORY} a+rx
    reMkDirWithBackup ${HOMEBREW_PREFIX}/Caskroom a+rx
    reMkDirWithBackup ${HOMEBREW_PREFIX}/Cellar a+rx
    reMkDirWithBackup ${HOMEBREW_PREFIX}/var/homebrew a+rx
    homebrew_directories=(bin etc include lib sbin share var opt
                        share/zsh share/zsh/site-functions
                        var/homebrew var/homebrew/linked
                        Cellar Caskroom Homebrew Frameworks)
    for dir in "${homebrew_directories[@]}"; do
        if ! [[ -d "${HOMEBREW_PREFIX}/${dir}" ]]; then
            createFolder "${HOMEBREW_PREFIX}/${dir}" a+rx
        fi
    done

    # 从国内镜像，克隆 Homebrew 基本文件(32M+)
    echo '==> 克隆 Homebrew (32M+)'
    git clone $USER_BREW_GIT ${HOMEBREW_REPOSITORY}
    judgeSuccess 尝试再次运行自动脚本选择其他下载源或者切换网络 out
    echo '==> 创建brew的替身'
    find ${HOMEBREW_PREFIX}/bin -name brew -exec sudo rm -f {} \;
    ln -s ${HOMEBREW_PREFIX}/Homebrew/bin/brew ${HOMEBREW_PREFIX}/bin/brew
    judgeSuccess

    # 从国内镜像，克隆 Homebrew Core(224M+)
    echo '==> 克隆Homebrew Core(224M+)'
    createFolder ${HOMEBREW_PREFIX}/Homebrew/Library/Taps/homebrew/homebrew-core a+rx
    git clone $USER_BREW_GIT_CORE ${HOMEBREW_PREFIX}/Homebrew/Library/Taps/homebrew/homebrew-core/
    judgeSuccess 尝试再次运行自动脚本选择其他下载源或者切换网络 out

    # 从国内镜像，克隆 Homebrew Cask(248M+) 类似 AppStore
    echo '==> 克隆 Homebrew Cask(248M+) 类似 AppStore'
    createFolder ${HOMEBREW_PREFIX}/Homebrew/Library/Taps/homebrew/homebrew-cask a+rx
    git clone $USER_BREW_GIT_CASK ${HOMEBREW_PREFIX}/Homebrew/Library/Taps/homebrew/homebrew-cask/
    if [ $? -ne 0 ];then
        rm -rf ${HOMEBREW_PREFIX}/Homebrew/Library/Taps/homebrew/homebrew-cask
        echo '\033[1;31m尝试切换下载源或者切换网络, 不过Cask组件非必须模块。可以忽略\033[0m'
    else
        echo "\033[1;32m此步骤成功\033[0m"
    fi

    # 配置国内镜像源HOMEBREW BOTTLE 到 ~/.zshrc
    echo '==> 配置国内镜像源HOMEBREW BOTTLE'
    if [[ -f ${NOW_HOME}/.zshrc ]]; then
        changePermission ${NOW_HOME}/.zshrc a+rx
    fi
    # 在 ${NOW_HOME}/.zshrc 文件中，追加配置
    ret=$(cat ${NOW_HOME}/.zshrc | grep "HomeBrew Start")
    if [[ $? -ne 0 ]]; then
        echo "
# HomeBrew Start
export HOMEBREW_BOTTLE_DOMAIN=${USER_BREW_BOTTLE_DOMAIN}
export PATH=\"/usr/local/bin:\$PATH\"
export PATH=\"/usr/local/sbin:\$PATH\"
# HomeBrew END
" >> ${NOW_HOME}/.zshrc
    fi

    # 配置国内镜像源HOMEBREW BOTTLE 到 ~/.bash_profile
    if [[ -f ${NOW_HOME}/.bash_profile ]]; then
        changePermission ${NOW_HOME}/.bash_profile a+rx
    fi
    # 在 ${NOW_HOME}/.bash_profile 文件中，追加配置
    ret=$(cat ${NOW_HOME}/.bash_profile | grep "HomeBrew Start")
    if [[ $? -ne 0 ]]; then
        echo "
# HomeBrew Start
export HOMEBREW_BOTTLE_DOMAIN=${USER_BREW_BOTTLE_DOMAIN}
export PATH=\"/usr/local/bin:\$PATH\"
export PATH=\"/usr/local/sbin:\$PATH\"
# HomeBrew END
" >> ${NOW_HOME}/.bash_profile
    fi

    source ${NOW_HOME}/.zshrc
    source ${NOW_HOME}/.bash_profile

    echo "\033[1;32m 安装 HomeBrew 完成 \033[0m"

    # 设置权限
    changePermission ${HOMEBREW_REPOSITORY} a+rx
    #先暂时设置到清华大学源，中科大没有 Ruby 下载镜像
    HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
    echo '
    ==> brew -v
    '
    brew -v
    if [ $? -ne 0 ];then
        echo '\033[1;31m Brew前期配置失败\033[0m'
        HOMEBREW_BOTTLE_DOMAIN=${USER_BREW_BOTTLE_DOMAIN}
        exit 0
    else
        HOMEBREW_BOTTLE_DOMAIN=${USER_BREW_BOTTLE_DOMAIN}
        echo "\033[1;32m Brew前期配置成功\033[0m"
    fi
}

#################################################################
# 使用 brew 安装指定工具
# @param 待安装的工具
# @return 0 -- 首次成功安装；1 -- 安装失败；2 -- 之前已安装；
# @depend brew
#################################################################
myFuncBrewInstall() {
    local ret=$(brew list --formula | grep $1)
    if [[ $? -eq 0 ]]; then
        echo "\033[1;36m 已安装 $1，无需再安装
        \033[0m"
        return 2
    fi
    echo "
    ==> install $1
    "
    # 使用 brew 安装指定工具
    brew install $1

    ret=$(brew list --formula | grep $1)
    if [[ $? -eq 0 ]]; then
        echo "\033[1;32m 已成功安装 $1 \033[0m"
        return 0
    else
        echo "\033[1;31m 安装 $1 失败\033[0m"
        return 1
    fi
}

#################################################################
# 安装 OpenSSL
# @depend brew 
#################################################################
myFuncInstallOpenSSL() {
    # 使用 brew 安装 openssl
    myFuncBrewInstall openssl
    # 若不是首次成功安装，则退出函数
    if [[ $? -ne 0 ]]; then
        return $?
    fi
    # 链接 brew 安装的 openssl（系统自带的openssl版本过低）
    brew link openssl --force
    # 使用 brew 升级 openssl
    brew upgrade openssl
    local BREW_OPENSSL=$(brew list --formula | grep openssl)
    local ret=$(cat ${NOW_HOME}/.bash_profile | grep "OpenSSL Start")
    if [[ $? -ne 0 ]] && [[ -n "$BREW_OPENSSL" ]]; then
    echo "
# OpenSSL Start
export PATH=\"${HOMEBREW_PREFIX}/opt/${BREW_OPENSSL}/bin:\$PATH\"
export LDFLAGS=\"-L${HOMEBREW_PREFIX}/opt/${BREW_OPENSSL}/lib\"
export CPPFLAGS=\"-I${HOMEBREW_PREFIX}/opt/${BREW_OPENSSL}/include\"
# OpenSSL END
" >> ${NOW_HOME}/.bash_profile
    fi
}

#################################################################
# 更新 HomeBrew
#################################################################
myFuncUpdateHomeBrew() {
    local ret=$(brew -v)
    if [[ $? -ne 0 ]]; then
        echo '\033[1;36m 未安装HomeBrew，无法更新
        \033[0m'
        return 1
    fi

    # 临时要求 curl 忽略证书错误问题
    ignoreSslCertificateProblem

    # 安装 OpenSSL
    myFuncInstallOpenSSL

    echo '
    ==> brew update
    '
    brew update
    if [ $? -ne 0 ];then
        echo '
        \033[1;31m 更新 homeBrew 失败\033[0m'
    else
        echo "
        \033[1;32m 更新 homeBrew 完成\033[0m"
    fi

    # 要求 curl 恢复对证书的校验
    restoreSslCertificateChecking
}

#################################################################
# 生成 SSH Key
#################################################################
myFuncGenSSHKeys() {
    if [[ -f ${NOW_HOME}/.ssh/id_rsa ]] && [[ -f ${NOW_HOME}/.ssh/id_rsa.pub ]]; then
        echo '\033[1;36m 已有 SSH Key，无需再生成
        \033[0m'
        return 0
    fi
    echo '
    ==> Gen SSH Key
    '
    # 生成 SSH Key（-m：指定密钥格式；-t：密钥类型；-N：指定新密语为空，不用输入回车；-b：密钥长度；-f：保存文件名；-C：添加注释；-q：不输出显示）
    ssh-keygen -m PEM -t rsa -N '' -f ${NOW_HOME}/.ssh/id_rsa -b 4096 -C "${YOUR_SSHGEN_EMAIL}"
    # ssh-keygen -m PEM -t rsa -N '' -f ${NOW_HOME}/.ssh/id_rsa -b 4096 -C "${YOUR_SSHGEN_EMAIL}" -q
    
    # 检查 rsa 密钥文件是否生成
    if [[ -f ${NOW_HOME}/.ssh/id_rsa ]] && [[ -f ${NOW_HOME}/.ssh/id_rsa.pub ]]; then
        echo '\033[1;36m 生成 SSH Key成功，公钥如下: ================================================\033[0m'
        # 查看生成的 SSH key
        cat ${NOW_HOME}/.ssh/id_rsa.pub
        echo '\033[1;36m=============================================================================\033[0m'
    else
        echo '\033[1;31m 生成 SSH Key 失败\033[0m'
    fi
}

#################################################################
# 安装并配置 git
# @depend brew (系统自带的老版本 git 会被忽视)
#################################################################
myFuncInstallAndCfgGit() {
    myFuncBrewInstall git
    # 若不是首次成功安装，则退出函数
    if [[ $? -ne 0 ]]; then
        return $?
    fi
    local GIT_USER_NAME=$(git config --global user.name)
    local GIT_USER_EMAIL=$(git config --global user.email)
    if [[ -z "$GIT_USER_NAME"  &&  -z "$GIT_USER_EMAIL" ]]; then
        echo '
        ==> git global config
        '
        git config --global user.name "${YOUR_GIT_NAME}"
        git config --global user.email "${YOUR_GIT_EMAIL}"
        # 让 git 显示颜色(自动)
        git config --global color.ui auto
        # 设置为大小写敏感
        git config core.ignorecase false
        # 提交时转换为LF，检出时不转换
        git config --global core.autocrlf input
        # 允许提交包含混合换行符的文件
        git config --global core.safecrlf false
        # 查看配置
        git config --list
    else
        echo '\033[1;36m Git 已全局配置，无需再配置；\033[0m'
    fi
}

#################################################################
# 配置 Shell 别名 alias
#################################################################
myFuncCfgAlias() {
    # 在 ${NOW_HOME}/.bash_profile 文件中，追加配置 shell 的命令别名
    if [[ ! -f ${NOW_HOME}/.bash_profile ]]; then
        touch ${NOW_HOME}/.bash_profile
    fi

    local ret=$(cat ${NOW_HOME}/.bash_profile | grep "Alias Start")
    if [[ -z "$ret" ]]; then
        # 追加别名配置到 ${NOW_HOME}/.bash_profile
        echo "
# Alias Start
alias ll='ls -l'
alias vi='vim'
# Alias End
" >> ${NOW_HOME}/.bash_profile
         echo "\033[1;32m 配置 Shell 别名完成\033[0m"
    else
        echo '\033[1;36m 已配置 Shell 别名，无需再配置
        \033[0m'
    fi
}

#################################################################
# 配置 vim
#################################################################
myFuncCfgVim() {
    # 在 ${NOW_HOME}/.vimrc 文件中，追加配置
    if [[ -f ${NOW_HOME}/.vimrc ]]; then
        local ret=$(cat ${NOW_HOME}/.vimrc | grep "syntax on")
        if [[ $? -eq 0 ]]; then
            echo '\033[1;36m 已配置 vim，无需再配置
            \033[0m'
            return 0
        fi
    fi
    echo "
syntax on
set nu
colorscheme desert
" >> ${NOW_HOME}/.vimrc
    echo "\033[1;32m 配置 vim 完成\033[0m"
}

#################################################################
# 安装 powerline 字体
# @depend git
#################################################################
myFuncInstallPowerlineFonts() {
    local ret=$(ls ${NOW_HOME}/Library/Fonts |grep wedakjfhluew)
    if [[ $? -eq 0 ]]; then
        echo '\033[1;36m 已安装 powerline 字体，无需再安装
            \033[0m'
        return 0
    fi
    # clone
    git clone https://github.com/powerline/fonts.git --depth=1
    # install
    sh ./fonts/install.sh
    # clean-up a bit
    rm -rf fonts
}

#################################################################
# 安装并配置 zsh
# @depend brew (系统自带的老版本 zsh 会被忽视)
# @depend git
#################################################################
myFuncInstallAndCfgZSH() {
    # 检查 mac 系统是否自带 zsh
    local ret=$(cat /etc/shells |grep "/bin/zsh")
    if [[ $? -eq 0 ]]; then
        echo "\033[1;36m 此Mac已自带 zsh，无需再安装
        \033[0m"
    else
        myFuncBrewInstall zsh
    fi

    # 安装 iterm2 (更好看的终端，可选)
    # brew cask install iterm2

    # # 安装 wget
    # myFuncBrewInstall wget

    # 安装 oh-my-zsh 配置
    # 方案一：下载 安装 ~/.oh-my-zsh 安装脚本(自动安装)
    # sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    # # 方案二： 下载 ~/.oh-my-zsh（手动安装）
    if [[ ! -d "${NOW_HOME}/.oh-my-zsh" ]]; then
        echo '
        ==> clone oh-my-zsh
        '
        git clone git://github.com/robbyrussell/oh-my-zsh.git ${NOW_HOME}/.oh-my-zsh
        # 拷贝出 oh-my-zsh 中的文件作为自己的配置文件 （备份）
        if [[ -f ${NOW_HOME}/.zshrc ]]; then
            mv ${NOW_HOME}/.zshrc ${NOW_HOME}/.zshrc_backup${NOW_TIME}
        fi
        cp ${NOW_HOME}/.oh-my-zsh/templates/zshrc.zsh-template ${NOW_HOME}/.zshrc
    fi

    # 克隆 zsh 命令补全插件：zsh-autosuggestions
    if [[ ! -d "${NOW_HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        echo '
        ==> clone plugins zsh-autosuggestions
        '
        git clone git://github.com/zsh-users/zsh-autosuggestions ${NOW_HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    fi
    # 克隆 zsh 高亮插件: zsh-syntax-highlighting
    if [[ ! -d "${NOW_HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
        echo '
        ==> clone plugins zsh-syntax-highlighting
        '
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${NOW_HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    fi

    # 安装 zsh 跳转目录插件: autojump
    myFuncBrewInstall autojump

    # 修改 zsh 配置文件，修改主题：ZSH_THEME="robbyrussell" -> ZSH_THEME="robbyrussell"
    sed -i "" 's/ZSH_THEME="robbyrussell"/ZSH_THEME="ys"/g' ${NOW_HOME}/.zshrc

    # 修改 zsh 配置文件，添加已加插件字段：plugins=(git)
    sed -i "" 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting autojump)/g' ${NOW_HOME}/.zshrc

    # 暂时屏蔽 source $ZSH/oh-my-zsh.sh
    sed -i "" 's?source $ZSH/oh-my-zsh.sh?# source $ZSH/oh-my-zsh.sh?g'  ${NOW_HOME}/.zshrc
    
    # 添加 autojump 的配置，并恢复 上一步暂时屏蔽的 source $ZSH/oh-my-zsh.sh
    ret=$(cat ${NOW_HOME}/.zshrc | grep "autojump config")
    if [[ $? -eq 1 ]]; then
    echo "
# autojump config
[[ -f ${HOMEBREW_PREFIX}/etc/profile.d/autojump.sh ]] && . ${HOMEBREW_PREFIX}/etc/profile.d/autojump.sh

source \$ZSH/oh-my-zsh.sh"  >> ${NOW_HOME}/.zshrc
        # source ${NOW_HOME}/.oh-my-zsh/oh-my-zsh.sh
    fi

    # 在.zshrc文件中，追加 source ~/.bash_profile 保留以前配置的环境变量
    ret=$(cat ${NOW_HOME}/.zshrc | grep "retain bash profile config")
    if [[ $? -eq 1 ]] && [[ -f ${NOW_HOME}/.bash_profile ]]; then
        echo "
# retain bash profile config
source ${NOW_HOME}/.bash_profile
" >> ${NOW_HOME}/.zshrc
    fi

    # 将 brew 安装的 zsh 路径添加到 /etc/shells 文件
    ret=$(cat /etc/shells | grep "${HOMEBREW_PREFIX}/bin/zsh")
    if [[ -z "$ret" ]]; then
        execute_sudo "$CHOWN" "$USER" "/etc/shells"
        execute_sudo "/bin/echo" "${HOMEBREW_PREFIX}/bin/zsh" >> "/etc/shells"
        execute_sudo "$CHOWN" "root" "/etc/shells"
    fi

    # 将系统默认 shell 切换为 zsh
    if ! [[ "$SHELL" == "${HOMEBREW_PREFIX}/bin/zsh" ]]; then
        chsh -s ${HOMEBREW_PREFIX}/bin/zsh
        echo "\033[1;36m 已将默认 Shell 切换为 zsh，稍后请重启终端
        \033[0m"
    fi
    source ${NOW_HOME}/.zshrc
}


#################################################################
# 安装 其他
#################################################################
myOtherFunc() {
# installing Node.js
myFuncBrewInstall node@12
# Add the bin/ directory for this Node.js installation to your PATH:
# 例如 ： /usr/local/opt/node@12/bin


# install Go
myFuncBrewInstall golang
# Setting a GOROOT
# 写入下命令到 ~/.bashrc
export GOROOT="${YOUR_GO_ROOT}"
# 添加如下路径到Path
$GOROOT/bin


# install Java JDK
#eg.
# brew tap adoptopenjdk/openjdk
# brew cask install adoptopenjdk11
# 写入下命令到 ~/.bashrc
# TODO: 例如如下
JAVA_HOME=/usr/local/lib/jdk-11.0.3+7/Contents/Home
PATH=$PATH:/usr/local/lib/jdk-11.0.3+7/Contents/Home/bin


# Python3
myFuncBrewInstall python3 pipenv
python3 --version
pip3 --version

}
####################  Func Define End  ##########################



############  Script Running Start ############
# 打印脚本描述头
printScriptDesHead

# 1. 安装命令行工具Command Line Tools
echo "\033[1;36m 1. 安装命令行工具Command Line Tools \033[0m"
myFuncInstallXcodeSelect

# 2. 安装 HomeBrew
echo "\033[1;36m 2. 安装 HomeBrew \033[0m"
myFuncInstallHomeBrew

# 3. 更新 HomeBrew
echo "\033[1;36m 3. 更新 HomeBrew \033[0m"
myFuncUpdateHomeBrew

# 4. 生成 SSH Key
echo "\033[1;36m 4. 生成 SSH Key \033[0m"
myFuncGenSSHKeys

# 5. 安装并配置 git
echo "\033[1;36m 5. 安装并配置 git \033[0m"
myFuncInstallAndCfgGit

# 6. 配置 vim
echo "\033[1;36m 6. 配置 vim \033[0m"
myFuncCfgVim

# 7. 配置 Shell 别名 alias
echo "\033[1;36m 7. 配置 Shell 别名 alias \033[0m"
myFuncCfgAlias

# 8. 安装 powerline 字体
echo "\033[1;36m 8. 安装 powerline 字体 \033[0m"
myFuncInstallPowerlineFonts

# 9. 安装并配置 zsh
echo "\033[1;36m 9. 安装并配置 zsh \033[0m"
myFuncInstallAndCfgZSH
############  Script Running End ############