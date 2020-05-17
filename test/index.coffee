import "source-map-support/register"
import assert from "assert"
import {print, test, success} from "amen"

import {flow} from "panda-garden"
import {property} from "panda-parchment"
import fetch from "node-fetch"
import {use, url, method, query, headers,
  request, Fetch, expect, json} from "../src"

global.fetch = fetch

do ->

  print await test "Mercury: HTTP Combinators",  [

    test
      description: "fetch test"
      wait: false
      ->
        PublicAPI =
          search:
            flow [
              use Fetch.client mode: "cors"
              url "https://api.publicapis.org/entries"
              query property "data"
              method "get"
              headers accept: "application/json"
              request
              expect.status [ 200 ]
              json
              property "json"
            ]

        {entries} = await PublicAPI.search
          title: "cat"
          category: "animals"
        assert entries

      # ensure we didn't tacitly redfine an combinators
      assert method.call?

  ]

  process.exit if success then 0 else 1
