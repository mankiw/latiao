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
    put(transport, Transport),
    ok = ranch:accept_ack(Ref),
    main_socket_loop(Socket, Transport).

main_socket_loop(Socket, Transport) ->
    case Transport:recv(Socket, 0, 5000000) of
        {ok, Data} ->
            io:format("Data is ~p~n", [Data]),
           deal_req(Data),
           main_socket_loop(Socket, Transport);
        _ ->
           ProtoNum =?USER_LOGOUT_REQ,
           Content = <<0>>,
           Packet = proto_util:pack_cmd_proto(ProtoNum, Content),
           ServerPacket = proto_util:pack_server_proto(Packet),
           send_server(ServerPacket),
           gen_tcp:close(Socket)
    end.


deal_req(Data) ->
    {_Size, Rest} = decode_head(Data),
    io:format("Rest is ~p~n", [Rest]),
    deal_msgs(Rest).
   
deal_msgs(<<Size:16/little, ProtoNumb:16/little,  Rest/binary>>) ->
    Size1 = Size - 4,
    <<Content:Size1/binary, Left/binary>> =  Rest,
    Size2 = Size1 -1,
    case Content of
        <<Content1:Size2/binary, _End/binary>> ->
            Content1;
        <<Content1:Size1/binary, _End/binary>> ->
            Content1
    end,
    deal_msg(ProtoNumb, Content1),
    ServerContent = <<Size:16/little, ProtoNumb:16/little,Content/binary>>,
    deal_server_packet(ServerContent),
    deal_msgs(Left);
deal_msgs(_) ->
    ok.
 

deal_msg(ProtoNumb, Content) ->
    case ProtoNumb of
        ?SERVER_ID_SYN_REQ ->
            ServerID = binary_to_integer(Content),
            put(server_id, ServerID),
            case ets:lookup(ets_server_map, ServerID) of
               [{_, Socket}] ->
                    put(server_socket, Socket),
                    Seq = proto_util:get_seq(),
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
            ok
    end.


    

decode_head(<<Size:16/little, _None:16, Rest/binary>>) ->
    {Size, Rest}.

send_client(Packet) ->
    Socket = get(socket),
    Transport = get(transport),
    Transport:send(Socket, Packet).

deal_server_packet(Packet) ->
    Seq = get(seq),
    case catch proto_util:pack_server_proto(Seq, Packet) of
        Packet1 when is_binary(Packet1) ->
            send_server(Packet1);
        O ->
            io:format("client pack server packet ~p failed ,reason ~p~n", [Packet, O])
    end.

send_server(Packet) ->
    case get(server_socket) of
        undefined ->
            ok;
        Socket ->
            Transport = get(transport),
            Transport:send(Socket, Packet)
    end.