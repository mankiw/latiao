%% @author Administrator
%% @doc @todo Add description to boot.


-module(boot).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0]).

start() ->
    ok = application:start(crypto),
    ok = application:start(asn1),  
    ok = application:start(public_key),  
    ok = application:start(ssl),
    config:start(),%配置
    lager:start(), %日志
    ok = application:start(ranch),
    ok = application:start(gate_way).
  


%% ====================================================================
%% Internal functions
%% ====================================================================

  
