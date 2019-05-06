class BillHist < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'old_start'
  self.table_name= 'bill_hist'
  
  belongs_to :device, :foreign_key => 'dev_id'
  
  #############################
  #     Instance Methods      #
  #############################
  
  #############################
  #     Class Methods      #
  #############################
  
  def self.old_start_total(cut_date)
    old_start_total = 0
    bill_hists = BillHist.where(cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      old_start_total += (bill_hist.old_start * bill_hist.denomination)
    end
    return old_start_total
  end
  
  def self.device_old_start_total(device_id, cut_date)
    old_start_total = 0
    bill_hists = BillHist.where(dev_id: device_id, cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      old_start_total += (bill_hist.old_start * bill_hist.denomination)
    end
    return old_start_total
  end
  
  def self.new_start_total(cut_date)
    new_start_total = 0
    bill_hists = BillHist.where(cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      new_start_total += (bill_hist.new_start * bill_hist.denomination)
    end
    return new_start_total
  end
  
  def self.device_new_start_total(device_id, cut_date)
    new_start_total = 0
    bill_hists = BillHist.where(dev_id: device_id, cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      new_start_total += (bill_hist.new_start * bill_hist.denomination)
    end
    return new_start_total
  end
  
  def self.terminal_bill_dispensed(cut_date)
    terminal_bill_dispensed = 0
    bill_hists = BillHist.where(cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      terminal_bill_dispensed += (bill_hist.old_term_cyc * bill_hist.denomination)
    end
    return terminal_bill_dispensed
  end
  
  def self.host_bill_dispensed(cut_date)
    host_bill_dispensed = 0
    bill_hists = BillHist.where(cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      host_bill_dispensed += (bill_hist.old_host_cyc * bill_hist.denomination)
    end
    return host_bill_dispensed
  end
  
  def self.device_host_bill_dispensed(device_id, cut_date)
    host_bill_dispensed = 0
    bill_hists = BillHist.where(dev_id: device_id, cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      host_bill_dispensed += (bill_hist.old_host_cyc * bill_hist.denomination)
    end
    return host_bill_dispensed
  end
  
  def self.added(cut_date)
    added = 0
    bill_hists = BillHist.where(cut_dt: cut_date)
    bill_hists.each do |bill_hist|
      added += (bill_hist.added * bill_hist.denomination)
    end
    return added
  end
  
  def self.wsdl_find_all_by_device_id(dev_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT [bill_hist].* FROM [bill_hist] WHERE [bill_hist].[dev_id] = #{dev_id}"})
    Rails.logger.debug "**BillHist.wsdl_find_all_by_device_id response body: #{response.body}"
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
  
  def self.wsdl_find_all_by_device_id_and_cut_date(device_id, cut_date)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT [bill_hist].* FROM [bill_hist] WHERE [bill_hist].[dev_id] = #{device_id} AND [bill_hist].[cut_dt] = N'#{cut_date}'"})
    Rails.logger.debug "**BillHist.wsdl_find_all_by_device_id_and_cut_date response body: #{response.body}"
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
    response = client.call(:do_query, message: {Query: "SELECT TOP 20 [bill_hist].* FROM [bill_hist] WHERE [bill_hist].[dev_id] = #{dev_id} ORDER BY cut_dt desc"})
    Rails.logger.debug "**BillHist.wsdl_find_all_by_device_id response body: #{response.body}"
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
  
  def self.wsdl_find_last_5_distinct_by_device_id(dev_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT DISTINCT TOP 5 cut_dt FROM [bill_hist] WHERE [bill_hist].[dev_id] = #{dev_id} ORDER BY cut_dt desc"})
    Rails.logger.debug "**BillHist.wsdl_find_all_by_device_id response body: #{response.body}"
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
  
#  def self.new_start_total(device_id, cut_date)
#    new_start_total = 0
#    bill_hists = BillHist.wsdl_find_all_by_device_id_and_cut_date(device_id, cut_date)
#    bill_hists.each do |bill_hist|
#      new_start_total += (bill_hist['new_start'].to_i * bill_hist['denomination'].to_i)
#    end
#    return new_start_total
#  end
  
  def self.old_start_total(device_id, cut_date)
    old_start_total = 0
    bill_hists = BillHist.wsdl_find_all_by_device_id_and_cut_date(device_id, cut_date)
    bill_hists.each do |bill_hist|
      old_start_total += (bill_hist['old_start'].to_i * bill_hist['denomination'].to_i)
    end
    return old_start_total
  end
  
#  def self.added(device_id, cut_date)
#    added = 0
#    bill_hists = BillHist.wsdl_find_all_by_device_id_and_cut_date(device_id, cut_date)
#    bill_hists.each do |bill_hist|
#      added += (bill_hist['added'].to_i * bill_hist['denomination'].to_i)
#    end
#    return added
#  end
  
  def self.host_bill_dispensed(device_id, cut_date)
    host_bill_dispensed = 0
    bill_hists = BillHist.wsdl_find_all_by_device_id_and_cut_date(device_id, cut_date)
    bill_hists.each do |bill_hist|
      host_bill_dispensed += (bill_hist['old_host_cyc'].to_i * bill_hist['denomination'].to_i)
    end
    return host_bill_dispensed
  end
  
end