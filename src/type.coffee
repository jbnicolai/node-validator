# Validator for simple types
# =================================================

debug = require('debug')('validator:type')
validator = require './index'

# Send value and return it
# -------------------------------------------------
# This helps supporting both return values and callbacks at the same time.
done = (err, value, cb = ->) ->
  cb err, value
  err ? value

# Boolean value
# -------------------------------------------------
# No options allowed.
exports.boolean =
  check: (name, value, options, cb) ->
    if typeof value is 'string'
      debug "Boolean check '#{value}' for #{name}"
    else
      debug "Boolean check #{value} for #{name}"
    unless value?
      return done null, false, cb
    switch typeof value
      when 'boolean'
        return done null, value, cb
      when 'string'
        switch value.toLowerCase()
          when 'true', '1', 'on', 'yes'
            return done null, true, cb
          when 'false', '0', 'off', 'no'
            return done null, false, cb
      when 'number'
        switch value
          when 1
            return done null, true, cb
          when 0
            return done null, false, cb
      else
        return done new Error("No boolean value given for #{name}."), null, cb
    done new Error("The value '#{value}' is no boolean for #{name}."), null, cb
  describe: (options = {}) ->
    "The value has to be a boolean. The value will be true for 1, 'true', 'on',
    'yes' and it will be considered as false for 0, 'false', 'off', 'no', '.
    Other values are not allowed."

