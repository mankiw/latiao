%%%-------------------------------------------------------------------
%% @doc gate_way public API
%% @end
%%%-------------------------------------------------------------------

-module(gate_way_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    Port = config:get_listen_client_port(),
    proc_lib:spawn(safe_protocol, start, []),
    lager:info("start gate server start port ~p", [Port]),
    {ok, _} = ranch:start_listener(gate_way, 100,
        gate_tcp, [{port, Port}],
        gate_protocol, []
        ).

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
