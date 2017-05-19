IP=`cat common_cfg.ini |grep local|awk -F '=' '{print $2}'`
COOKIE=`cat common_cfg.ini |grep cookie|awk -F '=' '{print $2}'`
erl -name gate_way@$IP -setcookie $COOKIE -pa _build/default/lib/*/ebin/ -s boot -s reloader
