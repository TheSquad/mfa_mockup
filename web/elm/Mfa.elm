module Mfa exposing (..)

import Html exposing (..)
import Html.Attributes as Attr exposing (type', value, style)
import Html.Events exposing (onInput, onSubmit, onClick)
import Html.App
import Platform.Cmd
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing ((:=))
import Dict
import FontAwesome.Web as Icon
import Bootstrap.Buttons as Btn exposing (..)
import Bootstrap.Grid exposing (..)

-- MAIN

main : Program Never
main =
  Html.App.program
    { init = init
    , update = update
    , view = newview
    , subscriptions = subscriptions
    }

-- CONSTANTS

socketServer : String
--socketServer = "ws://52.50.229.134:9402/socket/websocket"
socketServer = "ws://localhost:9402/socket/websocket"

-- MODEL

type Status
  = None
  | Waiting
  | Accepted
  | Rejected
  | Timeout

type Msg
  = Checkout
  | ReceiveAccepted JE.Value
  | ReceiveRejected JE.Value
  | ReceiveTimeout JE.Value
  | SendMessage
  | SetNewMessage String
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | ReceiveChatMessage JE.Value
  | JoinChannel
  | LeaveChannel
  | ShowJoinedMessage String
  | ShowLeftMessage String
  | NoOp
  | Ping JE.Value

type alias Model =
  { newMessage : String
  , messages : List String
  , phxSocket : Phoenix.Socket.Socket Msg
  , ping : Int
  , status : Status
  }

type alias Model2 =
  { status : String
  , phxSocket : Phoenix.Socket.Socket Msg
  }

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
  Phoenix.Socket.init socketServer
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "waiting" "rooms:lobby" Ping
    |> Phoenix.Socket.on "accepted" "rooms:lobby" ReceiveAccepted
    |> Phoenix.Socket.on "rejected" "rooms:lobby" ReceiveRejected
    |> Phoenix.Socket.on "timeout" "rooms:lobby" ReceiveTimeout

initModel : Model
initModel =
  Model "" [] initPhxSocket 0 None

init : ( Model, Cmd Msg )
init =
  ( initModel, Cmd.none )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg

-- COMMANDS


-- PHOENIX STUFF

type alias ChatMessage =
  { user : String
  , body : String
  , value : Int
  }

chatMessageDecoder : JD.Decoder ChatMessage
chatMessageDecoder =
  JD.object3 ChatMessage
    ("user" := JD.string)
    ("body" := JD.string)
    ("value" := JD.int)

-- UPDATE

userParams : JE.Value
userParams =
  JE.object [ ("user_id", JE.string "123") ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    SendMessage ->
      let
        payload = (JE.object [ ("user", JE.string "user"), ("body", JE.string model.newMessage) ])
        push' =
          Phoenix.Push.init "new:msg" "rooms:lobby"
            |> Phoenix.Push.withPayload payload
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model
          | newMessage = ""
          , phxSocket = phxSocket
          }
        , Cmd.map PhoenixMsg phxCmd
        )

    SetNewMessage str ->
      ( { model | newMessage = str }
      , Cmd.none
      )

    ReceiveChatMessage raw ->
      case JD.decodeValue chatMessageDecoder raw of
        Ok chatMessage ->
          ( { model | messages = (chatMessage.user ++ ": " ++ chatMessage.body) :: model.messages }
          , Cmd.none
          )
        Err error ->
          ( model, Cmd.none )

    JoinChannel ->
      let
        channel =
          Phoenix.Channel.init "rooms:lobby"
            |> Phoenix.Channel.withPayload userParams
            |> Phoenix.Channel.onJoin (always (ShowJoinedMessage "rooms:lobby"))
            |> Phoenix.Channel.onClose (always (ShowLeftMessage "rooms:lobby"))

        (phxSocket, phxCmd) = Phoenix.Socket.join channel model.phxSocket
      in
        ({ model | phxSocket = (Debug.log "phoenix socket on join" phxSocket) }
        , Cmd.map PhoenixMsg phxCmd
        )

    LeaveChannel ->
      let
        (phxSocket, phxCmd) = Phoenix.Socket.leave "rooms:lobby" model.phxSocket
      in
        ({ model | phxSocket = phxSocket, status = None, ping = 0}
        , Cmd.map PhoenixMsg phxCmd
        )

    ShowJoinedMessage channelName ->
      ( { model | messages = ("Joined channel " ++ channelName) :: model.messages }
      , Cmd.none
      )

    ShowLeftMessage channelName ->
      ( { model | messages = ("Left channel " ++ channelName) :: model.messages }
      , Cmd.none
      )

    Checkout ->
        let
            payload = (JE.object [ ("user", JE.string "user"), ("body", JE.string "42") ])
            push' =
                Phoenix.Push.init "new:msg" "rooms:lobby"
                |> Phoenix.Push.withPayload payload
            (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
        in
            ( { model
                | newMessage = ""
                , phxSocket = phxSocket
                , ping = 0
            }
            , Cmd.map PhoenixMsg phxCmd
            )
    ReceiveAccepted raw ->
        (  { model | status = Accepted }
        ,  Cmd.none
        )

    ReceiveRejected raw ->
        (  { model | status = Rejected }
        ,  Cmd.none
        )

    ReceiveTimeout raw ->
        (  { model | status = Timeout }
        ,  Cmd.none
        )

    Ping raw ->
        case JD.decodeValue chatMessageDecoder raw of
        Ok pm ->
          ( { model | ping = pm.value, status = Waiting}
        , Cmd.none)
        Err error ->
          ( model, Cmd.none )

    NoOp ->
      ( { model | ping = 0, status = None}, Cmd.none )

-- VIEW

(=>) = (,)

color : Status -> String
color msg =
    case msg of
        Accepted ->
            Debug.log "color" "#00D000"

        Rejected ->
            Debug.log "color" "#D00000"

        Timeout ->
            Debug.log "color" "#DDDDDD"

        Waiting ->
            Debug.log "color" "#123456"

        None ->
            Debug.log "color" "#FFF"

newview : Model -> Html Msg
newview model =
    case model.status of
        None ->
            layout (page_checkout model)
        Waiting ->
            layout (page_waiting model)
        Accepted ->
            layout (page_accepted model)
        Rejected ->
            layout (page_rejected model)
        Timeout ->
            layout (page_retry model)

page_retry: Model -> Html Msg
page_retry model =
    div[ style ["width" => "100%"] ][img [ Attr.src "http://www.theislandbath.com/assets/images/Icons/oops2.png" ][]
         ,br [][]
         ,br [][]
         ,h3 [] [text "It seems that you didn't accept in time... should we retry ?"]
         ,Btn.btn
             BtnSuccess
             [BtnBlock]
             []
             [ onClick Checkout ] --onClick Retry
             [
              text "Yes"
             ]
         ,Btn.btn
             BtnDanger
             [BtnBlock]
             []
             [ onClick LeaveChannel ] --onClick Retry
             [
              text "No"
             ]
         ]

layout: Html Msg -> Html Msg
layout page =
    containerFluid [
         row [column [ExtraSmall Two, Small Two, Medium Two, Large Two]
                  []
             ,column [ExtraSmall Eight, Small Eight, Medium Eight, Large Eight]
                 [ page ]
             ,column [ExtraSmall Two, Small Two, Medium Two, Large Two]
                 []
             ]
        ]

page_checkout : Model -> Html Msg
page_checkout model =
    div []
        [h2 [][ text "The total is of $ 42.0 " ]
        ,Btn.btn
            BtnPrimary
            [BtnBlock]
            []
            [ onClick JoinChannel ]
            [
             Html.i [ Attr.class "fa fa-shopping-cart fa-4x fa-fw" ][]
            ]
        ]

page_waiting: Model -> Html Msg
page_waiting model =
    div [] [
         div [
          style
              [ "background-color" => color model.status
              , "width" => "100%"
              , "border-radius" => "4px"
              , "left" => "center"
              , "top" => "center"
              , "color" => "white"
              ]
         ]
             [
              div [] [
                   h1 [ style ["align-items" => "center"] ] [text "Waiting for your acceptation..."]
                  ]
             ,div [
                  style
                      ["left" => "center"
                      ,"align" => "center"
                      , "justify-content" => "center"]
                 ] [
                   Html.i [ style ["align" => "center"], Attr.class "fa fa-spinner fa-spin fa-3x fa-fw" ] []
                  ]
             ]
        , div [
              style
                  [ "top" => "bottom"
                  , "color" => "#444" ]
             ] [
             ]
        ]

page_accepted: Model -> Html Msg
page_accepted model =
    div [
     style
         [ "background-color" => color model.status
         , "width" => "100%"
         , "height" => "150px"
         , "border-radius" => "4px"
         , "left" => "center"
         , "top" => "center"
         , "color" => "white"
         ]
    ][h1[style ["left" => "center"
               ,"top" => "center"]
        ][ text "Your purchase has been confirmed!" ]
     ,br [][]
     ,br [][]
     ,br [][]
     ,br [][]
     ,Btn.btn
         BtnPrimary
         [BtnBlock]
         []
         [ onClick LeaveChannel ] --onClick Retry
         [
          text "Go back HOME"
         ]
     ]

page_rejected: Model -> Html Msg
page_rejected model =
    div [
     style
         [ "background-color" => color model.status
         , "width" => "100%"
         , "height" => "150px"
         , "border-radius" => "4px"
         , "left" => "center"
         , "top" => "center"
         , "color" => "white"
         ]
    ][h1[style ["left" => "center"
               ,"top" => "center"]
        ][ text "Your purchase has been rejected !" ]
     ,br [][]
     ,h3 [] [text "It seems that you didn't accept in time... should we retry ?"]
     ,br [][]
     ,br [][]
     ,Btn.btn
         BtnSuccess
         [BtnBlock]
         []
         [ onClick Checkout ] --onClick Retry
         [
          text "Yes"
         ]
     ,Btn.btn
         BtnDanger
         [BtnBlock]
         []
         [ onClick LeaveChannel ] --onClick Retry
         [
          text "No"
         ]
     ]

view : Model -> Html Msg
view model =
  div []
    [ h3 [] [ text "Channels:" ]
    , div
        []
        [ button [ onClick JoinChannel ] [ text "Join channel" ]
        , button [ onClick LeaveChannel ] [ text "Leave channel" ]
        ]
    , channelsTable (Dict.values model.phxSocket.channels)
    , br [] []
    , h3 [] [ text "Messages:" ]
    , newMessageForm model
    , ul [] ((List.reverse << List.map renderMessage) model.messages)
    ]

channelsTable : List (Phoenix.Channel.Channel Msg) -> Html Msg
channelsTable channels =
  table []
    [ tbody [] (List.map channelRow channels)
    ]

channelRow : (Phoenix.Channel.Channel Msg) -> Html Msg
channelRow channel =
  tr []
    [ td [] [ text channel.name ]
    , td [] [ (text << toString) channel.payload ]
    , td [] [ (text << toString) channel.state ]
    ]

newMessageForm : Model -> Html Msg
newMessageForm model =
  form [ onSubmit SendMessage ]
    [ input [ type' "text", value model.newMessage, onInput SetNewMessage ] []
    ]

renderMessage : String -> Html Msg
renderMessage str =
  li [] [ text str ]
