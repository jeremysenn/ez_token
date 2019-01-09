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

  $('#show_account_code_button').on 'click', ->
    $('#generating_barcode_spinner').show()
    customer_id = $(this).data( "customer-id" )
    $.ajax
      url: "/customers/" + customer_id + "/barcode"
      dataType: 'json'
      success: (data) ->
        $('#generating_barcode_spinner').hide()
        barcode_string = data.barcode_string
        # $('#barcode_contents').append barcode_string
        document.getElementById('barcode_contents').setAttribute 'src', "data:image/png;base64," + barcode_string
        return
      error: (xhr) ->
        $('#generating_barcode_spinner').hide()
        error = $.parseJSON(xhr.responseText).error
        alert error
        console.log error
        return
    return