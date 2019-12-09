# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $(document).on 'turbolinks:load', ->

    $('.select2_accounts').select2
      minimumInputLength: 2
      cache: true
      allowClear: true
      placeholder: "-- Search --"

  # Make sure select2 isn't applied multiple times by turbolinks
  $(document).on 'turbolinks:before-cache', ->
    if $('.select2_accounts').length
      $('.select2_accounts').select2 'destroy'
    return