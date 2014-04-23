exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo:
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^(?!app)/
    stylesheets:
      joinTo: 'stylesheets/app.css'
    templates:
      joinTo: 'javascripts/app.js'

  # clean compiled js file from modules header and wrap it like coffeescript should
  modules:
    definition: false
    wrapper: (path, data) ->
      """
    (function() {
      'use strict';
      #{data}
    }).call(this);
      """
