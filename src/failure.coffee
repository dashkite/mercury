import * as Mercury from "./error"

failure = do ({codes, message} = {}) ->

  codes =

    "unexpected status": (response) ->
      "unexpected status: #{response.status}"

    "not ok": (response) ->
      "status is not ok: #{response.status}"

    "unsupported media type": (response)->
      "unsupported media type: #{response.headers['content-type']}"

  (code, response) ->
    new Mercury.Error (codes[code] response), response


export default failure
