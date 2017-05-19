%% @author Administrator
%% @doc @todo Add description to boot.


-module(boot).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0, stop/0]).

start() ->
    ok = application:start(crypto),
    ok = application:start(asn1),  
    ok = application:start(public_key),  
    ok = application:start(ssl),
    config:start(),%配置
    lager:start(), %日志
    ok = application:start(ranch),
    ok = application:start(gate_way).
  
stop() ->
  application:stop(ranch),
  application:stop(gate_way),
  application:stop(ssl),
  application:stop(inets),
  application:stop(public_key),
  application:stop(asn1),
  application:stop(crypto),
  lager:info("server system stopped"),
  application:stop(lager),
  erlang:halt().
%% ====================================================================
%% Internal functions
%% ====================================================================

  
