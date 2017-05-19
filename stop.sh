IP=`cat common_cfg.ini |grep local|awk -F '=' '{print $2}'`
COOKIE=`cat common_cfg.ini |grep cookie|awk -F '=' '{print $2}'`

echo "stop gamesvr ..."
rslt=`erl_call  -name gate_way@$IP -c $COOKIE -r -a 'boot stop' 2>&1`
if [ -z "$rslt" ]; then
  echo "dgame stop success"
else
  echo "dgame stop fail, reason $rslt"
fi
