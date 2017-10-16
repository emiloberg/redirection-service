module Modal exposing (..)

import Html exposing (Html, button, div, text, h1)
import Html.Attributes exposing (type_, class, attribute, id)
import Markdown exposing (..)


modalId : String
modalId =
    -- An id to select and toggle the modal on. The random suffix makes conflicts unlikely.
    "helpModal-9fec3a447441"


viewHelpButton : Html msg
viewHelpButton =
    button [ type_ "button", class "btn btn-primary", attribute "data-toggle" "modal", attribute "data-target" <| "#" ++ modalId ] [ text "View some examples" ]


markdownOptions : Options
markdownOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = True
    }


viewHelpText : Html msg
viewHelpText =
    toHtmlWith markdownOptions [ class "modal-body" ] """
<style>
  .modal-body table {
    width: 100%;
    margin-bottom: 1rem;
    table-layout: fixed;
  }

  .modal-body h3 {
    margin-top: 5rem;
  }

  .modal-body h5 {
    margin-top: 3rem;
  }
</style>

A redirection rule is simply a mapping from a specific incoming request to a new desination. Below is listed some things to keep in mind when designing new rules.

##### Anatomy of a rule

| From  | To       | Kind            | Why                    |
|-------|----------|-----------------|------------------------|
| /amex | /gb/amex | Permanent (301) | Localize old amex page |

- **From**: The incoming request path
- **To**: The destination the request should be redirected to
- **Kind**: Whether the redirect should be cached by the client
- **Why**: The purpose of the rule to aid management


##### Rules match exactly

Only requests whose path match the "From"-value exactly will be affected by the rule. Given the above rule, the following request would and would not be redirected respectively

| Redirected  | Not redirected |
|-------------|----------------|
| /amex       | /gb/amex       |
| /amex/      | /amexs         |
| /amex?q=foo | /amex/12       |


##### Protocol, subdomain, domain and path are overridden

If any of the protocol, subdomain, domain or path are specified in the "To"-column, that part of the incoming request will be overriden with the corresponding To-value. Because of this, avoid specifying more than you have to in the To-field when making a rule.

Given the following rule:

| From      | To                                  |
|-----------|-------------------------------------|
| /advisors | https://www.izettle.com/gb/advisors |

The following redirect would happen:

| Incoming                    | Redirected to                       |
|-----------------------------|-------------------------------------|
| http://izettle.com/advisors | https://www.izettle.com/gb/advisors |

##### Query parameters are merged

If a rule specifies a query parameter, it will be merged with any existing query parameters of the incoming request. Duplicate query params is overwritten.

Given the following rule:

| From      | To                         |
|-----------|----------------------------|
| /advisors | /gb/advisors?source=google |

The following redirect would happen:

| Incoming         | Redirected to                     |
|------------------|-----------------------------------|
| /advisors?q=john | /gb/advisors?q=john&source=google |



### Expert rules

Expert rules are for advanced path matching and bulk operations and should be used sparingly as they’re more prone to errors and are more difficult to maintain.

##### Matches using Regex

Expert rules use a javascript regex syntax to match incoming rules

Given the following rule:

| From         | To           |
|--------------|--------------|
| \\/advisors? | /gb/advisors |

The following redirects would happen:

| Incoming  | Redirected to |
|-----------|---------------|
| /advisor  | /gb/advisors  |
| /advisors | /gb/advisors  |

##### Capturing groups in destination

You can define capturing groups in the From-column and insert them in the To-column using regex replace syntax.

Given the following rule:

| From                 | To              |
|----------------------|-----------------|
| \\/advisors\\/(\\d+) | /gb/advisors/$1 |

The following redirects would happen:

| Incoming        | Redirected to      |
|-----------------|--------------------|
| /advisors/1     | /gb/advisors/1     |
| /advisors/40012 | /gb/advisors/40012 |


##### Special matching tokens

A special matching token is provided "{country}" which defines a matching group for any valid izettle locale.

Given the following rule:

| From                    | To          |
|-------------------------|-------------|
| \\/{country}\\/advisors | /$1/coaches |

The following redirects would happen:

| Incoming     | Redirected to    |
|--------------|------------------|
| /gb/advisors | /gb/coaches      |
| /se/advisors | /se/coaches      |
| /jp/advisors | would not match! |

"""


viewHelpModal : Html msg
viewHelpModal =
    let
        header =
            div [ class "modal-header" ]
                [ h1 [ class "modal-title" ] [ text "Help and examples" ]
                , button [ type_ "button", class "close", attribute "data-dismiss" "modal" ] [ text "×" ]
                ]

        body =
            viewHelpText

        footer =
            div [ class "modal-footer" ]
                [ button [ type_ "button", class "btn btn-primary", attribute "data-dismiss" "modal" ] [ text "Ok" ]
                ]
    in
        div [ id modalId, class "modal" ]
            [ div [ class "modal-dialog modal-lg" ]
                [ div [ class "modal-content" ]
                    [ header
                    , body
                    , footer
                    ]
                ]
            ]
