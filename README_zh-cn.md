# Mincraft Server Tools (MCST)

## 什么是 MCST

~~MCST是一系列用于管理本地Minecraft服务实例的脚本。~~
现在，MCST理论上能够用于管理任何能够从终端启动的游戏服务器，只需要一个启动脚本
（start.sh）和一个终止脚本（stop.sh）。
它包含了一个命令行程序（mcscli）和一个交互式程序（mcsshell）。

使用MCST，你可以：
- 使用一句命令创建并初始化一个新的实例。
- 管理多个本地服务实例。
- 随时查看服务状态。
- 从你的终端发送服务器指令并执行。

## 安装

1. 首先，安装`screen`。如果你正在使用Ubuntu或者Debain，你可以使用这个命令安装：
    ```bash
    sudo apt install screen
    ```
2. ~~下载MCST文件，并放到`$HOME/.local/bin/mcst`目录，`$HOME`是用于运行MC服务器的用户的主目录。~~
   这个方法仍可以使用，但目前计划改用`git clone`方式，以方便更新。
   由于该项目仍在开发中，可能会有破坏性更新，请自行决定安装方式。

3. 创建软连接到`$HOME/.local/bin`目录。
   ```bash
   ln -sv $HOME/.local/bin/mcst/mcscli $HOME/.local/bin/mcscli
   ln -sv $HOME/.local/bin/mcst/mcsshell $HOME/.local/bin/mcsshell
   ```

4. 确保你的`$PATH`环境变量包含`$HOME/.local/bin`，你可以这样添加：
   ```bash
   export PATH="$PATH:$HOME/.local/bin"
   ```
   把上述代码加入`$HOME/.basrc`或者`$HOME/.zshrc`文件，这样在你登录时就能自动
   添加。

## 配置

### 配置MCST

你可以用`$HOME/.mcstrc`配置MCST：
```bash
# 用于运行MCST的用户
export CONF_USER="minecraft"
# 服务实例存放的位置
export CONF_SERVER_DIR="/home/$CONF_USER/game_servers"
# 标识screen会话，这样能够清楚地知道那些会话是MCST启动的
export CONF_SESSION_PREFIX="mcst-"
```

### 配置实例

在初始化服务实例后，你应该能够找到一个名为`.mcst`的文件夹（注意，这是一个隐藏
文件夹），你可以在这个文件夹中使用`{start|stop|reload|update}.sh.override`
这些文件来自定义你的服务管理脚本。

所有`*.sh.override`文件都应该使用Bash语法，如果你想执行一个服务器指令，你可以
使用这样的语句`mcst_cms "你想执行的指令"`。

你可以在你的脚本中使用`instance_path`来获取服务实例的绝对路径。
