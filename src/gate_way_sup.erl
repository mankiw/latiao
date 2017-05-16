%%%-------------------------------------------------------------------
%% @doc gate_way1 top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(gate_way_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    start_client_tcp_safe_pool(),
    start_server_tcp_logic_pool(),
    start_client_tcp_logic_pool(),
    Children = 
        [{init_sup, % 子监控树，包括：和DB相关的初始化+各种ETS表的初始化
          {init_sup, start_link, []},
          permanent, infinity, supervisor, [init_sup]}],
    RestartStrategy = {one_for_one, 30, 10},
    {ok, {RestartStrategy, Children}}.

%%====================================================================
%% Internal functions
%%====================================================================
start_client_tcp_logic_pool() ->
    Port = config:get_listen_client_port(),
    {ok, _} = ranch:start_listener(client_gate_way, 100,
        gate_tcp, [{port, Port}],
        gate_client_protocol, []
        ).

start_client_tcp_safe_pool() ->
    Port = 843,
    {ok, _} = ranch:start_listener(client_safe_gate_way, 100,
        gate_tcp, [{port, Port}],
        gate_client_safe_protocol, []
        ).

start_server_tcp_logic_pool() ->
    Port = config:get_listen_server_port(),
    {ok, _} = ranch:start_listener(server_gate_way,  10,
        gate_tcp, [{port, Port}],
        gate_server_protocol, []
        ).