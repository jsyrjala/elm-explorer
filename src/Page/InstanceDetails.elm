module Page.InstanceDetails exposing (view, Msg, Model, init, update, toSession, subscriptions)
{-| Workflow instance details
-}
import Html exposing (..)
import Session exposing (Session)

type alias Model =
    { session: Session
    , id: Int
    }

type Msg
  = GotSession Session
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
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
      GotSession session ->
         ( { model | session = session }, Cmd.none )

      _ -> (model, Cmd.none)


view : Model -> { title : String, content : Html msg }
view model =
    { title = ""
    , content =
        div []
        [ dataTable model
        ]
    }

dataTable: Model -> Html msg
dataTable model =
    div []
    [ h2 [] [ text "title" ]
    , text "Go to workflow definition"
    , text "Parent workflow:"
    , text "Created:"
    , text "Started:"
    , text "Modified:"
    , text "Current state:"
    , text "Current status:"
    , text "Next activation:"
    , text "Workflow id"
    , text "Business key"
    , text "External id"
    ]

actionHistory: Model -> Html msg
actionHistory model =
    div []
    [
      h2 [] [ text "Action history goes here"]
    ]

stateVariables: Model -> Html msg
stateVariables model =
    div []
    [
      h2 [] [ text "State variable go here"]
    ]

manage: Model -> Html msg
manage model =
    div []
    [
      h2 [] [ text "Manage"]
    ]
