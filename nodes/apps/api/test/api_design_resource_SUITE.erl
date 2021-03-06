%% -*- mode: erlang -*-
%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
%% Copyright 2011 Benjamin Nortier
%%
%%   Licensed under the Apache License, Version 2.0 (the "License");
%%   you may not use this file except in compliance with the License.
%%   You may obtain a copy of the License at
%%
%%       http://www.apache.org/licenses/LICENSE-2.0
%%
%%   Unless required by applicable law or agreed to in writing, software
%%   distributed under the License is distributed on an "AS IS" BASIS,
%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%   See the License for the specific language governing permissions and
%%   limitations under the License.

-module(api_design_resource_SUITE).
-author('Benjamin Nortier <bjnortier@gmail.com>').
-compile(export_all).
-include_lib("common_test/include/ct.hrl").

suite() -> [{timetrap,{minutes,1}}].

all() ->
	[
	 validate_body,
	 validate_design,
	 not_found,
	 create_new,
	 save,
	 delete
	].

init_per_suite(Config) ->
    ok = api_deps:start_with_api(),
    Config.

end_per_suite(_Config) ->
    api_deps:stop_with_api().

init_per_testcase(_Testcase, Config) ->
    {ok, _} = api_mem_db:start_link(),
    Config.

end_per_testcase(_Testcase, _Config) ->
    api_mem_db:stop(),
    ok.

-define(EMPTY_DESIGN, {[{<<"refs">>,
			 {[{<<"heads">>,
			    {[{<<"master">>,
			       <<"8a7ad9f7c827053faabaf84772081809317a1732">>}]}}]}}]}).

validate_design(_Config) ->
    
    Pairs = [
	     {"something%2Fwith%2Fslashes", 400, 
	      {[{<<"newDesignName">>, <<"design name can only contain letters, numbers, dashes and underscores">>}]}},
	     {"design.with.dots", 400, {[{<<"newDesignName">>, <<"design name can only contain letters, numbers, dashes and underscores">>}]}},
	     {"@&£^%&$^£", 400, {[{<<"newDesignName">>, <<"design name can only contain letters, numbers, dashes and underscores">>}]}},
	     {"iphoneDock", 200, ?EMPTY_DESIGN},
	     {"foo123ABC", 200, ?EMPTY_DESIGN},
	     {"_ABC678_", 200, ?EMPTY_DESIGN},
	     {"-x-y-z-", 200, ?EMPTY_DESIGN}
	    ],
	     
    lists:map(fun({Design, Code, Response}) ->
		      
		      {ok,{{"HTTP/1.1",Code,_}, ResponseHeaders, PostResponse}} = 
			  httpc:request(post, {"http://localhost:8001/local/" ++ Design, [], "application/json", "{}"}, [], []),
		      check_json_content_type(ResponseHeaders),
		      Response = jiffy:decode(iolist_to_binary(PostResponse))
	      end,
	      Pairs).

validate_body(_Config) ->
    Pairs = [
	     {"&@^%£$", {[{<<"invalid JSON">>,<<"&@^%£$">>},{<<"position">>,1}]}},
	     {"[]", <<"only {} accepted">>}
	    ],

    lists:map(fun({Request, ValidationError}) ->
		      
		      {ok,{{"HTTP/1.1",400,_}, ResponseHeaders, PostResponse}} = 
			  httpc:request(post, {"http://localhost:8001/local/iphonedock/", [], "application/json", Request}, [], []),
		      check_json_content_type(ResponseHeaders),
		      ValidationError = 
			  jiffy:decode(iolist_to_binary(PostResponse))
	      end,
	      Pairs).


not_found(_Config) ->
    {ok,{{"HTTP/1.1",404,_}, GetResponseHeaders, GetResponse}} = 
	httpc:request(get, {"http://localhost:8001/local/undefined/", []}, [], []),
    check_json_content_type(GetResponseHeaders),
    <<"not found">> = jiffy:decode(iolist_to_binary(GetResponse)).

create_new(_Config) ->
    %% Create
    {ok,{{"HTTP/1.1",200,_}, Headers1, PostResponse1}} = 
	httpc:request(post, {"http://localhost:8001/local/iphonedock/", [], "application/json", "{}"}, [], []),
    check_json_content_type(Headers1),
    ?EMPTY_DESIGN = jiffy:decode(iolist_to_binary(PostResponse1)),

    %% Cannot create more than once
    {ok,{{"HTTP/1.1",400,_}, Headers2, PostResponse2}} = 
	httpc:request(post, {"http://localhost:8001/local/iphonedock/", [], "application/json", "{}"}, [], []),
    check_json_content_type(Headers2),
    {[{<<"newDesignName">>, <<"already exists">>}]} = jiffy:decode(iolist_to_binary(PostResponse2)),

    %% Get design
    {ok,{{"HTTP/1.1",200,_}, _, GetResponse1}} = 
	httpc:request(get, {"http://localhost:8001/local/iphonedock/", []}, [], []),
    ?EMPTY_DESIGN = jiffy:decode(iolist_to_binary(GetResponse1)),
    
    %% Get ref
    {ok,{{"HTTP/1.1",200,_}, _, GetResponse2}} = 
	httpc:request(get, {"http://localhost:8001/local/iphonedock/refs/heads/master", []}, [], []),
    <<"8a7ad9f7c827053faabaf84772081809317a1732">> = jiffy:decode(iolist_to_binary(GetResponse2)),
    
    %% Get user designs
    {ok,{{"HTTP/1.1",200,_}, _, GetResponse3}} = 
	httpc:request(get, {"http://localhost:8001/user/local/", []}, [], []),
    {[{<<"designs">>,[<<"iphonedock">>]}]} = jiffy:decode(iolist_to_binary(GetResponse3)).


