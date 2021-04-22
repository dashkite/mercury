import assert from "assert"
import {print, test, success} from "amen"

import * as _ from "@dashkite/joy"
import fetch from "node-fetch"
import * as $ from "../src"
import * as k from "@dashkite/katana"

globalThis.fetch ?= fetch
global.Request ?= fetch.Request

trace = (name, f) ->
  (args...) ->
    console.log name, "called with", args
    r = _.apply f, args
    console.log name, "returned", r
    r


PublicAPI =
  search:
    _.flow [
      $.request [
        $.url "https://api.publicapis.org/entries"
        $.query()
        $.method "get"
        $.headers accept: "application/json"
        $.expect.status [ 200 ]
      ]
      $.response [
        $.json
      ]
      _.get "json"
    ]

#   fail:
#     _.flow [
#       $.start
#       $.mode "cors"
#       $.url "https://api.publicapis.org/entries"
#       $.query()
#       $.method "get"
#       $.headers accept: "application/json"
#       $.expect.status [ 300 ]
#       $.request
#       $.json
#       $.get "json"
#     ]
#
# FubarAPI =
#   fubar:
#     _.flow [
#       $.start
#       $.mode "cors"
#       $.url "https://api.publicapis.org/fubar"
#       $.method "get"
#       $.expect.ok
#       $.request
#     ]

do ->

  print await test "Mercury: HTTP Combinators",  [

    test
      description: "fetch test"
      wait: false
      ->

        {entries} = await PublicAPI.search
          title: "cat"
          category: "animals"
        console.log entries
        assert entries


    # test
    #   description: "failing fetch test"
    #   wait: false
    #   ->
    #     assert.rejects ->
    #       {entries} = await PublicAPI.fail
    #         title: "cat"
    #         category: "animals"
    #
    # test
    #   description: "from with data",
    #   wait: false
    #   ->
    #     f = _.flow [
    #       $.start
    #       $.mode "cors"
    #       $.url()
    #       $.get "url"
    #     ]
    #     url = await f "http://example.com/"
    #     assert.equal "http://example.com/", url.href
    #
    # test
    #   description: "context available in error"
    #   wait: false
    #   ->
    #     assert.rejects (-> FubarAPI.fubar()),
    #       (error) -> error.response? && error.status == 404

  ]

  process.exit if success then 0 else 1
