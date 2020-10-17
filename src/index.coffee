import URLTemplate from "url-template"
import {curry, tee, rtee, flow} from "@pandastrike/garden"
import {stack, push, pop, poke} from "@dashkite/katana"
import failure from "./failure"

toUpperCase = (s) -> s.toUpperCase()
isString = (s) -> s.constructor == String

use = curry (client, data) ->
  if client.run? then client.run {data} else {client, data}

url = curry rtee (value, context) -> context.url = new URL value

base = curry rtee (value, context) -> context.base = value

path = curry rtee (value, context) ->
  context.path = value
  context.url = new URL value, context.base

query = curry rtee (object, context) ->
  for key, value of object
    context.url.searchParams.append key, value

template = curry rtee (value, context) ->
  context.template = URLTemplate.parse value

parameters = curry rtee (object, context) ->
  context.parameters = object
  path (context.template.expand object), context

content = curry rtee (value, context) ->
  # TODO support streams and other content types
  #      this may also affect other combinators like Zinc.sigil
  context.body = if isString value then value else JSON.stringify value

headers = curry rtee (object, context) -> context.headers = object

accept = curry rtee (value, context) ->
  if value?
    (context.headers ?= {}).accept = value

media = curry rtee (value, context) ->
  if value?
    (context.headers ?= {})["content-type"] = value

method = curry rtee (value, context) -> context.method = value

authorize = curry rtee (value, context) ->
  (context.headers ?= {}).authorization = value

data = curry (names, context) ->
  names.reduce ((r, name) -> {r..., [name]: context.data[name]}), {}

from = ([source, filters..., target]) ->
  tee stack flow [
    push source
    (poke filter for filter in filters)...
    pop target
  ]

cache = do (cache = {}, {method, url, cached} = {}) ->
  curry (requestor, context) ->
    {url, method} = context
    if (cached = cache[url]?[method])?
      await cached
    else
      (cache[url] ?= {})[method] = requestor context

request = tee (context) -> context.response = await context.client context

expect =

  status: curry rtee (codes, context) ->
    if codes?
      if ! (context.response.status in codes)
        throw failure "unexpected status", context

  media:  curry rtee (value, context) ->
    if value?
      if ! ((context.response.headers.get "content-type") == value)
        throw failure "unsupported media type", context

  ok: tee (context) ->
    if ! context.response.ok
      throw failure "not ok", context

text = tee (context) -> context.text = await context.response.text()

json = tee (context) -> context.json = await context.response.json()

blob = tee (context) -> context.blob = await context.response.blob()

Fetch =

  client: do ({type, credentials} = {}) ->
    curry ({mode}, {url, method, headers, body}) ->
      fetch url, {method: (toUpperCase method), headers, body,  mode}

export {use, url, base, path,
  query, template, parameters, content, headers,
  accept, media, method, data, from, authorize, cache, request, expect,
  text, json, blob, Fetch}
