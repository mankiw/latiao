%% @author Administrator
%% @doc @todo Add description to gate_protocol.


-module(gate_protocol).
%-behaviour(ranch_protocol).

-export([start_link/4]).
-export([init/4]).

start_link(Ref, Socket, Transport, Opts) ->
        Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
        {ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    lager:error("get connect ~n", []),
    ok = ranch:accept_ack(Ref),
    exe_cmd(Socket, Transport).

exe_cmd(Socket, Transport) ->
    case Transport:recv(Socket, 0, 5000) of
        {ok, Data} ->
           io:format("revc date ~p~n", [Data]),
           Transport:send(Socket, Data);
        _ ->
           ok
    end,
    ok = Transport:close(Socket).
