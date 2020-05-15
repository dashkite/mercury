import {identity, tee, flow} from "panda-garden"
import {property} from "panda-parchment"
import discover from "panda-sky-client"
import fetch from "node-fetch"
import Profile from "@dashkite/zinc"

import {use, resource, method, query, content, data, accept, authorize,
  request, expect, text, json, Sky, Zinc} from "../src"

{EncryptionKeyPair, SignatureKeyPair, PublicKey,
  convert, randomBytes} = Profile.Confidential

generateAddress = ->
  convert
    from: "bytes"
    to: "safe-base64"
    await randomBytes 16

generateRoom = ({title, blurb, host}) ->
  profile = await Profile.current
  {publicKeys, data: {nickname}} = profile
  address = await generateAddress()
  {title, blurb, host: nickname, address, publicKeys}

Key =

  get:
    flow [
      use Sky.client "https://http-test.dashkite.com", {fetch}
      resource "public encryption key"
      method "get"
      accept "text/plain"
      request
      text
      property "text"
    ]

key = do ({key} = {}) ->
  tee (context) ->
    key ?= await Key.get()
    context.keys ?= {}
    context.keys.api ?= {}
    context.keys.api.encryption = key

initialize =

  flow [
    use Sky.client "https://http-test.dashkite.com", {fetch}
    key
  ]

Room =

  create:
    flow [
      generateRoom
      initialize
      resource "rooms"
      content property "data"
      method "post"
      authorize Zinc.sigil
      request
      json
      Zinc.grants
      property "json"
    ]

  Title:
    put:
      flow [
        initialize
        resource "title"
        method "put"
        Sky.parameters data ({address}) -> {address}
        content data ({title}) -> {title}
        authorize Zinc.claim
        request
        expect [ 204 ]
      ]

export default Room
