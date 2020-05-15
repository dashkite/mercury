import "source-map-support/register"
import assert from "assert"
import {print, test, success} from "amen"

import "fake-indexeddb/auto"
import faker from "faker"
import {flow} from "panda-garden"
import {titleCase, property} from "panda-parchment"
import fetch from "node-fetch"
import Profile from "@dashkite/zinc"
import {use, url, method, query, headers,
  request, Fetch, expect, json} from "../src"
import "./custom-event"
import "./local-storage"
import Room from "./sky"

do ->

  Profile.current = await Profile.create
    nickname: faker.internet.userName()

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
              method "get"
              headers accept: "application/json"
              request
              expect [ 200 ]
              json
              property "json"
            ]

        {entries} = await PublicAPI.search
          title: "cat"
          category: "animals"
        assert entries

      # ensure we didn't tacitly redfine an combinators
      assert method.call?

    test
      description: "zinc test"
      wait: false
      ->
        {room} = await Room.create
          title: titleCase faker.lorem.words()
          blurb: faker.lorem.sentence()
        assert room.created

        await Room.Title.put
          title: titleCase faker.lorem.words()
          address: room.address

  ]
