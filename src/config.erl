%% @author Administrator
%% @doc @todo Add description to config.


-module(config).

-define(CONFIG_NAME, gate_config).
%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0]).

-export([get_local_ip/0, 
         get_listen_client_port/0, 
         get_listen_server_port/0,
         get_max_connect/0,
         get_is_first_run/0,
         set_not_first_run/0]).

start() ->
    {ok,_} = application:ensure_all_started(econfig),
    econfig:register_config(?CONFIG_NAME, ["common_cfg.ini"], [autoreload]),
    ok = econfig:subscribe(?CONFIG_NAME).



get_local_ip() ->
    econfig:get_value(?CONFIG_NAME, "gate_way", local_ip).

get_listen_client_port() ->
    econfig:get_integer(?CONFIG_NAME, "gate_way", listen_client_port).

get_listen_server_port() ->
    econfig:get_integer(?CONFIG_NAME, "gate_way", listen_server_port).

get_max_connect() ->
    econfig:get_integer(?CONFIG_NAME, "gate_way", max_connect).

get_is_first_run() ->
    econfig:get_boolean(?CONFIG_NAME, "gate_way", is_first_run).

set_not_first_run() ->
    econfig:set_value(?CONFIG_NAME, "gate_way", is_first_run, "false").

%% ====================================================================
%% Internal functions
%% ====================================================================


