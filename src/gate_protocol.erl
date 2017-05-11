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
    put(socket, Socket),
    put(transport, Transport),
    lager:info("get connect ~n", []),
    ok = ranch:accept_ack(Ref),
    exe_cmd(Socket, Transport).

deal_req(Data) ->
    {_Size, Rest} = decode_head(Data),
    deal_msgs(Rest).
   
deal_msgs(<<Size:16/little, ProtoNumb:16/little,  Rest/binary>>) ->
    Size1 = Size - 4,
    <<Content:Size1/binary, Left/binary>> =  Rest,
    Size2 = Size1 -1,
    <<Content1:Size2/binary, _End/binary>> = Content,
    deal_msg(ProtoNumb, Content1),
    deal_msgs(Left);
deal_msgs(_) ->
    ok.
 

deal_msg(ProtoNumb, Content) ->
    case ProtoNumb of
        16#5000 ->
            ServerID = binary_to_integer(Content),
            put(server_id, ServerID),
            io:format("ProtoNumb is ~p, Content is ~p", [ProtoNumb, ServerID]),
            ProtoNumbReply = 16#5001,
            Result0 = <<ProtoNumbReply:16/little,0:32/little>>,
            Result = <<Result0/binary, 0:8>>,
            ResultSize = byte_size(Result) + 2,
            Result1 = <<ResultSize:16/little, Result/binary>>,
            pack_repy(Result1);
        _ ->
            ok
    end.

exe_cmd(Socket, Transport) ->
    case Transport:recv(Socket, 0, 5000) of
        {ok, Data} ->
           lager:info("revc date ~p~n", [Data]),
           deal_req(Data),
           exe_cmd(Socket, Transport);
        _ ->
           gen_tcp:close(Socket)
    end.
    

decode_head(<<Size:16/little, _None:16, Rest/binary>>) ->
    {Size, Rest}.



pack_repy(Content) ->
    ByteSize = byte_size(Content) + 4,
    Packet = <<ByteSize:16/little,0:16,Content/binary>>,
    send(Packet).


send(Packet) ->
    Socket = get(socket),
    Transport = get(transport),
    io:format("Packet is ~p~n",[Packet]),
    Transport:send(Socket, Packet).
