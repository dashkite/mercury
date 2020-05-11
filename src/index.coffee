import URLTemplate from "url-template"
import {curry, tee, rtee, flow} from "panda-garden"
import discover from "panda-sky-client"
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

data = curry rtee (builder, context) -> builder context.data

query = curry rtee (builder, context) ->
  for key, value of builder context
    context.url.searchParams.append key, value

template = curry rtee (template, context) ->
  context.template = URLTemplate.parse template

parameters = curry rtee (builder, context) ->
  context.url = context.template.expand builder context

content = curry rtee (builder, context) -> context.body = builder context

headers = curry rtee (headers, context) -> context.headers = headers

method = curry rtee (name, context) -> context.method = name

request = tee (context) -> context.response = await context.client context

http =
  get: flow [ (method "get"), request ]
  put: flow [ (method "put") request ]
  delete: flow [ (method "delete"), request ]
  patch: flow [ (method "patch"), request ]
  post: flow [ (method "post"), request ]
  options: flow [ (method "options"), request ]
  head: flow [ (method "head"), request ]

expect = curry rtee (codes, context) ->
  if ! context.response.status in codes
    throw "Mercury: unexpected response status: #{context.response.status}"

ok = (context) ->
  if !context.response.ok
    throw "Mercury: response status is not OK: #{context.response.status}"

text = tee (context) -> context.text = await context.response.text()

json = tee (context) -> context.json = await context.response.json()

Fetch =

  client: curry ({fetch, mode},
    {url, method, headers, body}) ->
    fetch url, {method, headers, body,  mode}

Sky = do ({client} = {}) ->

  client = ({api, resource, parameters, method, body, authorization}) ->
    api[resource](parameters)[method] {authorization, body}

  client: do ({api} = {}) ->
    (url, options) ->
      run: tee (context) ->
        api ?= await discover url, options
        context.api = api
        context.client = client
        Object.defineProperty context, "url",
          get: -> @api[@resource](@parameters).url

export {use, events, resource, base, url, data,
  query, template, parameters, content, headers, method,
  request, http, expect, ok, text, json, Fetch, Sky}
