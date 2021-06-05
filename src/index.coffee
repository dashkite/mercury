import URLTemplate from "es6-url-template"
import * as _ from "@dashkite/joy"
import * as k from "@dashkite/katana"
import * as ks from "@dashkite/katana/sync"
import failure from "./failure"

# TODO implement this with parse
acceptable = (expected, actual) ->
  (_.toLowerCase actual).includes (_.toLowerCase expected)

setter = (f) ->
  (value) ->
    if k.isDaisho value
      ((ks.test _.isDefined, f) value)
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
  k.peek ({verify, response}) ->
    if verify
      verifier = _.all verify
      verifier response
]

cacheResponse = _.flow [
  k.context
  k.peek ({cache, expires, request, response}) ->
    if cache?
      cache.put request, response.clone()
      if expires?
        setTimeout (-> cache.delete request), expires
  k.discard
]

request = (graph) ->
  _.flow [
    # set up the stack
    (data) -> k.Daisho.create [ data ], { data, mode: "cors" }
    # run the graph
    k.assign graph
    createRequest
    processRequest
    verifyResponse
    cacheResponse
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
  path

]

method = setter ks.assign _.pipe [
  ks.push  _.toUpperCase
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

verify = ks.assign _.pipe [
  ks.read "verify"
  ks.push (verify, f) ->
    _.push (verify ? []), f
  ks.write "verify"
]

expect =

  status: setter _.pipe [
    ks.poke (codes) ->
      (response) ->
        if ! (response.status in codes)
          throw failure "unexpected status", response
    verify
  ]

  media: ks.assign _.pipe [
    ks.read "headers"
    ks.poke _.get "accept"
    ks.push (accept) ->
      (response) ->
        if !(acceptable accept, response.headers.get "content-type")?
          throw failure "unsupported media type", response
    verify
  ]

  ok: ks.assign _.pipe [
    ks.push ->
      (response) -> if ! response.ok then throw failure "not ok", response
    verify
  ]

text = _.flow [
  k.read "response"
  k.poke (response) -> response.text()
  k.write "text"
]

json = _.flow [
  k.read "response"
  k.poke (response) -> response.json()
  k.write "json"
]

blob = _.flow [
  k.read "response"
  k.poke (response) -> response.blob()
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
  text
  json
  blob
}
