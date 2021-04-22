import URLTemplate from "url-template"
import * as _ from "@dashkite/joy"
import * as ks from "@dashkite/katana/sync"
import * as k from "@dashkite/katana/async"
import failure from "./failure"

# TODO if we get a stack, we know no argument was passed in
#      when defining the graph. if we get a value, we use
#      that to parameterize the fn
setter = (f) ->
  (value) -> if value? then _.pipe [ (ks.push -> value), f ] else f

request = (graph) ->
  _.pipe [
    # set up the stack
    (data) -> [ { data, mode: "cors" } ]
    # run the graph, pushing the arguments onto the stack for convenience
    ks.copy _.pipe [ (ks.read "data"), graph... ]
    # create the request...
    ks.copy _.pipe [
      ks.push ({url, method, headers, body, mode}) ->
        new Request context.url, {url, method, headers, body, mode}
      ks.write "request"
    # now we can actually process the request
    k.copy _.flow [
      # check the cache, if one was specified
      # otherwise, fetch the request
      k.push ({request, cache}) ->
        if cache? && (response = await cache.match request)?
          response
        else
          fetch request
        # save the response
        k.write "response"
        # verify the response if any verifiers were installed
        k.read "verify"
        k.peek (verify, response) -> verify? response
      ]
    ]
  ]

url = setter ks.copy _.pipe [
  ks.push (value) -> new URL value
  ks.write "url"
]

base = setter ks.write "base"

path = setter ks.copy _.pipe [
  ks.read "base"
  ks.push (base, value) -> new URL value, base
  ks.write "url"
]

query = setter _.pipe [
  ks.read "url"
  ks.peek (url, parameters) ->
    for key, value of parameters
      url.searchParams.append key, value
]

template = setter ks.copy _.pipe [
  ks.push (value) -> URLTemplate.parse value
  ks.write "template"
]

parameters = setter ks.copy _.pipe [
  ks.write "parameters"
  ks.read "template"
  ks.push (template, parameters) -> template.expand parameters
  ks.write "path"
]

method = setter ks.copy _.pipe [
  ks.push _.toUpperCase
  ks.write "method"
]

mode = setter ks.write "mode"

# TODO support streams and other content types
#      this may also affect other combinators like Zinc.sigil
content = setter ks.copy _.pipe [
  ks.push (value) -> if _.isString value then value else JSON.stringify value
  ks.write "body"
]

headers = setter ks.copy _.pipe [
  ks.read "headers"
  ks.push (headers, value) -> _.assign (headers ?= {}), value
  ks.write "headers"
]

header = (name) ->
  setter _.pipe [
    ks.poke (value) -> [name]: value
    headers
  ]

accept = header "accept"

media = header "content-type"

authorize = header "authorization"

urlencode = (object) ->
  _.pairs object
  .map ([key, value]) ->
    "#{encodeURIComponent key}=#{encodeURIComponent value}"
  .join "&"

urlencoded = setter _.pipe [
  ks.poke urlencode
  ks.write "body"
  media "application/x-www-form-urlencoded"
]

cache = setter _.pipe [
  ks.push (name) -> CacheStorage.open name
  ks.write "cache"
]

verify = (f) ->
  ks.copy _.pipe [
    ks.read "verify"
    ks.push (verify) -> if verify? then _.pipe [ verify, f ] else f
    ks.write "verify"
  ]

expect =

  status: (codes) ->
    verify (response) ->
      if ! (response.status in codes)
        throw failure "unexpected status", response

  media:  (value) ->
    verify (response) ->
      if ! ((context.response.headers.get "content-type") == value)
        throw failure "unsupported media type", response

  ok: verify (response) ->
    if ! response.ok then throw failure "not ok", response

response = (graph) ->
  _.flow [
    # process the response
    k.copy _.flow graph
    # return the context
    _.first
  ]

text = k.copy _.flow [
  k.read "response"
  k.push (response) -> response.text()
  k.write "text"
]

json = k.copy _.flow [
  k.read "response"
  k.push (response) -> response.json()
  k.write "json"
]

blob = k.copy _.flow [
  k.read "response"
  k.push (response) -> response.blob()
  k.write "blob"
]

export {
  request
  url
  base
  path
  query
  template
  parameters
  content
  urlencoded
  headers
  accept
  media
  method
  mode
  authorize
  cache
  expect
  response
  text
  json
  blob
}
