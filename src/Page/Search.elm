module Page.Search exposing (view, Msg, Model, init, update, toSession, subscriptions)
{-|
Search Page or Workflow Instance listing
-}
import Html exposing (Html)
import Session exposing (Session)


type alias Model =
    { session: Session
    }


type Msg =
    GotSession Session


toSession : Model -> Session
toSession model =
    model.session

subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)

init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  (model, Cmd.none)


view : Model -> { title : String, content : Html msg }
view model =
    { title = ""
    , content = Html.text "Search"
    }

