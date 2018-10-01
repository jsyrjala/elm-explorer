module Page.About exposing (view, Msg, Model, init, update, toSession, subscriptions)
{-|
About Page
-}
import Html exposing (Html)
import Session exposing (Session)


type alias Model =
    { session: Session
    }


type Msg
    = Opened
    | GotSession Session


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
    case msg of
      GotSession session ->
         ( { model | session = session }, Cmd.none )

      _ -> (model, Cmd.none)


view : Model -> { title : String, content : Html msg }
view model =
    { title = "About"
    , content = Html.text "About"
    }

