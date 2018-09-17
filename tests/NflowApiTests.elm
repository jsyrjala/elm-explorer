module NflowApiTests exposing(..)

import Test exposing (..)
import Expect

import Json.Decode as D
import Json.Encode as E
import Result

import Api.NflowApi as Api

ex : Test
ex =
    let
        jsonData = "{\"id\":1,\"host\":\"nbank-demo-1\",\"pid\":1197,\"executorGroup\":\"nflow\",\"started\":\"2018-08-16T18:14:38.170Z\",\"active\":\"2018-09-16T18:52:44.857Z\",\"expires\":\"2018-09-16T19:07:44.857Z\"}"
        executor = Api.Executor 1 "nbank-demo-1" 1197 "nflow" "2018-08-16T18:14:38.170Z" "2018-09-16T18:52:44.857Z" "2018-09-16T19:07:44.857Z"
    in
    describe "Executor"
         [ test "executorDecoder parses data" <|
            \_ ->
                let
                    parsed = D.decodeString Api.executorDecoder jsonData
                in
                case parsed of
                    Result.Ok value -> Expect.equal executor value
                    Result.Err err -> Expect.fail "parsing failed"

         , test "executorEncoder encodes data" <|
            \_ ->
                let
                    encoded = E.encode 0 (Api.executorEncoder executor)
                in
                    Expect.equal jsonData encoded
        ]
