module Api.NflowApi exposing ( Executor, executorDecoder, executorEncoder, fetchExecutors
                             , WorkflowDef, fetchWorkflowDefs, workflowDefDecoder)

import Http
import Json.Decode as D
import Json.Encode as E
import Json.Decode.Pipeline exposing (required, optional, hardcoded)

-- Executor

-- [{"id":1,"host":"nbank-demo-1","pid":1197,"executorGroup":"nflow","started":"2018-08-16T18:14:38.170Z","active":"2018-09-16T18:52:44.857Z","expires":"2018-09-16T19:07:44.857Z"}]

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
      |> required "started" D.string
      |> required "active" D.string
      |> required "expires" D.string

executorListDecoder : D.Decoder (List Executor)
executorListDecoder =
    D.list executorDecoder

-- TODO config, baseUrl, read from session
fetchExecutors: (Result Http.Error (List Executor) -> msg) -> Cmd msg
fetchExecutors resultMsg =
            Http.send resultMsg <|
                        Http.get "http://bank.nflow.io/nflow/api/nflow/v1/workflow-executor" executorListDecoder

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

fetchWorkflowDefs: (Result Http.Error (List WorkflowDef) -> msg) -> Cmd msg
fetchWorkflowDefs resultMsg =
            Http.send resultMsg <|
                        Http.get "http://bank.nflow.io/nflow/api/nflow/v1/workflow-definition" workflowDefListDecoder
