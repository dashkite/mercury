import "source-map-support/register"
import assert from "assert"
import {print, test, success} from "amen"

import {flow} from "panda-garden"
import {property} from "panda-parchment"
import fetch from "node-fetch"
import {use, url, method, query, headers,
  request, Fetch, expect, json} from "../src"

global.fetch = fetch

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

FubarAPI =
  fubar:
    flow [
      use Fetch.client mode: "cors"
      url "https://http-test.dashkite.com/fubar"
      method "get"
      request
      expect.ok
    ]


do ->

  print await test "Mercury: HTTP Combinators",  [

    test
      description: "fetch test"
      wait: false
      ->

        {entries} = await PublicAPI.search
          title: "cat"
          category: "animals"
        assert entries

      # ensure we didn't tacitly redefine any combinators
      assert method.call?

    test
      description: "context available in error"
      wait: false
      ->
        try
          await FubarAPI.fubar()
          assert.fail "Call to FubarAPI should throw"
        catch error
          assert.equal true, error.context?
          assert.equal true, error.response?
          assert.equal 404, error.status

  ]

  process.exit if success then 0 else 1
