import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import * as _ from "@dashkite/joy"
import fetch from "node-fetch"
import * as $ from "../src"
import * as k from "@dashkite/katana"

globalThis.fetch ?= fetch
global.Request ?= fetch.Request

HTTPBin =

  get:
    _.flow [
      $.start
      $.url "https://httpbin.org/get"
      $.query
      $.method "get"
      $.headers accept: "application/json"
      $.expect.status [ 200 ]
      $.request
      $.json
      k.get
    ]

  fail:
    _.flow [
      $.start
      $.mode "cors"
      $.url "https://httpbin.org/status/404"
      $.method "get"
      $.headers accept: "application/json"
      $.expect.status [ 200 ]
      $.request
      $.json
      k.get
    ]

do ->

  print await test "Mercury: HTTP Combinators",  [

    test
      description: "fetch test"
      wait: false
      ->
        data = await HTTPBin.get
          greeting: "hello, world"
        assert.equal true, _.isObject data
        assert.equal data.args.greeting, "hello, world"


    test
      description: "failing fetch test"
      wait: false
      -> assert.rejects -> await HTTPBin.fail()

  ]

  process.exit if success then 0 else 1
