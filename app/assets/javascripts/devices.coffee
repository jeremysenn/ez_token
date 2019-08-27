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
  ### ATM Reset Command ###

  ### Get Term Totals on Replenish Command ###
  $('#atm_profile_box').on 'click', '.replenish_command_button', (e) ->
    e.preventDefault()
    device_id = $(this).data( "device-id" )
    spinner_icon = $(".getting_term_totals_spinner")
    spinner_icon.show()
    $.ajax
      url: "/devices/" + device_id + "/get_term_totals"
      dataType: 'json'
      success: (data) ->
        spinner_icon.hide()
        bin1 = data.bin1
        bin2 = data.bin2
        bin3 = data.bin3
        bin4 = data.bin4
        bin5 = data.bin5
        bin6 = data.bin6
        bin7 = data.bin7
        bin8 = data.bin8
        $(".term_totals").html('<p>Bin 1: ' + bin1 + ' Bin 2: ' + bin2 + ' Bin 3: ' + bin3 + ' Bin 4: ' + bin4 + '<br>' + 'Bin 5: ' + bin5 + ' Bin 6: ' + bin6 + ' Bin 7: ' + bin7 + ' Bin 8: ' + bin8)
        return
      error: ->
        spinner_icon.hide()
        alert 'There was a problem getting term totals'
        return
  ### End Get Term Totals on Replenish Command ###

  $('.term_totals_reset_check_box').click ->
    $(this).closest('form').find(':submit').prop 'disabled', !$(this).prop('checked')
    return

  $('.modal').on 'keyup', '.bin_field', ->
    denomination = parseFloat($(this).data( "denomination" ))
    bin_notes = parseFloat($(this).val())
    total = denomination * bin_notes
    $(this).parent().next('.bin_help').html('$' + total)

  # Endless page for withdrawals
  loading_withdrawals = false
  $('a.load-more-withdrawals').on 'inview', (e, visible) ->
    return if loading_withdrawals or not visible
    loading_withdrawals = true
    $('#withdrawals_spinner').show()
    $('a.load-more-withdrawals').hide()

    $.getScript $(this).attr('href'), ->
      loading_withdrawals = false

  # Endless page for dev_statuses
  loading_dev_statuses = false
  $('a.load-more-dev-statuses').on 'inview', (e, visible) ->
    return if loading_dev_statuses or not visible
    loading_dev_statuses = true
    $('#dev_statuses_spinner').show()
    $('a.load-more-dev-statuses').hide()

    $.getScript $(this).attr('href'), ->
      loading_dev_statuses = false