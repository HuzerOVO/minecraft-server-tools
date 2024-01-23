sleep_time=10
mcst_cmd "say The server will shut down after $sleep_time seconds."
mcst_cmd "say 服务器将在$sleep_time秒后关闭。"
sleep $sleep_time
mcst_cmd "stop"
unset sleep_time
