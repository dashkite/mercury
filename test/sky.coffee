import {identity, tee, flow} from "panda-garden"
import {property} from "panda-parchment"
import discover from "panda-sky-client"
import fetch from "node-fetch"
import Profile from "@dashkite/zinc"

import {use, resource, method, query, content, data, accept, http, request,
  expect, text, json,
  Sky, Zinc} from "../src"

{EncryptionKeyPair, SignatureKeyPair, PublicKey,
  convert, randomBytes} = Profile.Confidential

_generateRoom = ({title, blurb, host}) ->
  {keyPairs} = await Profile.current

  title: title
  blurb: blurb
  host: host
  address: convert from: "bytes", to: "safe-base64", await randomBytes 16
  publicKeys:
    encryption: keyPairs.encryption.publicKey.to "base64"
    signature: keyPairs.signature.publicKey.to "base64"

Key =

  get:
    flow [
      use Sky.client "https://http-test.dashkite.com", {fetch}
      resource "public encryption key"
      accept "text/plain"
      http.get
      text
      property "text"
    ]

key = do ({key} = {}) ->
  tee (context) ->
    # TODO make this a combinator?
    key ?= await Key.get()
    context.keys ?= {}
    context.keys.api ?= {}
    context.keys.api.encryption = key

HTTPTest =
  initialize:
    flow [
      use Sky.client "https://http-test.dashkite.com", {fetch}
      key
    ]

Room =

  create:
    flow [
      _generateRoom
      HTTPTest.initialize
      resource "rooms"
      content property "data"
      method "post"
      Zinc.sigil
      request
      json
      Zinc.grants
      property "json"
    ]

  Title:
    put:
      flow [
        HTTPTest.initialize
        resource "title"
        Sky.parameters data ({address}) -> {address}
        content data ({title}) -> {title}
        Zinc.authorized.put
        expect [ 204 ]
      ]

export default Room
