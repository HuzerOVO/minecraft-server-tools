# Mincraft Server Tools (MCST)

[中文文档](README_zh-cn.md)

## What is MCST

MCST are a series of scripts that are used to manage multiple local 
Minecraft server instance. It contains a command line program (mcscli)
and a interactive program (mcsshell).

With MCST, you can:
- manage multiple local instances.
- create and initialize a instance.
- start or stop a MC server instance.
- check servers status.
- watch logs for a instance.
- execute MC server command in a instance.

## Install

1. First, install `screen` program. If you are using Ubuntu/Debian, you can
   install it with command:
    ```sh
    sudo apt install screen
    ```
2. Download MCST files to directory `$HOME/.local/bin/mcst`, `$HOME` is the 
   home for user who runs MC servers.

3. Make a soft link to `$HOME/.local/bin`.
   ```sh
   ln -sv $HOME/.local/bin/mcst/mcscli $HOME/.local/bin/mcscli
   ln -sv $HOME/.local/bin/mcst/mcsshell $HOME/.local/bin/mcsshell
   ```

4. Make sure your `$PATH` contains `$HOME/.local/bin`, you can add it by
   ```sh
   export PATH="$PATH:$HOME/.local/bin"
   ```
   Add the code to your `$HOME/.basrc` or `$HOME/.zshrc` file, so that it can be
   added automatically when you login.

## Configuration

You can configurate MCST in `$HOME/.local/bin/mcst/config.sh`.

