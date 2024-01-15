# Mincraft Server Tools (MCST)

## 什么是 MCST

MCST是一系列用于管理本地Minecraft服务实例的脚本。
它包含了一个命令行程序（mcscli）和一个交互式程序（mcsshell）。

使用MCST，你可以：
- 管理多个本地服务实例。
- 创建一个新的实例并初始化。
- 启动或者停止一个MC服务实例。
- 检查服务状态。
- 查看服务日志。
- 在服务实例中执行MC服务器指令。

## 安装

1. 首先，安装`screen`。如果你正在使用Ubuntu或者Debain，你可以使用这个命令安装：
    ```sh
    sudo apt install screen
    ```
2. 下载MCST文件，并放到`$HOME/.local/bin/mcst`目录，`$HOME`是用于运行MC服务器的
   用户的主目录。

3. 创建软连接到`$HOME/.local/bin`目录。
   ```sh
   ln -sv $HOME/.local/bin/mcst/mcscli $HOME/.local/bin/mcscli
   ln -sv $HOME/.local/bin/mcst/mcsshell $HOME/.local/bin/mcsshell
   ```

4. 确保你的`$PATH`环境变量包含`$HOME/.local/bin`，你可以这样添加：
   ```sh
   export PATH="$PATH:$HOME/.local/bin"
   ```
   把上述代码加入`$HOME/.basrc`或者`$HOME/.zshrc`文件，这样在你登录时就能自动
   添加。

## 配置

你可以用`$HOME/.local/bin/mcst/config.sh`配置MCST。

