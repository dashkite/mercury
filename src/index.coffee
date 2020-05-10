import {curry} from "panda-garden"
import discover from "panda-sky-client"
import Events from "./events"

api = curry (initializer, source) ->
  context = {source}
  context.api = await initializer()
  context

events = curry (handler, context) ->
  context.events = new Events
  try
    result = handler context
    context.events.dispath "success", result
    result
  catch error
    context.events.dispatch "failure", error

source = curry (key, source) -> source[key]

resource = curry (name, context) ->
  context.resource = name
  context

parameters = curry (builder, context) ->
  context.parameters = builder context.source, context
  context

content = curry (builder, context) ->
  context.body = builder context.source, context
  context

authorize = curry (builder, context) ->
  context.authorization = builder context.source, context
  context

http = do ({api, resource, parameters, body, authorization} = {}) ->
  get: (context) ->
    {api, resource, parameters, authorization} = context
    context.response = await api[resource](parameters)
      .get {authorization}
    context

  put: (context) ->
    {api, resource, parameters, body, authorization} = context
    context.response = await api[resource](parameters)
      .put {body, authorization}
    context

  post: (context) ->
    {api, resource, parameters, body, authorization} = context
    context.response = await api[resource](parameters)
      .post {body, authorization}
    context

  delete: (context) ->
    {api, resource, parameters, authorization} = context
    context.response = await api[resource](parameters)
      .delete {authorization}
    context

  patch: (context) ->
    {api, resource, parameters, body, authorization} = context
    context.response = await api[resource](parameters)
      .patch {body, authorization}
    context

json = (context) ->
  context.json = await context.response.json()
  context

response = (context) -> context.response

result = curry (key, context) -> context[key]

export {api, events, source,
  resource, parameters, content, authorize,
  http, json, response, result}
