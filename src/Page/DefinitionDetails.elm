module Page.DefinitionDetails exposing (Msg, Model, view, init, update, toSession, subscriptions)

{-| Workflow definition details
-}
import Api.NflowApi exposing (Action)
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Route exposing (linkTo)
import Session exposing (Session)
import Http
import Util exposing (textElem)

type alias Model =
    { session: Session
    , id: String
    , loading: Bool
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

init : Session -> String -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , id = id
      , loading = True
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
    , content = text ("Workflow definition " ++ model.id)
    }
