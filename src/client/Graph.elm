module Graph exposing (query, queryWithVars)

import Http
import Json.Encode as Encode
import Json.Decode exposing (Decoder)


query : String -> Decoder a -> Http.Request a
query queryString decoder =
    queryWithVars queryString [] decoder


queryWithVars : String -> List ( String, Encode.Value ) -> Decoder entity -> Http.Request entity
queryWithVars queryString variables decoder =
    let
        jsonBody =
            Http.jsonBody <|
                Encode.object
                    [ ( "query"
                      , Encode.string queryString
                      )
                    , ( "variables"
                      , Encode.object variables
                      )
                    ]
    in
        Http.post "/graphql" jsonBody decoder
