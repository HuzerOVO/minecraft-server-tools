server_path="$instance_path"
backup_path=$(mktemp -d)
cp "$server_path/mods/dedicated_server_mods_setup.lua" "$backup_path/dedicated_server_mods_setup.lua"

steamcmd +@ShutdownOnFailedCommand 1 \
+@NoPromptForPassword 1 \
+force_install_dir "$server_path" \
+login anonymous \
+app_update 343050 validate \
+quit

cp "$backup_path/dedicated_server_mods_setup.lua" "$server_path/mods/dedicated_server_mods_setup.lua"
