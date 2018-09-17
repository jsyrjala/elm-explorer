module Main exposing (main)
{-| Main functionality and the entry point of the app.

-}

import Debug exposing (log)
import Html exposing (..)
import Browser
import Browser.Navigation as Nav
import Page
import Page.Blank
import Page.ExecutorList
import Page.NotFound
import Route exposing (Route)
import Url exposing (Url)
import Page.Home
import Page.About
import Page.Data
import Page.ExecutorList

import Json.Decode as Decode exposing (Value)
import Session exposing (Session)

-- UPDATE

type Model
    = Redirect Session
    | NotFound Session
    | Home Page.Home.Model
    | About Page.About.Model
    | ExecutorList Page.ExecutorList.Model
    | Data Int Page.Data.Model

type Msg
    = Ignored
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotHomeMsg Page.Home.Msg
    | GotAboutMsg Page.About.Msg
    | GotExecutorsMsg Page.ExecutorList.Msg
    | GotDataMsg Page.Data.Msg
    | GotSession Session

toSession : Model -> Session
toSession page =
    case page of
        Redirect session ->
            session

        NotFound session ->
            session

        Home home ->
            Page.Home.toSession home

        About about ->
            Page.About.toSession about

        Data _ data ->
            Page.Data.toSession data

        ExecutorList executors ->
            Page.ExecutorList.toSession executors

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    case url.fragment of
                        Nothing ->
                            -- If we got a link that didn't include a fragment,
                            -- it's from one of those (href "") attributes that
                            -- we have to include to make the RealWorld CSS work.
                            --
                            -- In an application doing path routing instead of
                            -- fragment-based routing, this entire
                            -- `case url.fragment of` expression this comment
                            -- is inside would be unnecessary.
                            ( model, Cmd.none )

                        Just _ ->
                            ( model
                            , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                            )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ChangedRoute route, _ ) ->
            changeRouteTo route model

        ( GotHomeMsg subMsg, Home home ) ->
            Page.Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        ( GotAboutMsg subMsg, About about ) ->
            Page.About.update subMsg about
                |> updateWith About GotAboutMsg model

        ( GotDataMsg subMsg, Data id data ) ->
            Page.Data.update subMsg data
                |> updateWith (Data id) GotDataMsg model

        ( GotExecutorsMsg subMsg, ExecutorList executors ) ->
            Page.ExecutorList.update subMsg executors
                |> updateWith ExecutorList GotExecutorsMsg model

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


init : flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    -- TODO pass config.json via flags, and store it to Session
    changeRouteTo (Route.fromUrl url)
            (Redirect (Session.fromViewer navKey))

changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let _ = log "changeRouteTo" maybeRoute
        session = toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )
        Just Route.Root ->
            ( model, Route.replaceUrl (Session.navKey session) Route.Home )
        Just Route.Home ->
            Page.Home.init session
                |> updateWith Home GotHomeMsg model
        Just Route.About ->
            Page.About.init session
                |> updateWith About GotAboutMsg model
        Just Route.ExecutorList ->
            Page.ExecutorList.init session
                |> updateWith ExecutorList GotExecutorsMsg model
        Just (Route.Data id) ->
            Page.Data.init session id
                |> updateWith (Data id) GotDataMsg model

updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    let _ = log "update with"
    in
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        NotFound _ ->
            Sub.none

        Redirect _ ->
            Session.changes GotSession (Session.navKey (toSession model))

        Data _ data ->
            Sub.map GotDataMsg (Page.Data.subscriptions data)

        Home home ->
            Sub.map GotHomeMsg (Page.Home.subscriptions home)

        About about ->
            Sub.map GotAboutMsg (Page.About.subscriptions about)

        ExecutorList executorList ->
            Sub.map GotExecutorsMsg (Page.ExecutorList.subscriptions executorList)


-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        viewPage page toMsg config =
            let
                { title, body } =
                    Page.view page config
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model of
        Redirect _ ->
            viewPage Page.Other (\_ -> Ignored) Page.Blank.view

        NotFound _ ->
            viewPage Page.Other (\_ -> Ignored) Page.NotFound.view

        Home home ->
            viewPage Page.Home GotHomeMsg (Page.Home.view home)

        About about ->
            viewPage Page.About GotAboutMsg (Page.About.view about)

        Data id data ->
            viewPage Page.Data GotDataMsg (Page.Data.view { data | id = id } )

        ExecutorList executors ->
            viewPage Page.ExecutorList GotExecutorsMsg (Page.ExecutorList.view executors)


main : Program () Model Msg
main =
    let _ = log "start" "now"
    in
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }