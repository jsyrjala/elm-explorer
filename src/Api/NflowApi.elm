module Api.NflowApi exposing ( Executor, executorDecoder, executorEncoder, fetchExecutors
                             , WorkflowDef, fetchWorkflowDefs, workflowDefDecoder
                             , WorkflowSummary, searchWorkflows, workflowSummaryDecoder
                             , Action
                             )

import Http
import Json.Decode as D
import Json.Encode as E
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Session exposing (Session)
import Types exposing (Config)

-- Executor

-- [{"id":1,"host":"nbank-demo-1","pid":1197,"executorGroup":"nflow","started":"2018-08-16T18:14:38.170Z","active":"2018-09-16T18:52:44.857Z","expires":"2018-09-16T19:07:44.857Z"}]

-- TODO implement better
timestamp: D.Decoder String
timestamp = D.string

type alias Executor =
     { id: Int
     , host: String
     , pid: Int
     , executorGroup: String
     , started: String -- TODO timestamp parsing?
     , active: String
     , expires: String
     }

executorEncoder : Executor -> E.Value
executorEncoder executor =
  E.object
    [ ("id", E.int executor.id)
    , ("host", E.string executor.host)
    , ("pid", E.int executor.pid)
    , ("executorGroup", E.string executor.executorGroup)
    , ("started", E.string executor.started)
    , ("active", E.string executor.active)
    , ("expires", E.string executor.expires)
    ]

-- https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/
executorDecoder: D.Decoder Executor
executorDecoder =
    D.succeed Executor
      |> required "id" D.int
      |> required "host" D.string
      |> required "pid" D.int
      |> required "executorGroup" D.string
      |> required "started" timestamp
      |> required "active" timestamp
      |> required "expires" timestamp

executorListDecoder : D.Decoder (List Executor)
executorListDecoder =
    D.list executorDecoder

-- TODO config, baseUrl, read from session
fetchExecutors: Config -> (Result Http.Error (List Executor) -> msg) -> Cmd msg
fetchExecutors config resultMsg =
            Http.send resultMsg <|
                        Http.get (config.baseUrl ++ "workflow-executor") executorListDecoder

-- WorkflowDefinition

type alias State =
    { id: String
    , stateType: String -- TODO strict typing?
    , description: Maybe String
    , transition: List String
    , onFailure: Maybe String
    }

type alias WorkflowDef =
    { definitionType: String
    , name: Maybe String
    , description: Maybe String
    , onError: Maybe String
    , states: List State
    }

stateDecoder: D.Decoder State
stateDecoder =
    D.succeed State
      |> required "id" D.string
      |> required "type" D.string
      |> optional "description" (D.nullable D.string) Nothing
      |> optional "transitions" (D.list D.string) []
      |> optional "onFailure" (D.nullable D.string) Nothing

workflowDefDecoder: D.Decoder WorkflowDef
workflowDefDecoder =
    D.succeed WorkflowDef
      |> required "type" D.string
      -- nullable allows null value
      -- optional allows that key is missing
      |> optional "name" (D.nullable D.string) Nothing
      |> optional "description" (D.nullable D.string) Nothing
      |> optional "onError" (D.nullable D.string) Nothing
      |> optional "states" (D.list stateDecoder) []

workflowDefListDecoder : D.Decoder (List WorkflowDef)
workflowDefListDecoder =
    D.list workflowDefDecoder

fetchWorkflowDefs: Config -> (Result Http.Error (List WorkflowDef) -> msg) -> Cmd msg
fetchWorkflowDefs config resultMsg =
            Http.send resultMsg <|
                        Http.get (config.baseUrl ++ "workflow-definition") workflowDefListDecoder


-- WorkflowSummary
-- TODO rename to WorkflowInstance

type alias WorkflowSummary =
    { id: Int
    , businessKey: Maybe String
    , externalId: String
    , state: String
    , stateText: String
    , status: String
    , workflowType: String
    , retries: Int
    , nextActivation: Maybe String -- TODO timestamp
    , started: Maybe String -- TODO timestamp
    , parentActionId: Maybe Int
    , parentWorkflowId: Maybe Int
    , created: String -- TODO timestamp
    , modified: String -- TODO timestamp
    , actions: Maybe ( List Action )
    -- , stateVariables: Maybe String
    }

type alias Action =
    { id: Int
    , actionType: String
    , state: String
    , stateText: String
    , retryNo: Int
    , executionStartTime: String -- TODO timestamp
    , executionEndTime: Maybe String -- TODO timestmap
    , executorId: Int
    }

actionDecoder: D.Decoder Action
actionDecoder =
    D.succeed Action
      |> required "id" D.int
      |> required "type" D.string
      |> required "state" D.string
      |> required "stateText" D.string
      |> required "retryNo" D.int
      |> required "executionStartTime" timestamp
      |> optional "executionEndTime" (D.nullable timestamp) Nothing
      |> required "executorId" D.int


workflowSummaryDecoder: D.Decoder WorkflowSummary
workflowSummaryDecoder =
    D.succeed WorkflowSummary
      |> required "id" D.int
      |> optional "businessKey" (D.nullable D.string) Nothing
      |> required "externalId" D.string
      |> required "state" D.string
      |> required "stateText" D.string
      |> required "status" D.string
      |> required "type" D.string
      |> required "retries" D.int
      |> optional "nextActivation" (D.nullable timestamp) Nothing
      |> optional "started" (D.nullable timestamp) Nothing
      |> optional "parentActionId" (D.nullable D.int) Nothing
      |> optional "parentWorkflowId" (D.nullable D.int) Nothing
      |> required "created" timestamp
      |> required "modified" timestamp
      |> optional "actions" (D.nullable (D.list actionDecoder)) Nothing
      -- |> optional "stateVariables" (D.nullable D.string) Nothing

workflowSummaryListDecoder : D.Decoder (List WorkflowSummary)
workflowSummaryListDecoder =
    D.list workflowSummaryDecoder


-- TODO query parameters
searchWorkflows: Config -> (Result Http.Error (List WorkflowSummary) -> msg) -> Cmd msg
searchWorkflows config resultMsg =
            Http.send resultMsg <|
                        Http.get (config.baseUrl ++ "workflow-instance") workflowSummaryListDecoder


-- http://bank.nflow.io/nflow/api/v1/workflow-instance/id/2?include=actions,currentStateVariables,actionStateVariables
getWorkflowDetails: Config -> Int -> (Result Http.Error WorkflowSummary -> msg) -> Cmd msg
getWorkflowDetails config id resultMsg =
            Http.send resultMsg <|
                        Http.get (config.baseUrl ++
                                  "workflow-instance/id/" ++
                                  (String.fromInt id) ++
                                  "?include=actions,currentStateVariables,actionStateVariables")  workflowSummaryDecoder
