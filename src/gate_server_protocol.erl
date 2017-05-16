%% @author Administrator
%% @doc @todo Add description to gate_protocol.


-module(gate_server_protocol).
%-behaviour(ranch_protocol).
-include("cmd.hrl").
-export([start_link/4]).
-export([init/4]).

% api
start_link(Ref, Socket, Transport, Opts) ->
    Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Opts]),
    {ok, Pid}.

init(Ref, Socket, Transport, _Opts = []) ->
    put(socket, Socket),
    put(transport, Transport),
    ok = ranch:accept_ack(Ref),
    main_socket_loop(Socket, Transport).

%internal fun
main_socket_loop(Socket, Transport) ->
    case Transport:recv_packet(Socket, 4) of
        {ok, Data} ->
           deal_req(Data),
           main_socket_loop(Socket, Transport);
        Msg ->
           lager:error("rerv un expect msg ~p", [Msg]),
           gen_tcp:close(Socket)
    end.

deal_req(<<>>) ->
    ok;
deal_req(Data) ->
    Reqs = proto_util:decode_server_proto(Data),
    [deal_one_req(Req)||Req<-Reqs].
    
   

deal_one_req({GateSeqID, ServerSeqID, CmdList}) ->
    case GateSeqID of
        0 ->
            game_server_register(GateSeqID, CmdList);
        _ ->
            ets:update_element(ets_client_map, GateSeqID, {3, ServerSeqID}),
            ClientPacket = proto_util:pack_client_proto(CmdList),
            gate_tcp:send_to_client(GateSeqID, ClientPacket)
    end.
    
game_server_register(GateSeqID, CmdList) ->
    [{ProtoNumb, Content}|_]=proto_util:decode_cmd_proto(CmdList),  
    case ProtoNumb of
        ?GAME_SERVER_REGISTER ->
            
            <<ServerID:16/little,_/binary>> = Content,
            put(server_id, ServerID),
            ets:insert(ets_server_map, {ServerID, get(socket)}),
            ProtoNumbReply = ?GAME_SERVER_REGISTER,
            Result0 = <<10000:32/little>>,
            Result1 = proto_util:pack_cmd_proto(ProtoNumbReply, Result0),
            Result2 = proto_util:pack_server_proto(GateSeqID, Result1),
            send(Result2);
        _ ->
            ok
    end.

send(Packet) ->
    Socket = get(socket),
    gen_tcp:send(Socket, Packet).
