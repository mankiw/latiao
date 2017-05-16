%% @author Administrator
%% @doc @todo Add description to save_protocol.

-module(gate_client_safe_protocol).
-export([start_link/4, init/4]).        


%% 启动

start_link(Ref, Socket, Transport, Opts) ->
    Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
    {ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    lager:info("get safe connect ~n~n", []),
    ok = ranch:accept_ack(Ref),
     case Transport:recv(Socket, 0, 500) of
        {ok, _Data} ->
            Xml = "<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\"/></cross-domain-policy> \0",
            Transport:send(Socket, Xml);
        {error, closed} -> ok
    end.
