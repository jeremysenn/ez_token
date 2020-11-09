class BillCount < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'host_start_count'
  
  belongs_to :device, :foreign_key => 'dev_id'
  
  #############################
  #     Instance Methods      #
  #############################
  
  def count
    unless added_count.blank?
      host_start_count - host_cycle_count + added_count
    else
      host_start_count - host_cycle_count
    end
  end
  
  def denomination
    Denom.find_by_dev_id_and_cassette_id(dev_id, cassette_id).denomination
  end
  
  def status_description
    case status
    when 0
      return 'OK' 
    when 1
      return 'Empty'
    when 2
      return 'Fatal'
    when 3
      return 'Not Used'
    when 4
      return 'Low'
    when 5
      return 'Testing'
    when 6
      return 'Unknown'
    else
      return 'Unknown'
    end
  end
  
  #############################
  #     Class Methods         #
  #############################
  
  def self.find_all_by_device_id(device_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT [bill_counts].* FROM [bill_counts] WHERE [bill_counts].[dev_id] = #{device_id}"})
#    Rails.logger.debug "**BillCount.find_all_by_device_id response body: #{response.body}"
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
  
  def self.find_by_device_id_and_cassette_id(device_id, cassette_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT [bill_counts].* FROM [bill_counts] WHERE [bill_counts].[dev_id] = #{device_id} AND [bill_counts].[cassette_id] = #{cassette_id}"})
#    Rails.logger.debug "**BillCount.find_by_device_id_and_cassette_id response body: #{response.body}"
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