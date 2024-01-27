# Mincraft Server Tools (MCST)

## What is MCST

~~MCST are a series of scripts that are used to manage multiple local Minecraft
server instance.~~ It contains a command line program (mcscli) and a 
interactive program (mcsshell).

Now, MCST is a series of scripts that are used formanage multiple local game
server. You can manage any game that can start in the console by MCST with a 
start script and a stop script theoretically.

With MCST, you can:
- create and initialize a instance in one line command.
- manage multiple local instances.
- check servers status.
- execute server command from your console.

## Install

1. First, install `screen` program. If you are using Ubuntu/Debian, you can
   install it with command:
    ```bash
    sudo apt-get update && sudo apt-get install screen -y
    ```
2. ~~Download MCST files to directory `$HOME/.local/bin/mcst`, `$HOME` is the home for user who runs MC servers.~~
   This way still works, but I'm going to 
   use `git clone` so that you can get updates.

3. Make a soft link to `$HOME/.local/bin`.
   ```bash
   ln -sv $HOME/.local/bin/mcst/mcscli $HOME/.local/bin/mcscli
   ln -sv $HOME/.local/bin/mcst/mcsshell $HOME/.local/bin/mcsshell
   ```

4. Make sure your `$PATH` contains `$HOME/.local/bin`, you can add it by
   ```bash
   export PATH="$PATH:$HOME/.local/bin"
   ```
   Add the code to your `$HOME/.basrc`(for bash) or `$HOME/.zshrc`(for zsh)
   file, so that it can be added automatically when you login.

## Configuration

### For MCST

You can configurate MCST in `$HOME/.mcstrc`:
```bash
# who you will run MCST with.
export CONF_USER="minecraft"
# where your server instance will store in.
export CONF_SERVER_DIR="/home/$CONF_USER/game_servers"
# you can specify which sessions is started by MCST
export CONF_SESSION_PREFIX="mcst-"
```

### For server instance

After server instance initialized, you can find a directory named `.mcst`
(it is ahidden directory) in your server instance, and you can use file 
`{start|stop|update|reload}.sh.override` in the `.mcst` to custom your 
server instance.

The `*.sh.override` file should be write with bash syntax, if you want to 
execute a server command, you can use `mcst_cmd "call a server command"`.

You can use `instance_path` in your script for getting the instance path.
