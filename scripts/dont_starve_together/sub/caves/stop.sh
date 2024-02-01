sec=10
mcst_cmd "c_announce('The server whill shut down after $sec seconds')"
mcst_cmd "c_announce('服务器将在$sec秒后关闭')"
sleep $sec
mcst_cmd "c_shutdown(true)"
unset sec
