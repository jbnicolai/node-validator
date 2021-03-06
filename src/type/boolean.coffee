# Boolean value validation
# =================================================
# No options allowed.

# Node modules
# -------------------------------------------------
debug = require('debug')('validator:boolean')
util = require 'util'
chalk = require 'chalk'
# include classes and helper
rules = require '../rules'

valuesTrue = ['true', '1', 'on', 'yes', 1, true]
valuesFalse = ['false', '0', 'off', 'no', 0, false]

module.exports =

  # Description
  # -------------------------------------------------
  describe:

    # ### Type Description
    type: (options) ->
      options = optimize options
      # get possible values
      vTrue = valuesTrue.map(util.inspect).join ', '
      vFalse = valuesFalse.map(util.inspect).join ', '
      # combine into message
      "A boolean value, which will be true for #{vTrue} and
      will be considered as false for #{vFalse}. #{rules.describe.optional options}"

  # Synchronous check
  # -------------------------------------------------
  sync:

    # ### Check Type
    type: (check, path, options, value) ->
      debug "check #{util.inspect value} in #{check.pathname path}"
      , chalk.grey util.inspect options
      options = optimize options
      # sanitize
      value = rules.sync.optional check, path, options, value
      if typeof value is 'string'
        value = value.toLowerCase()
      # boolean values check
      return true if value in valuesTrue
      return false if value in valuesFalse
      # failed
      throw check.error path, options, value,
      new Error "No boolean value given"


  # Selfcheck
  # -------------------------------------------------
  selfcheck: (name, options) ->
    validator = require '../index'
    validator.check name,
      type: 'object'
      allowedKeys: true
      entries:
        type:
          type: 'string'
        title:
          type: 'string'
          optional: true
        description:
          type: 'string'
          optional: true
        optional:
          type: 'boolean'
          optional: true
        default:
          type: 'boolean'
          optional: true
    , options


# Optimize options setting
# -------------------------------------------------
optimize = (options) ->
  if options.optional and not options.default?
    options.default = false
  options
