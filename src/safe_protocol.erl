%% @author Administrator
%% @doc @todo Add description to save_protocol.


-module(safe_protocol).




-export([start/0]).        

-define(TCP_OPTIONS, [list, {packet, 0}, {active, false}, {reuseaddr,true}]). %这里是设置tcp的一些选项

%% 启动
start() ->
        {ok, LSocket} = gen_tcp:listen(843, ?TCP_OPTIONS), %设置一个端口为843的TCP监听
        do_accept(LSocket).


do_accept(LSocket) ->
        {ok, Socket} = gen_tcp:accept(LSocket),  
        spawn(fun() -> handle_client(Socket) end),
        do_accept(LSocket). 

handle_client(Socket) ->
        case gen_tcp:recv(Socket, 0) of
                {ok, _Data} ->
                        Xml = "<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\"/></cross-domain-policy> \0",
                        spawn(fun()-> gen_tcp:send(Socket, Xml) end),
                        handle_client(Socket); 
                {error, closed} -> ok
        end.