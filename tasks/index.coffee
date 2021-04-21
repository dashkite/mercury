import "coffeescript/register"
import p from "path"
import * as t from "@dashkite/genie"
import * as m from "@dashkite/masonry"
import {coffee} from "@dashkite/masonry/coffee"
import * as q from "panda-quill"
import {tee, flow} from "@dashkite/joy"

t.define "clean", -> m.rm "build"

t.define "build", "clean", m.start [
  m.glob [ "{src,test}/**/*.coffee" ], "."
  m.read
  flow [
    m.tr coffee target: "node"
    m.extension ".js"
    m.write p.join "build", "node"
  ]
  flow [
    m.tr coffee target: "import"
    m.extension ".js"
    m.write p.join "build", "import"
  ]
]

t.define "node:test", [ "build" ], ->
  m.exec "node", [
    "--enable-source-maps"
    "./build/node/test/index.js"
  ]

t.define "test", [ "clean" ], ->
  require "../test"
