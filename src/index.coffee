import {curry, tee, rtee, flow} from "panda-garden"
import discover from "panda-sky-client"
import Events from "./events"

use = curry (client, source) -> {client, source}

events = curry (handler, context) ->
  context.events = new Events
  try
    result = handler context
    context.events.dispatch "success", result
    result
  catch error
    context.events.dispatch "failure", error
    undefined

source = curry (key, source) -> source[key]

headers = curry rtee (headers, context) -> context.headers = headers

resource = curry rtee (url, context) -> context.resource = url

parameters = curry rtee (builder, context) ->
  context.parameters = builder context.source, context

content = curry rtee (builder, context) ->
  context.body = builder context.source, context

authorize = curry rtee (builder, context) ->
  context.authorization = builder context.source, context

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

text = tee (context) -> context.text = await context.response.text()

json = tee (context) -> context.json = await context.response.json()

fetch =
  mode: curry rtee (mode, context) -> context.mode = mode
  client: curry ({fetch}, {resource, parameters, method, body, headers, mode}) ->
    url = new URL resource
    url.searchParams.append key, value for key, value of parameters
    fetch url, {method, headers, body,  mode}

sky =
  client: ({api, resource, parameters, method, body, authorization}) ->
    switch method
      when "get", "options", "delete"
        api[resource](parameters)[method] {authorization}
      when "put", "patch", "post"
        api[resource](parameters)[method] {authorization, body}
  discover: do ({api} = {}) ->
    curry rtee (url, options, context) ->
      api ?= await discover url, options
      context.api = api


export {use, events, source,
  resource, parameters, content, headers,
  authorize, http, text, json, fetch, sky}
