class StatusDesc < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'status'
  self.table_name= 'status_desc'
  
  def self.wsdl_find_by_status(status)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT TOP 1 [status_desc].* FROM [status_desc] WHERE [status_desc].[status] = N'#{status}'"})
#    Rails.logger.debug "**StatusDesc.wsdl_find_by_status response body: #{response.body}"
    if response.success?
      unless response.body[:do_query_response].blank? or response.body[:do_query_response][:return].to_i > 0
        xml_string = response.body[:do_query_response][:return]
        data= Hash.from_xml(xml_string)
        unless data['XML']['RESULT']['ROW'].blank?
          return data['XML']['RESULT']['ROW']
        else
          nil
        end
      else
        nil
      end
    else
      nil
    end
  end
  
#  def self.short_description(status)
#    status_desc = StatusDesc.wsdl_find_by_status(status)
#    status_desc['short_desc'] unless status_desc.blank?
#  end

  def short_description
    
  end
  
end