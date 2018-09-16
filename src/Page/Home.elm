module Page.Home exposing (view, Msg, Model, init, update, toSession)
{-|
Home Page
-}
import Html exposing (Html)
import Session exposing (Session)

type alias Model =
    { session: Session

    }

type Msg
    = Opened


toSession : Model -> Session
toSession model =
    model.session


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
    , content = Html.text "Home"
    }

