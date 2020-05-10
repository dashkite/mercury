import {tee, flow} from "panda-garden"
import {property} from "panda-parchment"
import discover from "panda-sky-client"
import fetch from "node-fetch"
import {confidential} from "panda-confidential"

import {use, resource, content, headers, http, json, sky} from "../src"

Confidential = confidential()
{EncryptionKeyPair, SignatureKeyPair, convert, randomBytes} = Confidential

_generateRoom = ({title, blurb}) ->
  keyPairs =
    encryption: await EncryptionKeyPair.create()
    signature: await SignatureKeyPair.create()

  title: title
  blurb: blurb
  address: convert from: "bytes", to: "safe-base64", await randomBytes 16
  publicKeys:
    encryption: keyPairs.encryption.publicKey.to "base64"
    signature: keyPairs.signature.publicKey.to "base64"

Keys =

  get:
    flow [
      use sky.client
      sky.discover "https://storm-api.dashkite.com", {fetch}
      resource "keys"
      http.get
      json
      property "json"
    ]

keys = do ({keys} = {}) ->
  tee (context) ->
    keys ?= await Keys.get()
    context.keys = keys

Storm =
  initialize:
    flow [
      use sky.client
      sky.discover "https://storm-api.dashkite.com", {fetch}
      keys
    ]

Room =

  create:
    flow [
      _generateRoom
      Storm.initialize
      resource "rooms"
      content (room) -> room
      http.post
      json
      property "json"
    ]

export default Room
