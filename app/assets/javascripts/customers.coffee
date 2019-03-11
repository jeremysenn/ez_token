# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $(document).on 'turbolinks:load', ->
    $('a[data-toggle="tab"]').on 'show.bs.tab', (e) ->
      #save the latest tab
      localStorage.setItem 'lastTab', $(e.target).attr('href')
      return
    #go to the latest tab, if it exists:
    lastTab = localStorage.getItem('lastTab')
    if lastTab
      $('a[href="' + lastTab + '"]').click()
    return

    $('input[name=file]').change ->
      alert $(this).val()
      return

    ### Start Avatar Upload ###
    # drop just the filename in the display field
    $('#customer_avatar').change ->
      alert 'new one!'
      #$('#file-display').val $(@).val().replace(/^.*[\\\/]/, '')
    # trigger the real input field click to bring up the file selection dialog
    #$('#upload-btn').click ->
    #  $('#customer_avatar').click()
    ### End Avatar Upload ###

  $('.show_account_code_button').on 'click', ->
    $('.generating_barcode_spinner').show()
    customer_id = $(this).data( "customer-id" )
    company_id = $(this).data( "company-id" )
    account_id = $(this).data( "account-id" )
    amount = $('#withdrawal_amount').val()
    $.ajax
      url: "/customers/" + customer_id + "/barcode"
      dataType: 'json'
      data: 
        company_id: company_id
        account_id: account_id
        amount: amount
      success: (data) ->
        $('.generating_barcode_spinner').hide()
        barcode_string = data.barcode_string
        # $('#barcode_contents').append barcode_string
        document.getElementById("company_" + company_id + "_barcode_contents").setAttribute 'src', "data:image/png;base64," + barcode_string
        return
      error: (xhr) ->
        $('.generating_barcode_spinner').hide()
        error = $.parseJSON(xhr.responseText).error
        alert error
        console.log error
        return
    return

  ### Start Consumer QR Code Payment Scanner ###
  load_consumer_qr_code_payment_scanner = ->
    codeReader = new (ZXing.BrowserQRCodeReader)
    console.log 'ZXing code reader initialized'
    codeReader.getVideoInputDevices().then (videoInputDevices) ->
      sourceSelect = document.getElementById('sourceSelect')
      firstDeviceId = videoInputDevices[0].deviceId
      ###
      if videoInputDevices.length > 1
        videoInputDevices.forEach (element) ->
          sourceOption = document.createElement('option')
          sourceOption.text = element.label
          sourceOption.value = element.deviceId
          sourceSelect.appendChild sourceOption
          return
        sourceSelectPanel = document.getElementById('sourceSelectPanel')
        sourceSelectPanel.style.display = 'block'
      ###
      codeReader.decodeFromInputVideoDevice(firstDeviceId, 'video').then((result) ->
        barcode_number = result.text
        console.log barcode_number
        $('#qrcode_scanner_modal').modal('hide')
        $('#barcode_number').val barcode_number
        find_consumer_user_by_barcode_ajax()
        codeReader.reset()
        console.log 'ZXing code reader reset'

      $('#qr_code_payment_scanner_modal').on 'hidden.bs.modal', (e) ->
        $('#scan_spinner').hide()
        $('#open_consumer_qr_code_payment_scanner_button').show()
        codeReader.reset()
        console.log 'ZXing code reader reset'
        return

      ).catch (err) ->
        console.error err
      console.log 'Started continuous decode from camera with id ' + firstDeviceId
      return

  $('#qr_code_payment_details').on 'click', '#open_qr_code_payment_scanner_button', (e) ->
    $('#scan_spinner').show()
    $('#open_consumer_qr_code_payment_scanner_button').hide()
    load_consumer_qr_code_payment_scanner()
  ### End Consumer QR Code Payment Scanner ###

  $('#purchase_details').on 'click', '#open_buddy_search_button', (e) ->
    amount = parseFloat($('#amount').val())
    if amount > 0
      $('.request_payment_amount').html "$" + amount
    else
      alert "Amount must be greater than $0"
      return false

  $('#request_payment_details').on 'click', '#open_buddy_search_button', (e) ->
    amount = parseFloat($('#amount').val())
    if amount > 0
      $('.request_payment_amount').html "$" + amount
    else
      alert "Amount must be greater than $0"
      return false

  $('#send_payment_details').on 'click', '#open_send_payment_buddy_search_button', (e) ->
    amount = parseFloat($('#send_payment_amount').val())
    account_balance = parseFloat($('#account_balance').val())
    if amount > 0 && account_balance >= amount
      $('.send_payment_amount').html "$" + amount
    else
      alert "Amount must be greater than $0 and your balance must cover the amount."
      return false

  $('#withdrawal_details').on 'click', '#open_withdrawal_code_button', (e) ->
    amount = parseFloat($('#withdrawal_amount').val())
    account_balance = parseFloat($('#account_balance').val())
    if amount > 0 && account_balance >= amount
      $('.withdrawal_code_amount').html "$" + amount
    else
      alert "Withdrawal amount must be greater than $0 and your balance must cover the amount."
      return false

  $('.create_account_and_add_to_event_link').on 'click', (e) ->
    e.preventDefault()
    spinner_icon = $(this).find( ".fa-spinner" )
    spinner_icon.show()
    customer_id = $(this).data( "customer-id" )
    event_id = $(this).data( "event-id" )
    plus_circle_icon = $(this).find( ".fa-plus-circle" )
    plus_circle_icon.hide()
    $.ajax
      url: "/customers/" + customer_id + "/create_account_and_add_to_event"
      dataType: 'json'
      data: 
        event_id: event_id
      success: (data) ->
        spinner_icon.hide()
        $(this).hide()
        return
      error: (xhr) ->
        spinner_icon.hide()
        plus_circle_icon.show()
        error = $.parseJSON(xhr.responseText).error
        alert error
        console.log error
        return
    return

    ### Un-check Check Boxes When Radio Button Selected ###
    $('.customer_accounts_account[event_ids][] input[type="radio"]').click ->
      #state = $(this).prop('checked')
      $('input[type="checkbox"]').attr("checked", false);
      return

    ### Un-select Radio Button When Check Box Checked ###
    #$(' input:checked').click ->
    $('.account_event_ids input[type="checkbox"]').click ->
      $('input[type="radio"]').attr("checked", false);
      return