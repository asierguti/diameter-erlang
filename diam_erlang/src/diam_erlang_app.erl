%%%-------------------------------------------------------------------
%% @doc diameter-erlang public API
%% @end
%%%-------------------------------------------------------------------

-module(diam_erlang_app).

-include_lib("diameter/include/diameter.hrl").
-include_lib("diameter/include/diameter_gen_base_rfc3588.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-export([start/1,     %% start a service
         %start/2,     %%
         connect/2,   %% add a connecting transport
         call/1,      %% send using the record encoding
         cast/1]). %%,      %% send using the list encoding and detached
         % stop/1]).    %% stop a service

-export([start/0,
         connect/1,
         stop/0,
         call/0,
         cast/0,
         init/0]).

-define(DEF_SVC_NAME, ?MODULE).
-define(L, atom_to_list).

-define(SERVICE(Name), [{'Origin-Host', "localhost"},
                        {'Origin-Realm', "localhost"},
                        {'Vendor-Id', 13},
                        {'Product-Name', "Client"},
                        % {'Origin-State-Id',  diameter:origin_state_id()},
                        {'Auth-Application-Id', [0]},
                        {string_decode, false},
                        {decode_format, map},
                        {application, [{alias, common},
                                       {dictionary, diameter_gen_base_rfc6733},
                                       {module, diam_erlang_client_cb}]}]).


init() ->
    node:start(?DEF_SVC_NAME, [] ++ [T || {K,_} = T <- ?SERVICE(?DEF_SVC_NAME),
                           false == lists:keymember(K, 1, [])]).

start(_StartType, _StartArgs) ->
    diameter:start(),
    % diameter:start(?SERVICE(?DEF_SVC_NAME),),
    diam_erlang_sup:start_link().

% start(Name, Opts) ->
%     node:start(Name, Opts ++ [T || {K,_} = T <- ?SERVICE(Name),
%                                false == lists:keymember(K, 1, Opts)]).

start() ->
    start(?DEF_SVC_NAME).

start(Name)
  when is_atom(Name) ->
    start(Name, []);

start(Opts)
  when is_list(Opts) ->
    % node:start(?DEF_SVC_NAME, Opts ++ [T || {K,_} = T <- ?SERVICE(?DEF_SVC_NAME),
    %                              false == lists:keymember(K, 1, Opts)]).

    start(?DEF_SVC_NAME, Opts).




% stop() ->
%     stop(?DEF_SVC_NAME).

stop(_State) ->
    % node:stop(Name),
    ok.

% stop(Name) ->
%     node:stop(Name).

stop() ->
    stop(?DEF_SVC_NAME).

connect(Name, T) ->
    node:connect(Name, T).

connect(T) ->
    connect(?DEF_SVC_NAME, T).

call(Name) ->
    SId = diameter:session_id(?L(Name)),
    RAR = ['RAR' | #{'Session-Id' => SId,
                     'Auth-Application-Id' => 0,
                     'Re-Auth-Request-Type' => 0}],
    diameter:call(Name, common, RAR, []).

cast(Name) ->
    SId = diameter:session_id(?L(Name)),
    RAR = ['RAR', {'Session-Id', SId},
                  {'Auth-Application-Id', 0},
                  {'Re-Auth-Request-Type', 1}],
    diameter:call(Name, common, RAR, [detach]).

cast() ->
    cast(?DEF_SVC_NAME).

call() ->
    call(?DEF_SVC_NAME).