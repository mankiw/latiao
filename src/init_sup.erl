%% @author Administrator
%% @doc @todo Add description to init_sup.


-module(init_sup).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start_link/0, init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  ets:new(ets_server_map, [set, public, named_table]),
  ets:new(ets_client_map, [set, public, named_table]),
  ets:new(seq_map, [set, public, named_table]),
  ets:insert(seq_map, {1,1}),
  Children = [],
  RestartStrategy = {one_for_one,3,10},
  {ok, {RestartStrategy, Children}}.

%% ====================================================================
%% Internal functions
%% ====================================================================


