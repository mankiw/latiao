#!/bin/bash
IP=`cat common_cfg.ini |grep local|awk -F '=' '{print $2}'`
COOKIE=`cat common_cfg.ini |grep cookie|awk -F '=' '{print $2}'`
erl -hidden -name term_`date +%Y%m%d%H%M%S`@${IP} -setcookie ${COOKIE} -remsh gate_way@${IP}

