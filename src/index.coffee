import URLTemplate from "url-template"
import * as _ from "@dashkite/joy"
import * as k from "@dashkite/katana"
import { Daisho } from "@dashkite/katana"
import * as ks from "@dashkite/katana/sync"
import failure from "./failure"

setter = (f) ->
  (value) ->
    if k.isDaisho value
      f value
    else
      ks.assign _.pipe [ (ks.push -> value), f ]


# create the request...
createRequest = ks.assign _.pipe [
  ks.context
  ks.push ({url, method, headers, body, mode}) ->
    new Request url, {method, headers, body, mode}
  ks.write "request"
]

# actually process the request
# check the cache, if one was specified
# otherwise, fetch the request
processRequest = k.assign _.flow [
  ks.context
  k.push ({request, cache}) ->
    if cache? && (response = await cache.match request)?
      response
    else
      fetch request
  # save the response
  k.write "response"
]

# verify the response if any verifiers were installed
verifyResponse = _.flow [
  k.context
  k.peek ({verify, response}) -> verify? response
]

cacheResponse = _.flow [
  k.context
  k.peek ({cache, expires, request, response}) ->
    if cache?
      cache.put request, response.clone()
      if expires?
        setTimeout (-> cache.delete request), expires
]

request = (graph) ->
  _.pipe [
    # set up the stack
    (data) -> Daisho.create [], { data, mode: "cors" }
    # run the graph, pushing the arguments onto the stack for convenience
    ks.assign _.pipe [ (ks.read "data"), graph... ]
    createRequest
    _.flow [
      processRequest
      verifyResponse
      cacheResponse
    ]
  ]

url = setter ks.assign _.pipe [
  ks.push (value) -> new URL value
  ks.write "url"
]

base = setter ks.write "base"

path = setter ks.assign _.pipe [
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

template = setter ks.assign _.pipe [
  ks.push (value) -> URLTemplate.parse value
  ks.write "template"
]

parameters = setter ks.assign _.pipe [
  ks.write "parameters"
  ks.read "template"
  ks.push (template, parameters) -> template.expand parameters
  ks.write "path"
]

method = setter ks.assign _.pipe [
  ks.push _.toUpperCase
  ks.write "method"
]

mode = setter ks.write "mode"

# TODO support streams and other content types
#      this may also affect other combinators like Zinc.sigil
content = setter ks.assign _.pipe [
  ks.push (value) ->
    if _.isString value
      value
    else if (_.isObject value) || (_.isArray value)
      JSON.stringify value
    else
      value.toString?()
  ks.write "body"
]

headers = setter ks.assign _.pipe [
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

urlencoded = setter _.pipe [
  ks.poke (dictionary) -> (new URLSearchParams _.pairs dictionary).toString()
  ks.write "body"
  media "application/x-www-form-urlencoded"
]

cache = setter ks.assign _.pipe [
  ks.push (name) -> caches.open name
  ks.write "cache"
]

expires = setter ks.write "expires"

verify = (f) ->
  ks.assign _.pipe [
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
    k.assign _.flow graph
    # return the context
    k.context
    k.get
  ]

text = k.assign _.flow [
  k.read "response"
  k.push (response) -> response.text()
  k.write "text"
]

json = k.assign _.flow [
  k.read "response"
  k.push (response) -> response.json()
  k.write "json"
]

blob = k.assign _.flow [
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
