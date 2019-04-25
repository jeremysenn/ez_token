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
    load_request_payment_qrcode_scanner = ->
      codeReader = new (ZXing.BrowserQRCodeReader)
      console.log 'Request payment ZXing code reader initialized'
      codeReader.getVideoInputDevices().then (videoInputDevices) ->
        sourceSelect = document.getElementById('sourceSelect')
        #firstDeviceId = videoInputDevices[0].deviceId
        ###
        #if videoInputDevices.length > 1
        #  videoInputDevices.forEach (element) ->
        #    sourceOption = document.createElement('option')
        #    sourceOption.text = element.label
        #    sourceOption.value = element.deviceId
        #    sourceSelect.appendChild sourceOption
        #    return
          sourceSelectPanel = document.getElementById('sourceSelectPanel')
          sourceSelectPanel.style.display = 'block'
        ###
        #codeReader.decodeFromInputVideoDevice(firstDeviceId, 'video').then((result) ->
        codeReader.decodeFromInputVideoDevice(undefined, 'video').then((result) ->
          barcode_number = result.text
          console.log barcode_number
          $('#qrcode_scanner_modal').modal('hide')
          $('#barcode_number').val barcode_number
          find_customer_by_barcode_ajax()
          codeReader.reset()
          console.log 'ZXing code reader reset'

        $('#request_payment_qrcode_scanner_modal').on 'hidden.bs.modal', (e) ->
          $('#request_payment_scan_spinner').hide()
          $('#open_request_payment_qrcode_scanner_button').show()
          codeReader.reset()
          console.log 'ZXing code reader reset'
          return

        ).catch (err) ->
          console.error err
        # console.log 'Started continuous decode from camera with id ' + firstDeviceId
        console.log 'Started continuous decode from camera'
        return

    find_customer_by_barcode_ajax = ->
      barcode_number = $('#barcode_number').val()
      company_id = $('#company_id').val()
      event_id = $('#event_id').val()
      amount = parseFloat($('#amount').val())
      $.ajax
        url: "/customers/" + barcode_number + "/find_by_barcode"
        dataType: 'json'
        data:
          company_id: company_id
          event_id: event_id
        success: (data) ->
          first_name = data.first_name
          last_name = data.last_name
          balance = parseFloat(data.balance)
          consumer_customer_account_id = data.account_id
          customer_barcode_id = data.customer_barcode_id
          $('#consumer_details').append "<p>" + first_name + " " + last_name + "<br> Balance: OK </p>"
          if balance >= amount
            $('#scan_spinner').show()
            $('#open_consumer_qrcode_scanner_button').hide()
            # $('#from_account_id').val consumer_customer_account_id
            $('#scanned_from_account_id').val consumer_customer_account_id
            $('#customer_barcode_id').val customer_barcode_id
            $("#amount").prop("readonly", true)
            $('#quick_purchase_form').submit()
            $(".cash_register_chime")[0].play()
          else
            alert "Balance will not cover amount."
            $('#open_consumer_qrcode_scanner_button').hide()
          return
        error: (xhr) ->
          $('#scan_spinner').hide()
          error = $.parseJSON(xhr.responseText).error
          alert error
          console.log error
          $('#open_consumer_qrcode_scanner_button').show()
          return
      return

    load_send_payment_qrcode_scanner = ->
      sendPaymentcodeReader = new (ZXing.BrowserQRCodeReader)
      console.log 'Send payment ZXing code reader initialized'
      sendPaymentcodeReader.getVideoInputDevices().then (videoInputDevices) ->
        sourceSelect = document.getElementById('sourceSelect')
        #firstDeviceId = videoInputDevices[0].deviceId
        ###
        #if videoInputDevices.length > 1
        #  videoInputDevices.forEach (element) ->
        #    sourceOption = document.createElement('option')
        #    sourceOption.text = element.label
        #    sourceOption.value = element.deviceId
        #    sourceSelect.appendChild sourceOption
        #    return
          sourceSelectPanel = document.getElementById('sourceSelectPanel')
          sourceSelectPanel.style.display = 'block'
        ###
        #sendPaymentcodeReader.decodeFromInputVideoDevice(firstDeviceId, 'send_payment_video').then((result) ->
        sendPaymentcodeReader.decodeFromInputVideoDevice(undefined, 'send_payment_video').then((result) ->
          barcode_number = result.text
          console.log barcode_number
          $('#send_payment_qrcode_scanner_modal').modal('hide')
          $('#send_payment_barcode_number').val barcode_number
          find_user_by_qr_code_ajax()
          sendPaymentcodeReader.reset()
          console.log 'ZXing code reader reset'

        $('#send_payment_qrcode_scanner_modal').on 'hidden.bs.modal', (e) ->
          $('#send_payment_scan_spinner').hide()
          $('#open_send_payment_qrcode_scanner_button').show()
          sendPaymentcodeReader.reset()
          console.log 'Modal closed and ZXing code reader reset'
          return

        ).catch (err) ->
          console.error err
        #console.log 'Started continuous decode from camera with id ' + firstDeviceId
        console.log 'Started continuous decode from camera'
        return

    find_user_by_qr_code_ajax = ->
      barcode_number = $('#send_payment_barcode_number').val()
      company_id = $('#company_id').val()
      amount = parseFloat($('#request_payment_amount').val())
      $.ajax
        url: "/customers/" + barcode_number + "/find_by_barcode"
        dataType: 'json'
        data:
          company_id: company_id
        success: (data) ->
          first_name = data.first_name
          last_name = data.last_name
          to_account_id = data.account_id
          $('#scan_spinner').show()
          $('#open_send_payment_qrcode_scanner_button').hide()
          $('#send_payment_to_account_id').val to_account_id
          $("#send_payment_amount").prop("readonly", true);
          $('#send_payment_form').submit()
          return
        error: (xhr) ->
          error = $.parseJSON(xhr.responseText).error
          alert error
          console.log error
          $('#send_payment_scan_spinner').hide()
          $('#open_send_payment_qrcode_scanner_button').show()
          return
      return

    $('#request_payment_details').on 'click', '#open_request_payment_qrcode_scanner_button', (e) ->
      amount = parseFloat($('#amount').val())
      if amount > 0
        # $('#amount_requested').html "$" + amount
        $('.request_payment_amount').html "$" + amount
        $('#request_payment_scan_spinner').show()
        $('#open_request_payment_qrcode_scanner_button').hide()
        load_request_payment_qrcode_scanner()
      else
        alert "Amount must be greater than $0"
        return false

    $('#send_payment_details').on 'click', '#open_send_payment_qrcode_scanner_button', (e) ->
      amount = parseFloat($('#send_payment_amount').val())
      account_balance = parseFloat($('#account_balance').val())
      if amount > 0 && account_balance >= amount
        $('.send_payment_amount').html "$" + amount
        $('#send_payment_scan_spinner').show()
        $('#open_send_payment_qrcode_scanner_button').hide()
        load_send_payment_qrcode_scanner()
      else
        alert "Amount must be greater than $0 and your balance must cover the amount."
        return false

    ### End QR Code Scanner ###