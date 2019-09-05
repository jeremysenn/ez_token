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
    customerTopPosition = $('#active_customer').position().top
    $('#customer_list').animate scrollTop: customerTopPosition, 'fast'
    #$('#customer_list').scrollTop customerTopPosition
