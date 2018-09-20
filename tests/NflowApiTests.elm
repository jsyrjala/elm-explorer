module NflowApiTests exposing(..)

import Test exposing (..)
import Expect

import Json.Decode as D
import Json.Encode as E
import Result
import Http

import Api.NflowApi as Api

-- Executors

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

-- WorkflowDef

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


-- WorkflowSummary


workflowSummaryJson : Test
workflowSummaryJson =
    describe "WorkflowSummary"
         [ test "workflowSummaryDecoder parses data" <|
            \_ ->
                let
                    jsonData = """
                    {"id":4,
                    "status":"finished",
                    "type":"creditDecision",
                    "parentWorkflowId":3,
                    "parentActionId":15,
                    "businessKey":"2",
                    "externalId":"078aeaa6-1295-4ef1-9766-a208d9349083",
                    "state":"approved",
                    "stateText":"Stopped in state approved",
                    "retries":0,
                    "created":"2018-09-20T07:26:05.961Z",
                    "modified":"2018-09-20T07:26:12.947Z"}
                    """
                    workflowSummary = Api.WorkflowSummary
                             4
                             (Just "2")
                             "078aeaa6-1295-4ef1-9766-a208d9349083"
                             "approved"
                             "Stopped in state approved"
                             "finished"
                             "creditDecision"
                             0
                             Nothing
                             Nothing
                             (Just 15)
                             (Just 3)
                             "2018-09-20T07:26:05.961Z"
                             "2018-09-20T07:26:12.947Z"

                    parsed = D.decodeString Api.workflowSummaryDecoder jsonData
                in
                case parsed of
                    Result.Ok value -> Expect.equal workflowSummary value -- TODO implement better
                    Result.Err err -> Expect.fail "parsing failed"

         , test "workflowSummaryDecoder parses data part 2" <|
           \_ ->
               let
                   jsonData = """
                   {"id":3,
                   "status":"inProgress",
                   "type":"processCreditApplication",
                   "externalId":"00d5b780-eab6-4f14-999f-0dd35e11750b",
                   "state":"transferMoney",
                   "stateText":"com.sun.jersey.api.client.UniformInterfaceException: Client response status: 503\\n\\tat com.sun.jersey.api.client.WebResource.ha...",
                   "nextActivation":"2018-09-21T00:28:15.539Z",
                   "started":"2018-09-21T00:28:10.000Z",
                   "retries":9,
                   "created":"2018-09-20T07:26:05.392Z",
                   "modified":"2018-09-20T15:56:15.539Z"}
                   """
                   workflowSummary = Api.WorkflowSummary
                            3
                            Nothing
                            "00d5b780-eab6-4f14-999f-0dd35e11750b"
                            "transferMoney"
                            "com.sun.jersey.api.client.UniformInterfaceException: Client response status: 503\n\tat com.sun.jersey.api.client.WebResource.ha..."
                            "inProgress"
                            "processCreditApplication"
                            9
                            (Just "2018-09-21T00:28:15.539Z")
                            (Just "2018-09-21T00:28:10.000Z")
                            Nothing
                            Nothing
                            "2018-09-20T07:26:05.392Z"
                            "2018-09-20T15:56:15.539Z"

                   parsed = D.decodeString Api.workflowSummaryDecoder jsonData
               in
               case parsed of
                   Result.Ok value -> Expect.equal workflowSummary value -- TODO implement better
                   Result.Err err ->
                       let
                         _ = Debug.log "error" err
                       in
                       Expect.fail "parsing failed"

         ]


type WorkflowSummaryMsg = WorkflowSummaryFetch (Result.Result Http.Error (List Api.WorkflowSummary))

workflowSummaryHttp : Test
workflowSummaryHttp =
    describe "WorkflowSummary HTTP"
      [ test "foo" <|
        \_ ->
           let
              x = Api.searchWorkflows WorkflowSummaryFetch
           in
              -- TODO improve test
              Expect.equal 1 1
              -- Expect.equal x (Cmd.none, WorkflowDefFetch)
      ]