# String value
# -------------------------------------------------
# Sanitize options allowed:
#
# - `tostring` - convert objects to string, first
# - `allowControls` - keep control characters in string instead of
#   stripping them (but keep \\r\\n)
# - `stripTags` - remove all html tags
# - `lowerCase` - set to `true` or `first`
# - `upperCase` - set to `true` or `first`
# - `replace` - replacements (list): string (only single replacement) or
#   regular expressions and replacements as inner array
# - `trim` - strip whitespace from the beginning and end
# - `crop` - crop text after number of characters
#
# Check options:
#
# - `optional` - the value must not be present (will return null)
# - `minLength` - minimum text length in characters
# - `maxLength` - maximum text length in characters
# - `values` - array of possible values (complete text)
# - `startsWith` - start of text
# - `endsWith` - end of text
# - `match` - string or regular expression which have to be matched
#   (or list of expressions)
# - `matchNot` - string or regular expression which is not allowed to
#   match (or list of expressions)
exports.string =
  check: (name, value, options = {}, cb) ->
    debug "String check '#{value}' for #{name}", options
    unless value?
      return done null, null, cb if options.optional
      return done new Error("A value is needed for #{name}."), null, cb
    if options.tostring and typeof value is 'object'
      value = value.toString()
    # first check input type
    unless typeof value is 'string'
      return done new Error("A string is needed for #{name} but got
        #{typeof value} instead."), null, cb
    # sanitize
    unless options.allowControls
      value = value.replace /[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]/g, ''
    if options.stripTags?
      value = value.replace /<\/?[^>]+(>|$)/g, ''
    if options.lowerCase? and options.lowerCase is true
      value = value.toLowerCase()
    if options.upperCase? and options.upperCase is true
      value = value.toUpperCase()
    if options.lowerCase? and options.lowerCase is 'first'
      value = value.charAt(0).toLowerCase() + value[1..]
    if options.upperCase? and options.upperCase is 'first'
      value = value.charAt(0).toUpperCase() + value[1..]
    if options.replace?
      if Array.isArray options.replace[0]
        for [pattern, replace] in options.replace
          value = value.replace pattern, replace
      else
        [pattern, replace] = options.replace
        value = value.replace pattern, replace
    if options.trim
      value = value.trim()
    if options.crop?
      value = value.substring 0, options.crop
    # validate
    if options.minLength? and value.length < options.minLength
      return done new Error("The given string '#{value}' is too short for
        #{name}, at most #{options.minlength} characters are needed."), null, cb
    if options.maxLength? and value.length > options.maxLength
      return done new Error("The given string '#{value}' is too long for
        #{name}, at least #{options.maxlength} characters are allowed."), null, cb
    if options.values? and not (value in options.values)
      return done new Error("The given string '#{value}' is not in the list of
        allowed phrases (#{options.values}) for #{name}."), null, cb
    if options.startsWith? and value[..options.startsWith.length-1] isnt options.startsWith
      return done new Error("The given string '#{value}' should start with
        '#{options.startsWith}' for #{name}."), null, cb
    if options.endsWith? and value[value.length-options.endsWith.length..] isnt options.endsWith
      return done new Error("The given string '#{value}' should end with
        '#{options.endsWith}' for #{name}."), null, cb
    if options.match?
      if Array.isArray options.match
        success = true
        for match in options.match
          if match instanceof RegExp
            success = success and value.match match
          else
            success = success and ~value.indexOf match
        unless success
          return done new Error("The given string '#{value}' should match against
            '#{options.match}' for #{name}."), null, cb
      else if options.match instanceof RegExp and not value.match options.match
        return done new Error("The given string '#{value}' should match against
          '#{options.match}' for #{name}."), null, cb
      else if not ~value.indexOf options.match
        return done new Error("The given string '#{value}' should contain
          '#{options.match}' for #{name}."), null, cb
    if options.matchNot?
      if Array.isArray options.matchNot
        success = true
        for match in options.matchNot
          if match instanceof RegExp
            success = success and not value.match match
          else
            success = success and not ~value.indexOf match
        unless success
          return done new Error("The given string '#{value}' shouldn't match against
            '#{options.match}' for #{name}."), null, cb
      else if options.matchNot instanceof RegExp and value.matchNot options.match
        return done new Error("The given string '#{value}' shouldn't match against
          '#{options.matchNot}' for #{name}."), null, cb
      else if ~value.indexOf options.matchNot
        return done new Error("The given string '#{value}' shouldn't contain
          '#{options.matchNot}' for #{name}."), null, cb
    # done return resulting value
    return done null, value, cb
  describe: (options = {}) ->
    text = 'This should be text entry. '
    if options.tostring
      text += "Objects will be converted to their string representation. "
    remove = []
    remove.push "Control characters" unless options.allowControls
    remove.push "HTML Tags" if options.stripTags
    text += "#{remove.join ', '} will be removed. " if remove
    if options.replace?
      text += "The following replacements will take place: "
      if Array.isArray options.replace[0]
        for [pattern, replace] in options.replace
          text += "#{pattern} => #{replace}, "
        text = text.replace /, $/, '. '
      else
        [pattern, replace] = options.replace
        text += "#{pattern} => #{replace}. "
    if options.trim
      text += "Whitespace will be removed at start and end of the text. "
    if options.crop?
      text += "The text will be cropped after #{options.crop} characters. "
    if options.lowerCase? and options.lowerCase is true
      text += "The text will get lower case. "
    if options.upperCase? and options.upperCase is true
      text += "The text will get upper case. "
    if options.lowerCase? and options.lowerCase is 'first'
      text += "The first letter will get lower case. "
    if options.upperCase? and options.upperCase is 'first'
      text += "The first letter will get upper case. "
    if options.minLength? and options.maxLength?
      text += "It has to be between #{options.minLength} and #{options.maxLength} characters long. "
    else if options.minLength?
      text += "It has to be at least #{options.minLength} characters long. "
    else if options.maxLength?
      text += "It has to be not more than #{options.maxLength} characters long. "
    if options.values?
      text += "Only the values: #{values.join ', '} are allowed. "
    if options.startsWith?
      text += "It has to start with #{options.startsWith}... "
    if options.endsWith?
      text += "It has to end with ...#{options.endsWith}. "
    if options.match?
      text += "The text should match: "
      if Array.isArray options.match
        for entry in options.match
          text += "'#{entry}', "
        text = text.replace /, $/, '. '
      else
        text += "'#{options.match}'. "
    if options.matchNot?
      text += "The text shouldn't match: "
      if Array.isArray options.matchNot
        for entry in options.matchNot
          text += "'#{entry}', "
        text = text.replace /, $/, '. '
      else
        text += "'#{options.matchNot}'. "
    if options.optional
      text += "The setting is optional. "
    text.trim()

# Integer value
# -------------------------------------------------
#
# Sanitize options allowed:
#
# - `sanitize` - (bool) remove invalid characters
# - `round` - (bool) rounding of float can be set to true for arithmetic rounding
#   or use `floor` or `ceil` for the corresponding methods
#
# Check options:
#
# - `optional` - the value must not be present (will return null)
# - `min` - (integer) the smalles allowed number
# - `max` - (integer) the biggest allowed number
# - `type` - (integer|string) the integer is of given type
#   (4, 8, 16, 32, 64, 'byte', 'short','long','quad', 'safe')
# - `unsigned` - (bool) the integer has to be positive

integerTypes =
  byte: 8
  short: 16
  long : 32
  safe: 53
  quad: 64

exports.integer =
  check: (name, value, options = {}, cb) ->
    debug "Integer check '#{value}' for #{name}", options
    unless value?
      return done null, null, cb if options.optional
      return done new Error("A value is needed for #{name}."), null, cb
    # sanitize
    if typeof value is 'string'
      if options.sanitize
        if options.round?
          value = value.replace /^.*?(-?\d+\.?\d*).*?$/, '$1'
        else
          value = value.replace /^.*?(-?\d+).*?$/, '$1'
      if value.length
        value = Number value
    if options.round
      value = switch options.round
        when 'ceil' then Math.ceil value
        when 'floor' then Math.floor value
        else Math.round value
    # validate
    unless value is (value | 0)
      return done new Error("The given value '#{value}' is no integer as needed
        for #{name}."), null, cb
    if options.min? and value < options.min
      return done new Error("The value is to low, it has to be at least
        '#{options.min}' for #{name}."), null, cb
    if options.max? and value > options.max
      return done new Error("The value is to high, it has to be'#{options.max}'
        or lower for #{name}."), null, cb
    if options.type
      type = integerTypes[options.type] ? options.type
      unit = integerTypes[options.type] ? 'byte'
      unsigned = if options.unsigned then 1 else 0
      max = (Math.pow 2, type-1+unsigned)-1
      min = (unsigned-1) * max - 1 + unsigned
      if value < min or value > max
        return done new Error("The value is out of range for #{options.type}
          #{unit}-integer for #{name}."), null, cb
    # done return resulting value
    return done null, value, cb
  describe: (options = {}) ->
    text = 'An integer value is needed, here. '
    if options.sanitize
      text += "Invalid characters will be removed from text. "
    if options.round
      type = switch options.round
        when 'to ceil' then Math.ceil value
        when 'to floor' then Math.floor value
        else 'arithḿetic'
      text += "Value will be rounded #{type}. "
    if options.min? and options.max?
      text += "The value should be between #{options.min} and #{options.max}. "
    else if options.min?
      text += "The value should be greater than #{options.min}. "
    else if options.max?
      text += "The value should be lower than #{options.max}. "
    if options.type?
      type = integerTypes[options.type] ? options.type
      unit = integerTypes[options.type] ? 'byte'
      unsigned = if options.unsigned then 'unsigned' else 'signed'
      text += "Only values in the range of a #{unsigned} #{type}#{unit}-integer
        are allowed. "
    if options.optional
      text += "The setting is optional. "
    text.trim()

# Float value
# -------------------------------------------------
#
# Sanitize options allowed:
#
# - `sanitize` - (bool) remove invalid characters
# - `round` - (int) number of decimal digits to round to
#
# Check options:
#
# - `optional` - the value must not be present (will return null)
# - `min` - (numeric) the smalles allowed number
# - `max` - (numeric) the biggest allowed number
exports.float =
  check: (name, value, options = {}, cb) ->
    debug "Float check '#{value}' for #{name}", options
    unless value?
      return done null, null, cb if options.optional
      return done new Error("A value is needed for #{name}."), null, cb
    # sanitize
    if typeof value is 'string'
      if options.sanitize
        value = value.replace /^.*?(-?\d+\.?\d*).*?$/, '$1'
      if value.length
        value = Number value
    if options.round?
      exp = Math.pow 10, options.round
      value = Math.round(value * exp) / exp
    # validate
    unless not isNaN(parseFloat value) and isFinite value
      return done new Error("The given value '#{value}' is no number as needed
        for #{name}."), null, cb
    if options.min? and value < options.min
      return done new Error("The value is to low, it has to be at least
        '#{options.min}' for #{name}."), null, cb
    if options.max? and value > options.max
      return done new Error("The value is to high, it has to be'#{options.max}'
        or lower for #{name}."), null, cb
    # done return resulting value
    return done null, value, cb
  describe: (options = {}) ->
    text = 'A numeric value (float) is needed. '
    if options.sanitize
      text += "Invalid characters will be removed from text. "
    if options.round?
      text += "Value will be rounded arithmetic to #{options.round} digits. "
    if options.min? and options.max?
      text += "The value should be between #{options.min} and #{options.max}. "
    else if options.min?
      text += "The value should be greater than #{options.min}. "
    else if options.max?
      text += "The value should be lower than #{options.max}. "
    if options.optional
      text += "The setting is optional. "
    text.trim()


# Array
# -------------------------------------------------
#
# Sanitize options:
#
# - `delimiter` - allow value text with specified list separator
#   (it can also be an regular expression)
#
# Check options:
#
# - `notEmpty` - set to true if an empty array is not valid
# - `minLength` - minimum number of entries
# - `maxLength` - maximum number of entries
# - `optional` - the value must not be present (will return null)
exports.array =
  check: (name, value, options = {}, cb) ->
    debug "Array check for #{name}", options
    unless value?
      return done null, null, cb if options.optional
      return done new Error("A value is needed for #{name}."), null, cb
    if typeof value is 'string' and options.delimiter?
      value = value.split options.delimiter
    # validate
    unless Array.isArray value
      return done new Error("The value for #{name} has to be an array."), null, cb
    if options.notEmpty and value.length is 0
      return done new Error("An empty array/list is not allowed for #{name}."), null, cb
    if options.minLength? and options.minLength is options.maxLength and (
      value.length isnt options.minLength)
      return done new Error("Exactly #{options.minLength} entries are required
        for #{name}. "), null, cb
    else if options.minLength? and options.minLength > value.length
      return done new Error("At least #{options.minLength} entries are required
        in list for #{name}. "), null, cb
    else if options.maxLength? and options.maxLength < value.length
      return done new Error("Not more than #{options.maxLength} entries are allowed in list
        for #{name}. "), null, cb
    if options.entries?
      if cb?
        # run async
        return async.each [0..value.length-1], (i, cb) ->
          suboptions = if Array.isArray options.entries
            options.entries[i]
          else
            options.entries
          # run subcheck
          validator.check "name[#{i}]", subvalue, suboptions, (err, result) ->
            # check response
            return cb err if err
            value[i] = result
            cb()
        , (err) -> cb err, value
      #run sync
      for subvalue, i in value
        suboptions = if Array.isArray options.entries
          options.entries[i]
        else
          options.entries
        # run subcheck
        result = validator.check "name[#{i}]", subvalue, suboptions
        # check response
        if result instanceof Error
          return done result, value
        value[i] = result
    # done return resulting value
    return done null, value, cb

  describe: (options = {}) ->
    text = 'Here a list or array have to be given. '

    if options.optional
      text += "The setting is optional. "
    text.trim()


# Object
# -------------------------------------------------
#
# Check options:
#
# - `optional` - the value must not be present (will return null)
# - `instanceOf` - only objects of given class type are allowed
# - `mandatoryKeys` - the list of elements which are mandatory
# - `allowedKeys` - gives a list of elements which are also allowed
exports.object =
  check: (name, value, options = {}, cb) ->
    debug "Object check for #{name}", options
    unless value?
      return done null, null, cb if options.optional
      return done new Error("A value is needed for #{name}."), null, cb
    # add mandatory keys to allowed keys
    allowedKeys = []
    allowedKeys = allowedKeys.concat options.allowedKeys if options.allowedKeys?
    if options.mandatoryKeys?
      for entry in options.mandatoryKeys
        allowedKeys.push entry unless allowedKeys[entry]
    # validate
    if options.instanceOf?
      unless value instanceof options.instanceOf
        return done new Error("#{name} needs an object of #{options.instanceOf}
          as value."), null, cb
      return done null, value, cb
    if typeof value isnt 'object' or value instanceof Array
      return done new Error("The value for #{name} has to be an object."), null, cb
    if allowedKeys.length
      for key of value
        unless key in allowedKeys
          return done new Error("The key #{key} is not allowed for #{name}."), null, cb
    if options.mandatoryKeys?
      for key in options.mandatoryKeys
        keys = Object.keys value
        unless key in keys
          return done new Error("The key #{key} is missing for #{name}."), null, cb
    # done return resulting value
    return done null, value, cb

  describe: (options = {}) ->
    text = 'Here an object have to be given. '

    if options.optional
      text += "The setting is optional. "
    text.trim()

###
- \c keySpec - validators for each entry, use '' to specify for all
entries. This is specifgied by a the key with an array of validator
function as string, options array.

All mandatory keys are automatically allowed keys if given, too.

@param mixed   $value    value to be checked
@param string  $name     readable variable identification
@param array   $options  specific settings

@return boolean
@throws Exception if not valid
###


###
Check for enumerated values.

A readable name is given and converted mostly in numeric values.

<b>Options:</b>
- \c values - list of possible values as hash with codes
- \c allowList - true if multiple entries can be selected
- \c delimiter - select the list separator for given value
(it can also be an regular expression)

@param mixed   $value    value to be checked
@param string  $name     readable variable identification
@param array   $options  specific settings

@return mixed  entry code or list of codes for option allowList
@throws Exception if not valid
###

