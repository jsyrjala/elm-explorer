module Types exposing (Config, Flags, flagsDecoder)

import Json.Decode as D
import Json.Encode as E
import Json.Decode.Pipeline exposing (required, optional, hardcoded)

-- Config (nflow-explorer-config.json)

type alias Config =
  { baseUrl: String
  }

type alias Flags =
  { config: Config
  }

configDecoder: D.Decoder Config
configDecoder =
    D.succeed Config
      |> required "baseUrl" D.string

flagsDecoder: D.Decoder Flags
flagsDecoder =
    D.succeed Flags
      |> required "config" configDecoder
