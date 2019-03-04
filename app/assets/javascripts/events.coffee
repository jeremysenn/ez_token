# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/'


$(document).on 'turbolinks:load', ->
  ### ATM Reset Command ###
  $('#commands-modal').on 'click', '.atm_command_button', (e) ->
    #user click on atm reset button button
    e.preventDefault()
    device_id = $(this).data( "device-id" )
    atm_command = $(this).data( "command" )
    spinner_icon = $(this).find('.fa-spinner')
    spinner_icon.show()
    $.ajax
      url: "/devices/" + device_id + "/send_atm_command"
      dataType: 'json'
      data: 
          command: atm_command
      success: (data) ->
        spinner_icon.hide()
        alert atm_command + " command sent."
        return
      error: ->
        spinner_icon.hide()
        alert 'There was a problem sending the ATM Reset command'
        return
    return
  ### ATM Reset Command ###

  ### Expire Accounts Checkbox Change ###
  $('#event_expire_accounts').on 'change', (e) ->
    checked = $(this).is(":checked")
    if checked
      $('#event_do_not_expire_accounts_check_boxes').hide()
      $('#event_do_not_expire_accounts_check_boxes_fieldset').prop("disabled", true)
      $('#event_expire_accounts_links').show()
      $('#event_expire_accounts_links_fieldset').prop("disabled", false)
    else
      $('#event_do_not_expire_accounts_check_boxes').show()
      $('#event_do_not_expire_accounts_check_boxes_fieldset').prop("disabled", false)
      $('#event_expire_accounts_links').hide()
      $('#event_expire_accounts_links_fieldset').prop("disabled", true)
    return
  ### End Expire Accounts Checkbox Change ###