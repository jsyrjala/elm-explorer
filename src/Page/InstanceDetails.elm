module Page.InstanceDetails exposing (view, Msg, Model, init, update, toSession, subscriptions)
{-| Workflow instance details
-}
import Api.NflowApi exposing (Action, WorkflowSummary, getWorkflowDetails)
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Route exposing (linkTo)
import Session exposing (Session)
import Http
import Util exposing (textElem)

type alias Model =
    { session: Session
    , id: Int
    , loading: Bool
    , workflow: Maybe WorkflowSummary
    }

type Msg
  = GotSession Session
  | LoadResult (Result Http.Error WorkflowSummary)
  | Dummy

toSession : Model -> Session
toSession model =
    model.session

subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)

init : Session -> Int -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , id = id
      , loading = True
      , workflow = Nothing
      }
    , getWorkflowDetails session.config id LoadResult
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
      GotSession session ->
         ( { model | session = session }, Cmd.none )
      LoadResult (Ok workflow) ->
         ( { model | workflow = Just workflow
                   , loading = False }, Cmd.none )

      LoadResult (Err err) ->
         ( { model | workflow = Nothing
                   , loading = False }, Cmd.none )
      _ -> (model, Cmd.none)


view : Model -> { title : String, content : Html msg }
view model =
    { title = ""
    , content =
        case model.workflow of
            Just workflow ->
                div []
                [ dataTable workflow
                , actionHistory workflow
                ]
            Nothing ->
                div []
                [ text "Not found"
                ]
    }


dataTable: WorkflowSummary -> Html msg
dataTable workflow =
    div []
    [ h2 [] [ text workflow.workflowType ]
    , linkTo (Route.DefinitionDetails workflow.workflowType) [text "Go to workflow definition"]
    , text "Parent workflow:"
    , text "Created:", text workflow.created
    , text "Started:", textElem workflow.started
    , text "Modified:", text workflow.modified
    , text "Current state:"
    , text ( workflow.state ++ " (" ++ workflow.stateText ++ ")")
    , text "Current status:", text workflow.status
    , text "Next activation:", textElem workflow.started
    , text "Workflow id", text (String.fromInt workflow.id)
    , text "Business key", textElem workflow.businessKey
    , text "External id", text workflow.externalId
    ]


actionHistory: WorkflowSummary -> Html msg
actionHistory workflow =
    case workflow.actions of
        Just actions ->
            div []
            [
              h2 [] [ text "Action history"],
              table [class "pure-table"] [
                thead []
                [
                    tr []
                      [ th [] [ text "No" ]
                      , th [] [ text "State" ]
                      , th [] [ text "Description" ]
                      , th [] [ text "Retries" ]
                      , th [] [ text "Started" ]
                      , th [] [ text "Finished" ]
                      , th [] [ text "Duration" ]
                      ]
                ],
                tbody []
                     (List.map actionHistoryRow actions)
                ]
              ]
        Nothing ->
            text "No actions"

actionHistoryRow: Action -> Html msg
actionHistoryRow action =
    tr []
    [ td [] [ text "XXX" ] -- TODO compute ordinal
    , td [] [ text action.state ]
    , td [] [ text action.stateText ]
    , td [] [ text (String.fromInt action.retryNo) ]
    , td [] [ text action.executionStartTime ]
    , td [] [ textElem action.executionEndTime ]
    , td [] [ text "XXX" ] -- TODO compute duration
    ]

stateVariables: WorkflowSummary -> Html msg
stateVariables workflow =
    div []
    [
      h2 [] [ text "State variable go here"]
    ]

manage: WorkflowSummary -> Html msg
manage workflow =
    div []
    [
      h2 [] [ text "Manage"]
    ]
