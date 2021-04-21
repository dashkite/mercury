import URLTemplate from "url-template"
import * as _ from "@dashkite/joy"
import * as k from "@dashkite/katana"
import failure from "./failure"

read = (name, f) ->
  _.flow [
    k.read name
    f
    k.discard
  ]

write = (name, f) ->
  _.flow [
    f
    k.write name
    k.discard
  ]

set = (name, f) -> write name, k.push f

push = (f) ->
  (value) ->
    if value?
      _.flow [
        k.push -> value
        f
        k.discard
      ]
    else
      f

start = (data) ->
  if data?
    [ data, { data } ]
  else
    [ { data } ]

url = push set "url", (value) -> new URL value

base = push set "base", _.identity

path = push _.pipe [
  set "path", _.identity
  read "base", set "url", (value, base) -> new URL value, base
]

query = push read "url",
  k.speek (url, parameters) ->
    for key, value of parameters
      url.searchParams.append key, value

template = push set "template", (value) -> URLTemplate.parse value

parameters = push _.pipe [
  set "parameters", _.identity
  read "template", set "path", (template, value) -> template.expand value
]

method = push set "method", _.toUpperCase

mode = push set "mode", _.identity

# TODO support streams and other content types
#      this may also affect other combinators like Zinc.sigil
content = push set "body", (value) ->
  if _.isString value then value else JSON.stringify value

headers = push read "headers",
  set "headers", (headers, value) ->
    _.assign (headers ?= {}), value

_header = (name) ->
  push _.pipe [
    k.spoke (value) -> [name]: value
    headers
  ]

accept = _header "accept"

media = _header "content-type"

authorize = _header "authorization"

encode = (object) ->
  _.pairs object
  .map ([key, value]) ->
    "#{encodeURIComponent key}=#{encodeURIComponent value}"
  .join "&"

urlencoded = push _.pipe [
  set "body", encode
  media "application/x-www-form-urlencoded"
]

cache = push set "cache", (name) -> CacheStorage.open name

verify = (f) ->
  read "verify", set "verify", (verify) ->
    if verify? then _.pipe [ verify, f ] else f

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

request = ([stack..., context]) ->
  {url, method, headers, body, mode} = context
  request = new Request context.url, {url, method, headers, body, mode}
  context.response = await do ->
    if context.cache? && (response = await context.cache.match request)?
      response
    else
      fetch request
  context.verify? context.response
  [ stack..., context ]


text = read "response", set "text", (response) -> response.text()
json = read "response", set "json", (response) -> response.json()
blob = read "response", set "blob", (response) -> response.blob()

get = (name) -> ([stack..., context]) -> context[name]

export {
  start
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
  request
  expect,
  text
  json
  blob
  get
}
