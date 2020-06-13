import "source-map-support/register"
import assert from "assert"
import {print, test, success} from "amen"

import {flow} from "panda-garden"
import {property} from "panda-parchment"
import fetch from "node-fetch"
import {use, url, method, query, headers, from, data,
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
      description: "from with data",
      wait: false
      ->
        f = flow [
          use Fetch.client mode: "cors"
          from [
            data "url"
            property "url"
            url
          ]
        ]
        context = await f url: "http://example.com/"
        assert.equal "http://example.com/", context.url.href

    test
      description: "context available in error"
      wait: false
      ->
        assert.rejects (-> FubarAPI.fubar()),
          (error) -> error.context? && error.response? && error.status == 404

  ]

  process.exit if success then 0 else 1
