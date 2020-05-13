import "source-map-support/register"
import assert from "assert"
import {print, test, success} from "amen"

import "fake-indexeddb/auto"
import faker from "faker"
import {flow} from "panda-garden"
import {titleCase, property} from "panda-parchment"
import fetch from "node-fetch"
import Profile from "@dashkite/zinc"
import {use, url, query, headers, http, Fetch, expect, json} from "../src"
import "./custom-event"
import "./local-storage"
import Room from "./sky"

log = (context) -> console.log context ; context

do ->

  profile = await Profile.create nickname: faker.internet.userName()
  Profile.current = profile

  print await test "Mercury: HTTP Combinators",  [

    test
      description: "fetch test"
      wait: false
      ->
        PublicAPI =
          search:
            flow [
              use Fetch.client {fetch, mode: "cors"}
              url "https://api.publicapis.org/entries"
              query property "data"
              headers accept: "application/json"
              http.get
              expect [ 200 ]
              json
              property "json"
            ]

        {entries} = await PublicAPI.search
          title: "cat"
          category: "animals"
        assert entries

    test
      description: "zinc test"
      wait: false
      ->
        {room} = await Room.create
          title: titleCase faker.lorem.words()
          blurb: faker.lorem.sentence()
          host: profile.data.nickname
        assert room.created

        await Room.Title.put
          title: titleCase faker.lorem.words()
          address: room.address

  ]
