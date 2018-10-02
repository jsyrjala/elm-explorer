module Main exposing (main)

{-| Main functionality and the entry point of the app.
-}

import Api.NflowApi
import Browser
import Browser.Navigation as Nav
import Debug exposing (log)
import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Json.Encode as E
import Page
import Page.About
import Page.Blank
import Page.DefinitionDetails
import Page.DefinitionList
import Page.ExecutorList
import Page.InstanceDetails
import Page.NotFound
import Page.Search
import Route exposing (Route, SearchQueryParams)
import Session exposing (Session)
import Types
import Url exposing (Url)



-- UPDATE


type Model
    = Redirect Session
    | NotFound Session
    | Error
    | DefinitionList Page.DefinitionList.Model
    | About Page.About.Model
    | ExecutorList Page.ExecutorList.Model
    | InstanceDetails Int Page.InstanceDetails.Model
    | DefinitionDetails String Page.DefinitionDetails.Model
    | Search SearchQueryParams Page.Search.Model


type Msg
    = Ignored
    | GotSession Session
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotAboutMsg Page.About.Msg
    | GotExecutorsMsg Page.ExecutorList.Msg
    | GotDefinitionsMsg Page.DefinitionList.Msg
    | GotInstanceDetailsMsg Page.InstanceDetails.Msg
    | GotDefinitionDetailsMsg Page.DefinitionDetails.Msg
    | GotSearchMsg Page.Search.Msg


toSession : Model -> Maybe Session
toSession page =
    case page of
        Error ->
            Nothing

        Redirect session ->
            Just session

        NotFound session ->
            Just session

        DefinitionList subModel ->
            Just (Page.DefinitionList.toSession subModel)

        About subModel ->
            Just (Page.About.toSession subModel)

        InstanceDetails _ subModel ->
            Just (Page.InstanceDetails.toSession subModel)

        ExecutorList subModel ->
            Just (Page.ExecutorList.toSession subModel)

        DefinitionDetails _ subModel ->
            Just (Page.DefinitionDetails.toSession subModel)

        Search _ subModel ->
            Just (Page.Search.toSession subModel)


init : Decode.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        maybeFlags =
            Decode.decodeValue Types.flagsDecoder flags
    in
    case maybeFlags of
        Ok flagsJson ->
            changeRouteTo (Route.fromUrl url)
                (Redirect (Session.fromViewer flagsJson.config navKey))

        Err err ->
            let
                _ =
                    Debug.log "Malformed flags / config" err
            in
            ( Error, Cmd.none )


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
                            case toSession model of
                                Just session ->
                                    ( model
                                    , Nav.pushUrl (Session.navKey session) (Url.toString url)
                                    )

                                Nothing ->
                                    let
                                        _ =
                                            Debug.log "ERROR" "No existing session! This is a bug!"
                                    in
                                    ( Error, Cmd.none )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ChangedRoute route, _ ) ->
            changeRouteTo route model

        ( GotDefinitionsMsg subMsg, DefinitionList subModel ) ->
            Page.DefinitionList.update subMsg subModel
                |> updateWith DefinitionList GotDefinitionsMsg model

        ( GotAboutMsg subMsg, About subModel ) ->
            Page.About.update subMsg subModel
                |> updateWith About GotAboutMsg model

        ( GotInstanceDetailsMsg subMsg, InstanceDetails id subModel ) ->
            Page.InstanceDetails.update subMsg subModel
                |> updateWith (InstanceDetails id) GotInstanceDetailsMsg model

        ( GotExecutorsMsg subMsg, ExecutorList subModel ) ->
            Page.ExecutorList.update subMsg subModel
                |> updateWith ExecutorList GotExecutorsMsg model

        ( GotSearchMsg subMsg, Search queryParams subModel ) ->
            Page.Search.update subMsg subModel
                |> updateWith (Search queryParams) GotSearchMsg model

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    case toSession model of
        Nothing ->
            ( Error, Cmd.none )

        Just session ->
            case maybeRoute of
                Nothing ->
                    ( NotFound session, Cmd.none )

                Just Route.Root ->
                    ( model, Route.replaceUrl (Session.navKey session) Route.DefinitionList )

                Just Route.DefinitionList ->
                    Page.DefinitionList.init session
                        |> updateWith DefinitionList GotDefinitionsMsg model

                Just Route.About ->
                    Page.About.init session
                        |> updateWith About GotAboutMsg model

                Just Route.ExecutorList ->
                    Page.ExecutorList.init session
                        |> updateWith ExecutorList GotExecutorsMsg model

                Just (Route.InstanceDetails id) ->
                    Page.InstanceDetails.init session id
                        |> updateWith (InstanceDetails id) GotInstanceDetailsMsg model

                Just (Route.DefinitionDetails id) ->
                    Page.DefinitionDetails.init session id
                        |> updateWith (DefinitionDetails id) GotDefinitionDetailsMsg model

                Just (Route.Search queryParams) ->
                    Page.Search.init session queryParams
                        |> updateWith (Search queryParams) GotSearchMsg model


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    let
        _ =
            log "update with"
    in
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Error ->
            Sub.none

        NotFound _ ->
            Sub.none

        Redirect _ ->
            case toSession model of
                Just session ->
                    Session.changes GotSession (Session.navKey session)

                Nothing ->
                    Sub.none

        InstanceDetails _ subModel ->
            Sub.map GotInstanceDetailsMsg (Page.InstanceDetails.subscriptions subModel)

        DefinitionList subModel ->
            Sub.map GotDefinitionsMsg (Page.DefinitionList.subscriptions subModel)

        DefinitionDetails _ subModel ->
            Sub.map GotDefinitionDetailsMsg (Page.DefinitionDetails.subscriptions subModel)

        About subModel ->
            Sub.map GotAboutMsg (Page.About.subscriptions subModel)

        ExecutorList subModel ->
            Sub.map GotExecutorsMsg (Page.ExecutorList.subscriptions subModel)

        Search _ subModel ->
            Sub.map GotSearchMsg (Page.Search.subscriptions subModel)



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
        Error ->
            { title = "Error"
            , body =
                [ Html.div []
                    [ Html.h1 [] [ Html.text "Error" ]
                    ]
                ]
            }

        Redirect _ ->
            viewPage Page.Other (\_ -> Ignored) Page.Blank.view

        NotFound _ ->
            viewPage Page.Other (\_ -> Ignored) Page.NotFound.view

        DefinitionList subModel ->
            viewPage Page.DefinitionList GotDefinitionsMsg (Page.DefinitionList.view subModel)

        About subModel ->
            viewPage Page.About GotAboutMsg (Page.About.view subModel)

        InstanceDetails id subModel ->
            viewPage Page.Other GotInstanceDetailsMsg (Page.InstanceDetails.view subModel)

        ExecutorList subModel ->
            viewPage Page.ExecutorList GotExecutorsMsg (Page.ExecutorList.view subModel)

        DefinitionDetails id subModel ->
            viewPage Page.Other GotDefinitionDetailsMsg (Page.DefinitionDetails.view subModel)

        Search queryParams subModel ->
            viewPage Page.Search GotSearchMsg (Page.Search.view subModel)


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }
