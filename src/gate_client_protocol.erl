%% @author Administrator
%% @doc @todo Add description to gate_protocol.


-module(gate_client_protocol).
%-behaviour(ranch_protocol).
-include("cmd.hrl").

-export([start_link/4]).
-export([init/4]).

start_link(Ref, Socket, Transport, Opts) ->
    Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
    {ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    put(socket, Socket),
    ok = ranch:accept_ack(Ref),
    lager:info("new connect"),
    main_socket_loop(Socket, Transport).


%internal fun
main_socket_loop(Socket, Transport) ->
    case Transport:recv_packet(Socket, 4) of
        {ok, Data} ->
           deal_req(Data),
           main_socket_loop(Socket, Transport);
        _Msg ->
           catch send_logout_to_server(),
           gen_tcp:close(Socket)
    end.

send_logout_to_server() ->
   ProtoNum =?USER_LOGOUT_REQ,
   Content = <<0>>,
   Packet = proto_util:pack_cmd_proto(ProtoNum, Content),
   Seq = get(seq),
   ServerPacket = proto_util:pack_server_proto(Seq, Packet),
   send_server(ServerPacket).


deal_req(Data) ->
    case get(seq) of
        undefined ->
            deal_client_register(Data);
        Seq ->
            SocketPacket = proto_util:pack_server_proto(Seq, Data),
            Socket = get(server_socket),
            gen_tcp:send(Socket, SocketPacket)
    end.
   
 

deal_client_register(Data) ->
    [{ProtoNumb, Content}|_]=proto_util:decode_cmd_proto(Data),  
    case ProtoNumb of
        ?SERVER_ID_SYN_REQ ->
            [ServerIDStr|_Rest] = binary:split(Content, <<0>>),
            ServerID = binary_to_integer(ServerIDStr),
            put(server_id, ServerID),
            case ets:lookup(ets_server_map, ServerID) of
               [{_, Socket}] ->
                    put(server_socket, Socket),
                    Seq = proto_util:get_seq(),
                    Name = "client_" ++ integer_to_list(Seq),
                    lager:info("client ~p, sync server ~p~n", [Seq, ServerID]),
                    register(list_to_atom(Name), self()),
                    put(seq, Seq),
                    ets:insert(ets_client_map, {Seq, get(socket), 0}),
                    ProtoNumbReply = ?SERVER_ID_SYN_RESP,
                    Result0 = <<0:32/little>>,
                    Result1 = proto_util:pack_cmd_proto(ProtoNumbReply, Result0),
                    ClientPack = proto_util:pack_client_proto(Result1),
                    send_client(ClientPack);
               _ ->
                    ProtoNumbReply = ?SERVER_ID_SYN_RESP,
                    Result0 = <<1:32/little>>,
                    Result1 = proto_util:pack_cmd_proto(ProtoNumbReply, Result0),
                    ClientPack = proto_util:pack_client_proto(Result1),
                    send_client(ClientPack)
            end;
        _ ->
            Seq = proto_util:get_seq(),
            put(seq, Seq),
            SocketPacket = proto_util:pack_server_proto(Seq, Data),
            ets:insert(ets_client_map, {Seq, get(socket), 0}),
            case get(server_socket) of
                undefined ->
                    [{_,Socket}|_] = ets:tab2list(ets_server_map),
                    put(server_socket, Socket);
                Socket ->
                    ok
            end,
            gen_tcp:send(Socket, SocketPacket),
            ok
    end.



send_client(Packet) ->
    Socket = get(socket),
    gen_tcp:send(Socket, Packet).

send_server(Packet) ->
    case get(server_socket) of
        undefined ->
            ok;
        Socket ->
            gen_tcp:send(Socket, Packet)
    end.