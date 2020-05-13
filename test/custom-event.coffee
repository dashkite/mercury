class CustomEvent
  constructor: (@type, options) -> Object.assign @, options

global.CustomEvent = CustomEvent