delete(_Config) ->
    %% Create design
    {ok,{{"HTTP/1.1",200,_}, Headers1, PostResponse1}} = 
	httpc:request(post, {"http://localhost:8001/local/iphonedock/", [], "application/json", "{}"}, [], []),
    check_json_content_type(Headers1),
    ?EMPTY_DESIGN = jiffy:decode(iolist_to_binary(PostResponse1)),


    %% Create geometry
    GeomJSON = {[{<<"type">>, <<"sphere">>},
		 {<<"origin">>, {[{<<"x">>, 0},
				  {<<"y">>, 0},
				  {<<"z">>, 0}]}},
		 {<<"parameters">>, {[{<<"r">>, 1.1}]}}]},
    CreateURL = "http://localhost:8001/local/iphonedock/geom/", 
    {ok,{{"HTTP/1.1",200,_}, CreateHeaders, PostResponse}} = 
	httpc:request(post, {CreateURL, [], "application/json", jiffy:encode(GeomJSON)}, [], []),
    check_json_content_type(CreateHeaders),
    {[{<<"path">>, PathBin},
      {<<"SHA">>, SHABin}]} = jiffy:decode(iolist_to_binary(PostResponse)),
    Path = binary_to_list(PathBin),
    SHA = binary_to_list(SHABin),
    "/local/iphonedock/geom/" ++ SHA = Path,

    %% Delete the design
    {ok,{{"HTTP/1.1",200,_}, DeleteHeaders, DeleteResponse}} = 
	httpc:request(delete, {"http://localhost:8001/local/iphonedock/", []}, [], []),
    check_json_content_type(DeleteHeaders),
    <<"deleted">> = jiffy:decode(iolist_to_binary(DeleteResponse)),

    %% Get user's designs
    {ok,{{"HTTP/1.1",200,_}, GetHeaders1, GetResponse1}} = 
     	httpc:request(get, {"http://localhost:8001/user/local/", []}, [], []),
    check_json_content_type(GetHeaders1),
    {[{<<"designs">>, []}]} = jiffy:decode(iolist_to_binary(GetResponse1)),

    %% Get design - not found
    {ok,{{"HTTP/1.1",404,_}, _GetHeaders2, _GetResponse2}} = 
     	httpc:request(get, {"http://localhost:8001/local/iphonedock/", []}, [], []),
    ok.
    
save(_Config) ->
    create_new(_Config),

    %% Invalid master update
    {ok,{{"HTTP/1.1",400,_}, _, PutResponse1}} = 
	httpc:request(put, {"http://localhost:8001/local/iphonedock/refs/heads/master", [],  "application/json", "{}"}, [], []),
    <<"string commit SHA expected">> = jiffy:decode(iolist_to_binary(PutResponse1)),

    %% Update master
    {ok,{{"HTTP/1.1",200,_}, _, PutResponse2}} = 
	httpc:request(put, {"http://localhost:8001/local/iphonedock/refs/heads/master", [],  "application/json", <<"\"876abf32\"">>}, [], []),
    <<"updated">> = jiffy:decode(iolist_to_binary(PutResponse2)),

    %% Get design
    {ok,{{"HTTP/1.1",200,_}, _, GetResponse1}} = 
     	httpc:request(get, {"http://localhost:8001/local/iphonedock/", []}, [], []),
    {[{<<"refs">>,
       {[{<<"heads">>,
	  {[{<<"master">>,<<"876abf32">>}]}}]}}]}
     	= jiffy:decode(iolist_to_binary(GetResponse1)),
    
    %% Get ref
    {ok,{{"HTTP/1.1",200,_}, _, GetResponse2}} = 
    	httpc:request(get, {"http://localhost:8001/local/iphonedock/refs/heads/master", []}, [], []),
    <<"876abf32">> = jiffy:decode(iolist_to_binary(GetResponse2)).


check_json_content_type(Headers) ->
    {Headers, {_, "application/json"}} = {Headers, lists:keyfind("content-type", 1, Headers)}.

    
