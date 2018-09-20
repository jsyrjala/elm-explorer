module Page.Search exposing (view, Msg, Model, init, update, toSession, subscriptions)
{-|
Search Page or Workflow Instance listing
-}
import Http
import Api.NflowApi exposing (WorkflowSummary, searchWorkflows)
import Html exposing (Attribute, Html, button, div, input, table, tbody, td, text, th, thead, tr)
import Maybe exposing (andThen)
import Session exposing (Session)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Util exposing (formatTime, spinner, textElem)

type alias Model =
    { session: Session
    , businessKey: String
    , externalId: String
    , workflowId: Maybe Int
    , parentWorkflowId: Maybe Int
    , searchResults: List WorkflowSummary
    , loading: Bool
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , businessKey = ""
      , externalId = ""
      , workflowId = Nothing
      , parentWorkflowId = Nothing
      , searchResults = []
      , loading = False
      }
    , Cmd.none -- fetch worklow defs, and possible states
    )

type Msg =
    GotSession Session
    | BusinessKeyChange String
    | ExternalIdChange String
    | WorkflowIdChange (Maybe Int)
    | ParentWorkflowIdChange (Maybe Int)
    | Search
    | SearchResult (Result Http.Error (List WorkflowSummary))


toSession : Model -> Session
toSession model =
    model.session

subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BusinessKeyChange value ->
            ( { model | businessKey = value }, Cmd.none )
        ExternalIdChange value ->
            ( { model | externalId = value }, Cmd.none )
        WorkflowIdChange value ->
            ( { model | workflowId = value }, Cmd.none )
        ParentWorkflowIdChange value ->
            ( { model | parentWorkflowId = value }, Cmd.none )
        Search ->
            ( { model
                | loading = True }, searchWorkflows SearchResult)
        SearchResult (Ok workflowSummaries) ->
            ( { model
                | searchResults = workflowSummaries
                , loading = False}, Cmd.none )
        SearchResult (Err err) ->
            ( { model | loading = False }, Cmd.none )

        _ -> (model, Cmd.none)


view : Model -> { title : String, content : Html Msg }
view model =
          let
            _ = Debug.log "model" model
          in
    { title = "Workflow instances"
    , content = div []
      [ Html.form []
        [ textField model.businessKey "Business Key" BusinessKeyChange
        , textField model.externalId "External id" ExternalIdChange
        , integerField model.workflowId "Workflow id" WorkflowIdChange
        , integerField model.parentWorkflowId "Parent workflow id" ParentWorkflowIdChange
        , searchButton model
        ]
      , if model.loading then
          spinner
        else
          case model.searchResults of
            [] -> text "No results"
            results -> searchResultsTable results
       ]
    }


searchResultsTable : List WorkflowSummary -> Html Msg
searchResultsTable workflowSummaries =
    div []
    [table [ class "pure-table" ]
      [ thead []
        [ (th [] [text "Id"])
        , (th [] [text "Workflow type"])
        , (th [] [text "State"])
        , (th [] [text "State text"])
        , (th [] [text "Status"])
        , (th [] [text "Business key"])
        , (th [] [text "External id"])
        , (th [] [text "Retries"])
        , (th [] [text "Created"])
        , (th [] [text "Started"])
        , (th [] [text "Modified"])
        , (th [] [text "Next activation"])
        ]
      , tbody []
        (List.map workflowSummaryRow workflowSummaries)
      ]
    ]


workflowSummaryRow: WorkflowSummary -> Html msg
workflowSummaryRow workflow =
  tr []
    [ td [] [text (String.fromInt workflow.id)]
    , td [] [text workflow.workflowType]
    , td [] [text workflow.state]
    , td [] [text workflow.stateText]
    , td [] [text workflow.status]
    , td [] [textElem workflow.businessKey]
    , td [] [text workflow.externalId]
    , td [] [text (String.fromInt workflow.retries)]
    , td [] [text (formatTime workflow.created)]
    , td [] [textElem (Maybe.map formatTime workflow.started)]
    , td [] [text (formatTime workflow.modified)]
    , td [] [textElem (Maybe.map formatTime workflow.nextActivation)]
    ]


textField : String -> String -> ( String -> Msg ) -> Html Msg
textField fieldValue title changeMsg =
    div []
    [ input [ value fieldValue
            , placeholder title
            , onInput changeMsg] []
    ]

integerField : Maybe Int -> String -> ( Maybe Int -> Msg ) -> Html Msg
integerField fieldValue title changeMsg =
    let
        parseInt : String -> Maybe Int
        parseInt s = String.toInt s
        v = case fieldValue of
              Just x -> String.fromInt x
              _ -> ""
    in
    div []
    [ input [ value v
            , placeholder title
            , type_ "number"
            , onInput (\x -> changeMsg (parseInt x))] []
    ]

searchButton : Model -> Html Msg
searchButton model =
    div []
    [ button [ onClick Search
             ] [ text "Search"]
    ]