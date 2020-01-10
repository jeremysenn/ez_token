# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $(document).on 'turbolinks:load', ->
    
    loading_sms_messages = false
    $('a.load-more-sms-messages').on 'inview', (e, visible) ->
      return if loading_sms_messages or not visible
      loading_sms_messages = true
      $('#spinner').show()
      $('a.load-more-sms-messages').hide()

      $.getScript $(this).attr('href'), ->
        loading_sms_messages = false

    # Scroll customer into view if active
    if $('#active_customer').length
      customerTopPosition = $('#active_customer').position().top
      #$('#customer_list').scrollTop customerTopPosition
      $('#customer_list').animate scrollTop: customerTopPosition, 'fast'

    $('select#customer_id').select2
      theme: 'bootstrap'
      minimumInputLength: 3
      dropdownParent: $('#new_customer_message_form')
      ajax:
        #url: '/accounts'
        url: '/customers'
        dataType: 'json'
        delay: 250

    $('#send_new_sms_message').on 'click', '#send_message_button', (e) ->
      $('#sending_message_spinner_icon').show()
      $('#send_message_icon').hide()

    #$('#send_new_sms_message').on 'ajax:success', (a, b, c) ->
    $('#send_new_sms_message').on 'ajax:complete', (a, b, c) ->
      $(this).find('input[type="text"]').val ''
      $('#sending_message_spinner_icon').hide()
      $('#send_message_icon').show()
      return
    
  # Make sure select2 isn't applied multiple times by turbolinks
  $(document).on 'turbolinks:before-cache', ->
    $('select#customer_id').select2 'destroy'
    return

  

