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

data = curry (builder, context) -> await builder context.data

query = curry rtee (builder, context) ->
  for key, value of await builder context
    context.url.searchParams.append key, value

template = curry rtee (template, context) ->
  context.template = URLTemplate.parse template

parameters = curry rtee (builder, context) ->
  _url = context.template.expand await builder context
  url _url, context

content = curry rtee (builder, context) -> context.body = await builder context

headers = curry rtee (headers, context) -> context.headers = headers

accept = curry rtee (type, context) -> (context.headers ?= {}).accept = type

method = curry rtee (name, context) -> context.method = name

authorize = curry rtee (builder, context) ->
  context.authorization = await builder context

request = tee (context) -> context.response = await context.client context

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

  client: do ({type, credentials} = {}) ->
    curry ({fetch, mode}, {url, method, headers, authorization, body}) ->
      if authorization?
        type = (Object.keys authorization)[0]
        credentials = authorization[_type]
        headers.authorization = "#{type} #{credentials}"
      fetch url, {method, headers, body,  mode}

Sky = do ({client} = {}) ->

  client = ({api, resource, parameters,
    method, authorization, body, headers}) ->
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
    context.parameters = await builder context

Zinc =

  grants: tee (context) ->
    profile = await Profile.current
    profile.receive context.keys.api.encryption,
      context.json.directory

  claim: (context) ->
    {url, parameters, method} = context
    path = url.pathname
    profile = await Profile.current
    if (claim = profile.exercise {path, parameters, method})?
      capability: claim

  sigil: (context) ->
    {url, method, body} = context
    method = method.toUpperCase()
    {sign, hash, Message} = Profile.Confidential
    path = url.pathname
    date = new Date().toISOString()
    _hash = (hash Message.from "utf8", JSON.stringify body).to "base64"
    profile = await Profile.current
    declaration = sign profile.keyPairs.signature,
      Message.from "utf8", JSON.stringify {method, path, date, hash: _hash}
    sigil: declaration.to "base64"


export {use, events, resource, base, url, data,
  query, template, parameters, content, headers, accept, method, authorize,
  request, expect, ok, text, json, blob,
  Zinc, Fetch, Sky}
