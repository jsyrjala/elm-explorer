module Session exposing (Session, fromViewer, navKey)

import Browser.Navigation as Nav



-- TYPES


type Session
    = Guest Nav.Key



-- INFO

navKey : Session -> Nav.Key
navKey session =
    case session of

        Guest key ->
            key



-- CHANGES

{-
changes : (Session -> msg) -> Nav.Key -> Sub msg
changes toMsg key =
    Api.viewerChanges (\maybeViewer -> toMsg (fromViewer key maybeViewer)) Viewer.decoder

-}
fromViewer : Nav.Key -> Session
fromViewer key  =
    -- It's stored in localStorage as a JSON String;
    -- first decode the Value as a String, then
    -- decode that String as JSON.
    Guest key
