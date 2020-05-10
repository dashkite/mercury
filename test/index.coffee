import "source-map-support/register"
import assert from "assert"
import {print, test, success} from "amen"
import faker from "faker"

import {tee, flow} from "panda-garden"
import {titleCase} from "panda-parchment"
import discover from "panda-sky-client"
import fetch from "node-fetch"
import {confidential} from "panda-confidential"

import {api, resource, content, http, json, result} from "../src"

Confidential = confidential()
{EncryptionKeyPair, SignatureKeyPair, convert, randomBytes} = Confidential

initialize = do ({client} = {}) ->
  -> client ?= discover "https://storm-api.dashkite.com", {fetch}

# resource combinators
keys = do ({keys} = {}) ->
  tee (context) ->
    keys ?= await do ->
      response = await context.api.keys().get()
      response.json()
    context.keys = keys

log = (context) -> console.log context ; context

_create = ({title, blurb}) ->
  keyPairs =
    encryption: await EncryptionKeyPair.create()
    signature: await SignatureKeyPair.create()

  title: title
  blurb: blurb
  address: convert from: "bytes", to: "safe-base64", await randomBytes 16
  publicKeys:
    encryption: keyPairs.encryption.publicKey.to "base64"
    signature: keyPairs.signature.publicKey.to "base64"

Room =

  create:
    flow [
      _create
      api initialize
      keys
      resource "rooms"
      content (room) -> room
      http.post
      json
      result "json"
    ]

do ->


  print await test "Mercury: HTTP Combinators",  [

    test
      description: "basic test"
      wait: false
      ->
        {room} = await Room.create
          title: titleCase faker.lorem.words()
          blurb: faker.lorem.sentence()
        assert room.created

  ]
