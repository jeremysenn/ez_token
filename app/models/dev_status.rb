class DevStatus < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'dev_id'
  
  belongs_to :device, :foreign_key => 'dev_id'
  
  #############################
  #     Instance Methods      #
  #############################
  
  def status_description
    status_desc = StatusDesc.find_by(status: status)
    unless status_desc.blank?
      return status_desc.short_desc
    else
      return "N/A"
    end
#    status_desc = StatusDesc.find_by_status(status)
#    unless status_desc.blank?
#      return status_desc.short_desc
#    else
#      return "N/A"
#    end
  end
  
  #############################
  #     Class Methods         #
  #############################
  
  def self.wsdl_find_all
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT * FROM dev_statuses"})
#    Rails.logger.debug "**DevStatus.wsdl_find_all response body: #{response.body}"
    if response.success?
      unless response.body[:do_query_response].blank? or response.body[:do_query_response][:return].to_i > 0
        xml_string = response.body[:do_query_response][:return]
        data= Hash.from_xml(xml_string)
        unless data['XML']['RESULT']['ROW'].blank?
          if data["XML"]["RESULT"]["ROW"].is_a? Hash # Only one result returned, so put it into an array
            return [data['XML']['RESULT']['ROW']]
          else
            return data['XML']['RESULT']['ROW']
          end
        else
          []
        end
      else
        []
      end
    else
      []
    end
  end
  
  def self.wsdl_find_all_by_device_id(dev_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT [dev_statuses].* FROM [dev_statuses] WHERE [dev_statuses].[dev_id] = #{dev_id}"})
#    Rails.logger.debug "**DevStatus.wsdl_find_all_by_device_id response body: #{response.body}"
    if response.success?
      unless response.body[:do_query_response].blank? or response.body[:do_query_response][:return].to_i > 0
        xml_string = response.body[:do_query_response][:return]
        data= Hash.from_xml(xml_string)
        unless data['XML']['RESULT']['ROW'].blank?
          if data["XML"]["RESULT"]["ROW"].is_a? Hash # Only one result returned, so put it into an array
            return [data['XML']['RESULT']['ROW']]
          else
            return data['XML']['RESULT']['ROW']
          end
        else
          []
        end
      else
        []
      end
    else
      []
    end
  end
  
  def self.wsdl_find_last_20_by_device_id(dev_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT TOP 20 [dev_statuses].* FROM [dev_statuses] WHERE [dev_statuses].[dev_id] = #{dev_id} ORDER BY date_time desc"})
#    Rails.logger.debug "**DevStatus.wsdl_find_last_50_by_device_id response body: #{response.body}"
    if response.success?
      unless response.body[:do_query_response].blank? or response.body[:do_query_response][:return].to_i > 0
        xml_string = response.body[:do_query_response][:return]
        data= Hash.from_xml(xml_string)
        unless data['XML']['RESULT']['ROW'].blank?
          if data["XML"]["RESULT"]["ROW"].is_a? Hash # Only one result returned, so put it into an array
            return [data['XML']['RESULT']['ROW']]
          else
            return data['XML']['RESULT']['ROW']
          end
        else
          []
        end
      else
        []
      end
    else
      []
    end
  end
  
  def self.wsdl_find_first_by_status(status)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT TOP 1 [dev_statuses].* FROM [dev_statuses] WHERE [dev_statuses].[status] = N'#{status}'"})
#    Rails.logger.debug "**DevStatus.wsdl_find_first_by_status response body: #{response.body}"
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
  
end