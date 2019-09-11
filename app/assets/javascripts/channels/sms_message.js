$(function() {
  $('[data-channel-subscribe="sms_message"]').each(function(index, element) {
    var $element = $(element),
        customer_id = $element.data('customer-id');
        messageTemplate = $('[data-role="message-template"]');

    //$element.animate({ scrollTop: $element.prop("scrollHeight")}, 1000)        

    App.cable.subscriptions.create(
      {
        channel: "SmsMessageChannel",
        customer: customer_id
      },
      {
        received: function(data) {
          $element.prepend(data);
          
          //var content = messageTemplate.children().clone(true, true);
          //content.find('[data-role="message-text"]').text(data);
          //content.find('[data-role="message-date"]').text(data.updated_at);
          //$element.prepend(content);
          //$element.animate({ scrollTop: $element.prop("scrollHeight")}, 1000);
        }
      }
    );
  });
});

$(function() {
  $('[data-channel-subscribe="last_sms_message"]').each(function(index, element) {
    var $element = $(element),
        customer_id = $element.data('customer-id');

    $element.animate({ scrollTop: $element.prop("scrollHeight")}, 1000);      

    App.cable.subscriptions.create(
      {
        channel: "SmsMessageBodyChannel",
        customer: customer_id
      },
      {
        received: function(data) {
          if (data.length > 30)
            text= data.substring(0,27) + '...';
          else
            text = data;
          $element.html(text);
        }
      }
    );
  });
});