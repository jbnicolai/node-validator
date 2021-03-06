# RegExp validation
# =================================================

# Check options:
#
# - `optional` - the value must not be present (will return null)


# Node modules
# -------------------------------------------------
debug = require('debug')('validator:regexp')
util = require 'util'
chalk = require 'chalk'
# include classes and helper
ValidatorCheck = require '../check'
rules = require '../rules'

suboptions =
  type: 'string'
  match: /^\/.*?\/[gim]*$/

module.exports = hostname =

  # Description
  # -------------------------------------------------
  describe:

    # ### Type Description
    type: (options) ->
      text = 'A valid hostname. '
      text += rules.describe.optional options
      text += ValidatorCheck.describe suboptions
      text

  # Synchronous check
  # -------------------------------------------------
  sync:

    # ### Check Type
    type: (check, path, options, value) ->
      debug "check #{util.inspect value} in #{check.pathname path}"
      , chalk.grey util.inspect options
      # first check input type
      value = rules.sync.optional check, path, options, value
      return value unless value?
      # validate
      value = check.subcall path, suboptions, value
      # transform into regexp
      parts = value.match /^\/(.*?)\/([gim]*)$/
      new RegExp parts[1], parts[2]


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
          type: 'string'
          optional: true
    , options

