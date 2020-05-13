import URLTemplate from "url-template"
import {curry, tee, rtee, flow} from "panda-garden"
import discover from "panda-sky-client"
import Profile from "@dashkite/zinc"
import Events from "./events"

use = curry (client, data) ->
  if client.run? then client.run {data} else {client, data}

events = curry (handler, context) ->
  context.events = new Events
  try
    result = handler context
    context.events.dispatch "success", result
    result
  catch error
    context.events.dispatch "failure", error
    undefined

resource = curry rtee (name, context) -> context.resource = name

base = curry rtee (url, context) -> context.base = new URL url

url = curry rtee (url, context) ->
  context.url = if context.base
    new URL url, context.base
  else
    new URL url

data = curry (builder, context) -> builder context.data

query = curry rtee (builder, context) ->
  for key, value of context.query
    context.url.searchParams.append key, value

template = curry rtee (template, context) ->
  context.template = URLTemplate.parse template

parameters = curry rtee (builder, context) ->
  _url = context.template.expand builder context
  url _url, context

content = curry rtee (builder, context) -> context.body = builder context

headers = curry rtee (headers, context) -> context.headers = headers

accept = curry rtee (type, context) -> (context.headers ?= {}).accept = type

method = curry rtee (name, context) -> context.method = name

request = tee (context) -> context.response = await context.client context

http = do ({http} = {}) ->
  http = (name) -> flow [ (method name), request ]
  get: http "get"
  put: http "put"
  delete: http "delete"
  patch: http "patch"
  post: http "post"
  options: http "options"
  head: http "head"

expect = curry rtee (codes, context) ->
  if ! context.response.status in codes
    throw "Mercury: unexpected response status: #{context.response.status}"

ok = (context) ->
  if !context.response.ok
    throw "Mercury: response status is not OK: #{context.response.status}"

text = tee (context) -> context.text = await context.response.text()

json = tee (context) -> context.json = await context.response.json()

blob = tee (context) -> context.blob = await context.response.blob()

Fetch =

  client: curry ({fetch, mode},
    {url, method, headers, body}) ->
    fetch url, {method, headers, body,  mode}

Sky = do ({client} = {}) ->

  client = (context) ->
    {api, resource, parameters, method, authorization, body, headers} = context
    api[resource](parameters)[method] {authorization, body, headers}

  client: do ({api} = {}) ->
    (url, options) ->
      run: tee (context) ->
        api ?= await discover url, options
        context.api = api
        context.client = client
        Object.defineProperty context, "url",
          get: -> new URL @api[@resource](@parameters).url

  parameters: curry rtee (builder, context) ->
    context.parameters = builder context

Zinc =

  grants: tee (context) ->
    profile = await Profile.current
    profile.receive context.keys.api.encryption,
      context.json.directory

  authorize: authorize = tee (context) ->
    {url, parameters, method} = context
    path = url.pathname
    profile = await Profile.current
    if (claim = profile.exercise {path, parameters, method})?
      context.authorization = capability: claim

  sigil: tee (context) ->
    {url, method, body} = context
    method = method.toUpperCase()
    {sign, hash, Message} = Profile.Confidential
    path = url.pathname
    date = new Date().toISOString()
    _hash = (hash Message.from "utf8", JSON.stringify body).to "base64"
    profile = await Profile.current
    declaration = sign profile.keyPairs.signature,
      Message.from "utf8", JSON.stringify {method, path, date, hash: _hash}
    context.authorization = sigil: declaration.to "base64"

  authorized: do ({authorized} = {}) ->
    authorized = (name) -> flow [ (method name), authorize, request ]
    get: authorized "get"
    put: authorized "put"
    delete: authorized "delete"
    patch: authorized "patch"
    post: authorized "post"
    options: authorized "options"
    head: authorized "head"

export {use, events, resource, base, url, data,
  query, template, parameters, content, headers, accept, method,
  request, http, expect, ok, text, json, blob,
  Zinc, Fetch, Sky}
