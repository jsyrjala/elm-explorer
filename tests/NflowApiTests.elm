module NflowApiTests exposing(..)

import Test exposing (..)
import Expect

import Json.Decode as D
import Json.Encode as E
import Result
import Http

import Api.NflowApi as Api

executorJson : Test
executorJson =
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

type ExecutorsMsg = ExecutorsFetch (Result.Result Http.Error (List Api.Executor))

executorHttp : Test
executorHttp =
    describe "Executor HTTP"
      [ test "foo" <|
        \_ ->
           let
              x = Api.fetchExecutors ExecutorsFetch
           in
              -- TODO improve test
              Expect.equal 1 1
              -- Expect.equal x (Cmd.none, ExecutorsFetch)
      ]

workflowDefJson : Test
workflowDefJson =
    let
        jsonData = "{\"type\":\"creditDecision\",\"onError\":\"manualDecision\",\"states\":[{\"id\":\"internalBlacklist\",\"type\":\"start\",\"description\":\"Reject internally blacklisted customers\",\"transitions\":[\"decisionEngine\"]},{\"id\":\"decisionEngine\",\"type\":\"normal\",\"description\":\"Check if application ok for decision engine\",\"transitions\":[\"satQuery\"]},{\"id\":\"satQuery\",\"type\":\"normal\",\"description\":\"Query customer credit rating from SAT\",\"transitions\":[\"approved\",\"rejected\"]},{\"id\":\"manualDecision\",\"type\":\"manual\",\"description\":\"Manually approve or reject the application\"},{\"id\":\"approved\",\"type\":\"end\",\"description\":\"Credit Decision Approved\"},{\"id\":\"rejected\",\"type\":\"end\",\"description\":\"Credit Decision Rejected\"}],\"settings\":{\"transitionDelaysInMilliseconds\":{\"immediate\":0,\"waitShort\":30000,\"minErrorWait\":60000,\"maxErrorWait\":86400000},\"maxRetries\":17}}"
        -- workflowDef = Api.WorkflowDef  "nbank-demo-1" 1197 "nflow" "2018-08-16T18:14:38.170Z" "2018-09-16T18:52:44.857Z" "2018-09-16T19:07:44.857Z"
    in
    describe "WorkflowDef"
         [ test "workflowDefDecoder parses data" <|
            \_ ->
                let
                    parsed = D.decodeString Api.workflowDefDecoder jsonData
                in
                case parsed of
                    Result.Ok value -> Expect.equal 1 1 -- TODO implement better
                    Result.Err err -> Expect.fail "parsing failed"
         ]

type WorkflowDefMsg = WorkflowDefFetch (Result.Result Http.Error (List Api.WorkflowDef))


workflowDefHttp : Test
workflowDefHttp =
    describe "WorkflowDef HTTP"
      [ test "foo" <|
        \_ ->
           let
              x = Api.fetchWorkflowDefs WorkflowDefFetch
           in
              -- TODO improve test
              Expect.equal 1 1
              -- Expect.equal x (Cmd.none, WorkflowDefFetch)
      ]