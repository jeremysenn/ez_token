# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/'


$(document).on 'turbolinks:load', ->

  ### Un-check Check Boxes When Radio Button Selected ###
  $('.account_event_ids input[type="radio"]').click ->
    #state = $(this).prop('checked')
    $('input[type="checkbox"]').attr("checked", false);
    return

  ### Un-select Radio Button When Check Box Checked ###
  #$('input:checked').click ->
  $('.account_event_ids input[type="checkbox"]').click ->
    $('input[type="radio"]').attr("checked", false);
    return

  ### Endless Page ###
  loading_accounts = false
  $('a.load-more-accounts').on 'inview', (e, visible) ->
    return if loading_accounts or not visible
    loading_accounts = true
    $('#spinner').show()
    $('a.load-more-accounts').hide()

    $.getScript $(this).attr('href'), ->
      loading_accounts = false