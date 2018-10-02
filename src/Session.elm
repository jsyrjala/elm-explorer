module Session exposing (Session, changes, fromViewer, navKey)

import Browser.Navigation as Nav
import Types exposing (Config)



-- TYPES


type alias Session =
    { config : Config
    , navKey : Nav.Key
    }



-- INFO


navKey : Session -> Nav.Key
navKey session =
    session.navKey



-- CHANGES


changes : (Session -> msg) -> Nav.Key -> Sub msg
changes toMsg key =
    Sub.none



-- Api.viewerChanges (\maybeViewer -> toMsg (fromViewer key maybeViewer)) Viewer.decoder


fromViewer : Config -> Nav.Key -> Session
fromViewer config key =
    -- It's stored in localStorage as a JSON String;
    -- first decode the Value as a String, then
    -- decode that String as JSON.
    Session config key
