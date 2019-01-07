# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $(document).on 'turbolinks:load', ->
    $('.box').boxWidget
      animationSpeed: 500
      collapseTrigger: '#box_tool_collapse'
      removeTrigger: '#box_tool_remove'
      collapseIcon: 'fa-minus'
      expandIcon: 'fa-plus'
      removeIcon: 'fa-times'

  ### Start QR Code Scanner ###
  load_consumer_qrcode_scanner = ->
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

      $('#qrcode_scanner_modal').on 'hidden.bs.modal', (e) ->
        codeReader.reset()
        console.log 'ZXing code reader reset'
        return

      ).catch (err) ->
        console.error err
      console.log 'Started continuous decode from camera with id ' + firstDeviceId
      return

  find_consumer_user_by_barcode_ajax = ->
    barcode_number = $('#barcode_number').val()
    amount = parseFloat($('#amount').val())
    $.ajax
      url: "/customers/" + barcode_number + "/find_by_barcode"
      dataType: 'json'
      success: (data) ->
        $('#scan_spinner').hide()
        first_name = data.first_name
        last_name = data.last_name
        balance = parseFloat(data.balance)
        consumer_customer_account_id = data.account_id
        # alert "Consumer User " + first_name + " " + last_name + ", Balance: " + balance
        $('#consumer_details').append "<p>" + first_name + " " + last_name + "<br> Balance: " + balance + "</p>"
        if balance >= amount
          $('#from_account_id').val consumer_customer_account_id
          $('#quick_purchase_button').show()
        else
          alert "Balance will not cover amount."
          $('#open_consumer_qrcode_scanner_button').hide()
        return
      error: ->
        # spinner_icon.hide()
        alert 'There was a problem finding consumer user.'
        return
    return
  
  $('#purchase_details').on 'click', '#open_consumer_qrcode_scanner_button', (e) ->
    amount = parseFloat($('#amount').val())
    if amount > 0
      $('#scan_spinner').show()
      $('#open_consumer_qrcode_scanner_button').hide()
      load_consumer_qrcode_scanner()
    else
      alert "Amount must be greater than $0"
      return false
  ### End QR Code Scanner ###