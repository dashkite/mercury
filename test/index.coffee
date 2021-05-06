import assert from "assert"
import {print, test, success} from "amen"

import * as _ from "@dashkite/joy"
import fetch from "node-fetch"
import * as $ from "../src"
import * as k from "@dashkite/katana"

globalThis.fetch ?= fetch
global.Request ?= fetch.Request

PublicAPI =
  search:
    _.flow [
      $.request [
        $.url "https://api.publicapis.org/entries"
        $.query
        $.method "get"
        $.headers accept: "application/json"
        $.expect.status [ 200 ]
      ]
      $.response [ $.json ]
    ]

  fail:
    _.flow [
      $.request [
        $.mode "cors"
        $.url "https://api.publicapis.org/entries"
        $.query
        $.method "get"
        $.headers accept: "application/json"
        $.expect.status [ 300 ]
      ]
      $.response [ $.json ]
    ]

FubarAPI =
  fubar:
    _.flow [
      $.request [
        $.mode "cors"
        $.url "https://api.publicapis.org/fubar"
        $.method "get"
        $.expect.ok
      ]
      $.response [ $.json ]
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
        assert.equal true, _.isArray entries
        assert.equal true, entries.length > 0
        assert.equal true, entries[0].API?


    test
      description: "failing fetch test"
      wait: false
      ->
        assert.rejects ->
          {entries} = await PublicAPI.fail
            title: "cat"
            category: "animals"

    test
      description: "grab value from stack",
      wait: false
      ->
        f = _.flow [
          $.request [
            $.mode "cors"
            $.url
          ]
          k.context
          k.get
          _.get "url"
        ]
        url = await f "http://example.com/"
        assert.equal "http://example.com/", url.href

    test
      description: "context available in error"
      wait: false
      ->
        assert.rejects (-> FubarAPI.fubar()),
          (error) -> error.response? && error.status == 404

  ]

  process.exit if success then 0 else 1
