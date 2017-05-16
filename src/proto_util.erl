%% @author Administrator
%% @doc @todo Add description to proto_util.


-module(proto_util).

%% ====================================================================
%% API functions
%% ====================================================================
-export([pack_server_proto/2,
         pack_client_proto/1,
         pack_cmd_proto/2,
         get_seq/0,
         binary_to_integer/1,
         decode_server_proto/1,
         decode_cmd_proto/1]).
  
%% server->gate && gate->server
%% length:4,[length1:2,gateseqid:4,serverseqid:8,[length2:2,protoid:2,content:(length2-4)]:(length1-14)]

get_seq() ->
    ets:update_counter(seq_map, 1, {2,1}).

pack_server_proto(Seq, Packet) ->
    case catch ets:lookup_element(ets_client_map, Seq, 3) of
        {_,_} ->
            RoleID  = 0;
        RoleID ->
            RoleID
    end,
    Packet1 = <<Seq:32/little, RoleID:64/little,Packet/binary>>,
    PackSize1 = byte_size(Packet1) + 2,
    <<PackSize1:16/little, Packet1/binary>>.

  
decode_server_proto(Packet) ->
    Contents = splite_packet(Packet, 2, []),
    Fun = 
        fun(<<GateSeqID:32/little,ClientSeqID:64/little,CmdList/binary>>) ->
                {GateSeqID, ClientSeqID, CmdList}
        end,
    lists:map(Fun, Contents).

pack_client_proto(Content) ->
    ByteSize = byte_size(Content) + 4,
    <<ByteSize:16/little,0:16,Content/binary>>.

pack_cmd_proto(ProtoNumb, Content) ->
    Result0 = <<ProtoNumb:16/little,Content/binary>>,
    Length = byte_size(Result0) + 2,
    <<Length:16/little, Result0/binary>>.

decode_cmd_proto(Packet) ->
    Cmds = splite_packet(Packet, 2, []),
    Fun = 
        fun(<<Proto:16/little,Content/binary>>) ->
                {Proto,Content}
        end,
    lists:map(Fun, Cmds).

binary_to_integer(B) ->
    <<B1:16/little>> = B,
    erlang:integer_to_list(B1, 16).
%% ====================================================================
%% Internal functions
%% ====================================================================


splite_packet(Packet, HeadLength, Acc) ->
    HeadBitLength = HeadLength * 8,
    <<Length:HeadBitLength/little, Rest/binary>> = Packet,
    BitLength1 = Length - HeadLength,
    <<Content:BitLength1/binary,Rest1/binary>> = Rest,
    case Rest1 of
        <<>> ->
            [Content|Acc];
        _ ->
            splite_packet(Rest1, HeadLength, [Content|Acc])
    end.