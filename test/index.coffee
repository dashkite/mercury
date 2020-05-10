import "source-map-support/register"
import assert from "assert"
import {print, test, success} from "amen"
import faker from "faker"

import {tee, rtee, curry, flow} from "panda-garden"
import {toUpper, titleCase, property} from "panda-parchment"
import discover from "panda-sky-client"
import fetch from "node-fetch"
import {confidential} from "panda-confidential"

# import {api, resource, content, http, json, result} from "../src"
import {use, resource, parameters, content, headers, http,
  text, json, fetch as mfetch, sky} from "../src"

log = (context) -> console.log context ; context

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

do ->


  print await test "Mercury: HTTP Combinators",  [

    test
      description: "fetch test"
      wait: false
      ->
        search =
          flow [
            use mfetch.client {fetch}
            resource "https://api.publicapis.org/entries"
            parameters (query) -> query
            headers accept: "application/json"
            http.get
            json
            property "json"
          ]
        {entries} = await search
          title: "cat"
          category: "animals"
        assert entries

    test
      description: "sky test"
      wait: false
      ->
        {room} = await Room.create
          title: titleCase faker.lorem.words()
          blurb: faker.lorem.sentence()
        assert room.created

  ]
