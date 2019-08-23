class Device < ActiveRecord::Base
  self.primary_key = 'dev_id'
  establish_connection :ez_cash
  
  
  belongs_to :company, :foreign_key => "CompanyNbr"
  has_many :bill_counts, :foreign_key => "dev_id"
  has_many :denoms, :foreign_key => "dev_id"
  has_many :transactions, :foreign_key => "dev_id"
  has_many :dev_statuses, :foreign_key => 'dev_id'
  has_many :bill_hists, :foreign_key => "dev_id"
  has_many :cards, :foreign_key => "dev_id"
  
  #############################
  #     Instance Methods      #
  #############################
  
  def cards_query(start_date, end_date)
    cards.where("issued_date >= ? AND issued_date < ? AND avail_amt > ?", start_date, end_date.to_date + 1.day, 0)
  end
  
  def issued_prior_paid_in_period_cards_query(start_date, end_date)
    total = 0
    cards_list = cards.where("issued_date < ? AND last_activity_date >= ? AND last_activity_date <= ? AND card_status = ?", start_date, start_date, end_date, 'CL')
    cards_list.each do |card|
      total = total + card.card_amt
    end
    return total
  end
  
  def total_issued_in_period_cards_query(start_date, end_date)
    total = 0
    cards_list = cards.where("issued_date >= ? AND issued_date < ?", start_date, end_date.to_date + 1.day)
    cards_list.each do |card|
      total = total + card.card_amt
    end
    return total
  end
  
  def issued_but_not_paid_in_period_cards_query(start_date, end_date)
    total = 0
    cards_list = cards.where("issued_date >= ? AND issued_date < ? AND avail_amt > ?", start_date, end_date.to_date + 1.day, 0)
    cards_list.each do |card|
      total = total + card.card_amt
    end
    return total
  end
  
  def issued_and_paid_in_period_cards_query(start_date, end_date)
    total = 0
    cards_list = cards.where("issued_date >= ? AND issued_date < ? AND avail_amt = ?", start_date, end_date.to_date + 1.day, 0)
    cards_list.each do |card|
      total = total + card.card_amt
    end
    return total
  end
  
  def caution_status_description
    unless caution_status.blank?
      status_description = StatusDesc.find_by_status(caution_status)
      unless status_description.blank?
        status_description.short_desc
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def critical_status?
    caution_flag == 2
  end
  
  def caution_status?
    caution_flag == 1
  end
  
  def okay_status?
    caution_flag == nil or caution_flag == 0
  end
  
  def inactive?
    unless inactive_flag.blank?
      inactive_flag > 0
    else
      return false
    end
  end
  
#  def bill_counts
#    BillCount.where(dev_id: id)
#  end
#  
#  def bill_hists
#    BillHist.where('cut_dt >= ? AND dev_id = ?', 30.days.ago, id)
#  end
  
  def cards
    Card.where(dev_id: id)
  end
  
  def cards_last_30_days
    Card.where('last_activity_date >= ? AND dev_id = ? AND avail_amt > ?', 30.days.ago, id, 0)
  end
  
  def cards_today
    Card.where('last_activity_date >= ? AND dev_id = ? AND avail_amt > ?', Date.today.beginning_of_day, id, 0)
  end
  
#  def dev_statuses
#    DevStatus.where(dev_id: id)
#  end
  
  def dev_statuses_last_30_days
    DevStatus.where('date_time >= ? AND dev_id = ?', 30.days.ago, id)
  end
  
#  def transactions
#    Transaction.where(dev_id: id)
#  end
  
  def transactions_last_30_days
    Transaction.where('date_time >= ? AND dev_id = ?', 30.days.ago, id)
  end
  
  def transactions_with_amount
    Transaction.where('dev_id = ? AND amt_req IS NOT NULL AND amt_req > ?', id, 0)
  end
  
  def transactions_last_30_days_with_amount
    Transaction.where('date_time >= ? AND dev_id = ? AND amt_req IS NOT NULL AND amt_req > ?', 30.days.ago, id, 0)
  end
  
#  def denoms
#    Denom.where(dev_id: id)
#  end
  
  ### Start - bill_count records ###
  def bill_count_1
    BillCount.find_by_dev_id_and_cassette_id(id, "1")
  end
  
  def bill_count_2
    BillCount.find_by_dev_id_and_cassette_id(id, "2")
  end
  
  def bill_count_3
    BillCount.find_by_dev_id_and_cassette_id(id, "3")
  end
  
  def bill_count_4
    BillCount.find_by_dev_id_and_cassette_id(id, "4")
  end
  
  def bill_count_5
    BillCount.find_by_dev_id_and_cassette_id(id, "5")
  end
  
  def bill_count_6
    BillCount.find_by_dev_id_and_cassette_id(id, "6")
  end
  
  def bill_count_7
    BillCount.find_by_dev_id_and_cassette_id(id, "7")
  end
  
  def bill_count_8
    BillCount.find_by_dev_id_and_cassette_id(id, "8")
  end
  
  def bill_count_a # Previously cassette 99
    BillCount.find_by_dev_id_and_cassette_id(id, "A")
  end
  
  def bill_count(cassette_id)
    case cassette_id
    when 1
      bill_count_1
    when 2
      bill_count_2
    when 3
      bill_count_3
    when 4
      bill_count_4
    when 5
      bill_count_5
    when 6
      bill_count_6
    when 7
      bill_count_7
    when 8
      bill_count_8
    when a
      bill_count_a
    else
      nil
    end
  end
  
  ### End - bill_count records ###
  
  def bin_1_count
    start = bill_count_1.host_start_count ||= 0
    added = bill_count_1.added_count ||= 0
    host_cycle = bill_count_1.host_cycle_count ||= 0
    unless bill_count_1.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_2_count
    start = bill_count_2.host_start_count ||= 0
    added = bill_count_2.added_count ||= 0
    host_cycle = bill_count_2.host_cycle_count ||= 0
    unless bill_count_2.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_3_count
    start = bill_count_3.host_start_count ||= 0
    added = bill_count_3.added_count ||= 0
    host_cycle = bill_count_3.host_cycle_count ||= 0
    unless bill_count_3.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_4_count
    start = bill_count_4.host_start_count ||= 0
    added = bill_count_4.added_count ||= 0
    host_cycle = bill_count_4.host_cycle_count ||= 0
    unless bill_count_4.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_5_count
    start = bill_count_5.host_start_count ||= 0
    added = bill_count_5.added_count ||= 0
    host_cycle = bill_count_5.host_cycle_count ||= 0
    unless bill_count_5.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_6_count
    start = bill_count_6.host_start_count ||= 0
    added = bill_count_6.added_count ||= 0
    host_cycle = bill_count_6.host_cycle_count ||= 0
    unless bill_count_6.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_7_count
    start = bill_count_7.host_start_count ||= 0
    added = bill_count_7.added_count ||= 0
    host_cycle = bill_count_7.host_cycle_count ||= 0
    unless bill_count_7.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_8_count
    start = bill_count_8.host_start_count ||= 0
    added = bill_count_8.added_count ||= 0
    host_cycle = bill_count_8.host_cycle_count ||= 0
    unless bill_count_8.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_a_count # Cash acceptor
    start = bill_count_a.host_start_count ||= 0
    added = bill_count_a.added_count ||= 0
    host_cycle = bill_count_a.host_cycle_count ||= 0
    unless bill_count_a.blank?
      start + added - host_cycle
    else
      return nil
    end
  end
  
  def bin_count(bin_number)
    case bin_number
    when 1
      bin_1_count
    when 2
      bin_2_count
    when 3
      bin_3_count
    when 4
      bin_4_count
    when 5
      bin_5_count
    when 6
      bin_6_count
    when 7
      bin_7_count
    when 8
      bin_8_count
    else
      0
    end
  end
  
  def bin_1_remaining # Total dollar amount remaining in bin/cassette 1
    denom = Denom.find_by_dev_id_and_cassette_id(id, "1")
    if denom.blank? or bin_1_count.blank?
      return 0
    else
      return bin_1_count * denom.denomination
    end
  end
  
  def bin_2_remaining # Total dollar amount remaining in bin/cassette 2
    denom = Denom.find_by_dev_id_and_cassette_id(id, "2")
    if denom.blank? or bin_2_count.blank?
      return 0
    else
      return bin_2_count * denom.denomination
    end
  end
  
  def bin_3_remaining # Total dollar amount remaining in bin/cassette 3
    denom = Denom.find_by_dev_id_and_cassette_id(id, "3")
    if denom.blank? or bin_3_count.blank?
      return 0
    else
      return bin_3_count * denom.denomination
    end
  end
  
  def bin_4_remaining # Total dollar amount remaining in bin/cassette 4
    denom = Denom.find_by_dev_id_and_cassette_id(id, "4")
    if denom.blank? or bin_4_count.blank?
      return 0
    else
      return bin_4_count * denom.denomination
    end
  end
  
  def bin_5_remaining # Total dollar amount remaining in bin/cassette 5
    denom = Denom.find_by_dev_id_and_cassette_id(id, "5")
    if denom.blank? or bin_5_count.blank?
      return 0
    else
      return bin_5_count * denom.denomination
    end
  end
  
  def bin_6_remaining # Total dollar amount remaining in bin/cassette 6
    denom = Denom.find_by_dev_id_and_cassette_id(id, "6")
    if denom.blank? or bin_6_count.blank?
      return 0
    else
      return bin_6_count * denom.denomination
    end
  end
  
  def bin_7_remaining # Total dollar amount remaining in bin/cassette 7
    denom = Denom.find_by_dev_id_and_cassette_id(id, "7")
    if denom.blank? or bin_7_count.blank?
      return 0
    else
      return bin_7_count * denom.denomination
    end
  end
  
  def bin_8_remaining # Total dollar amount remaining in bin/cassette 8
    denom = Denom.find_by_dev_id_and_cassette_id(id, "8")
    if denom.blank? or bin_8_count.blank?
      return 0
    else
      return bin_8_count * denom.denomination
    end
  end
  
  def bin_a_remaining # Total dollar amount remaining in bin/cassette A (previously 99)
    denom = Denom.find_by_dev_id_and_cassette_id(id, "A")
    if denom.blank? or bin_a_count.blank?
      return 0
    else
      return bin_a_count * denom.denomination
    end
  end
  
  def remaining # Total dollar amount remaining in this Device/ATM
    total = 0
    bill_counts.each do |bill_count|
      denoms.where(cassette_id: bill_count.cassette_id).each do |denom|
        total = total + (bill_count.count * denom.denomination)
      end
    end
    return total
#    return bin_1_remaining + bin_2_remaining + bin_3_remaining + bin_4_remaining + bin_5_remaining + bin_6_remaining + bin_7_remaining + bin_8_remaining
  end
  
  def bin_1_denom
    denoms.where(cassette_id: "1").where.not(denomination: 0).first
  end
  
  def bin_2_denom
    denoms.where(cassette_id: "2").where.not(denomination: 0).first
  end
  
  def bin_3_denom
    denoms.where(cassette_id: "3").where.not(denomination: 0).first
  end
  
  def bin_4_denom
    denoms.where(cassette_id: "4").where.not(denomination: 0).first
  end
  
  def bin_5_denom
    denoms.where(cassette_id: "5").where.not(denomination: 0).first
  end
  
  def bin_6_denom
    denoms.where(cassette_id: "6").where.not(denomination: 0).first
  end
  
  def bin_7_denom
    denoms.where(cassette_id: "7").where.not(denomination: 0).first
  end
  
  def bin_8_denom
    denoms.where(cassette_id: "8").where.not(denomination: 0).first
  end
  
  def bin_1_denomination
    bin_1_denom.denomination unless bin_1_denom.blank?
  end
  
  def bin_2_denomination
    bin_2_denom.denomination unless bin_2_denom.blank?
  end
  
  def bin_3_denomination
    bin_3_denom.denomination unless bin_3_denom.blank?
  end
  
  def bin_4_denomination
    bin_4_denom.denomination unless bin_4_denom.blank?
  end
  
  def bin_5_denomination
    bin_5_denom.denomination unless bin_5_denom.blank?
  end
  
  def bin_6_denomination
    bin_6_denom.denomination unless bin_6_denom.blank?
  end
  
  def bin_7_denomination
    bin_7_denom.denomination unless bin_7_denom.blank?
  end
  
  def bin_8_denomination
    bin_8_denom.denomination unless bin_8_denom.blank?
  end
  
  def bin_1_total_amount
    unless bin_1_count.blank? or bin_1_denomination.blank?
      return (bin_1_count * bin_1_denomination).round
    else
      nil
    end
  end
  
  def bin_2_total_amount
    unless bin_2_count.blank? or bin_2_denomination.blank?
      return (bin_2_count * bin_2_denomination).round
    else
      nil
    end
  end
  
  def bin_3_total_amount
    unless bin_3_count.blank? or bin_3_denomination.blank?
      return (bin_3_count * bin_3_denomination).round
    else
      nil
    end
  end
  
  def bin_4_total_amount
    unless bin_4_count.blank? or bin_4_denomination.blank?
      return (bin_4_count * bin_4_denomination).round
    else
      nil
    end
  end
  
  def bin_5_total_amount
    unless bin_5_count.blank? or bin_5_denomination.blank?
      return (bin_5_count * bin_5_denomination).round
    else
      nil
    end
  end
  
  def bin_6_total_amount
    unless bin_6_count.blank? or bin_6_denomination.blank?
      return (bin_6_count * bin_6_denomination).round
    else
      nil
    end
  end
  
  def bin_7_total_amount
    unless bin_7_count.blank? or bin_7_denomination.blank?
      return (bin_7_count * bin_7_denomination).round
    else
      nil
    end
  end
  
  def bin_8_total_amount
    unless bin_8_count.blank? or bin_8_denomination.blank?
      return (bin_8_count * bin_8_denomination).round
    else
      nil
    end
  end
  
  def transactions_date_span_search(start_date, end_date)
#    transactions.where("CreateDate" => start_date..end_date)
    transactions.where("CreateDate >= ? AND CreateDate <= ?", start_date, end_date)
  end
  
  def withdrawal_transactions_date_span_search(start_date, end_date)
    transactions.withdrawals.where("CreateDate >= ? AND CreateDate <= ?", start_date, end_date)
  end
  
  def transactions_total_amount_authorized_date_span(start_date, end_date)
    transactions = transactions_date_span_search(start_date, end_date)
    transactions_total_amount_authorized = 0
    transactions.each do |transaction|
      transactions_total_amount_authorized += transaction.amt_auth unless transaction.amt_auth.blank?
    end
    return transactions_total_amount_authorized
  end
  
  def withdrawal_transactions_total_amount_authorized_date_span(start_date, end_date)
    transactions = withdrawal_transactions_date_span_search(start_date, end_date)
    transactions_total_amount_authorized = 0
    transactions.each do |transaction|
      transactions_total_amount_authorized += transaction.amt_auth unless transaction.amt_auth.blank?
    end
    return transactions_total_amount_authorized
  end
  
  def status_string
    if caution_flag == '1' 
      "Caution"
    elsif caution_flag == '2'
      "Critical"
    else
      "Okay"
    end
  end
  
#  def remaining # Total dollar amount remaining in this Device/ATM
#    total = 0
#    Device.bill_counts(device_id).each do |bill_count|
#      total_count = bill_count['host_start_count'].to_i - bill_count['host_cycle_count'].to_i
#      denom = Denom.find_by_device_id_and_cassette_id(device_id, bill_count['cassette_id'])
#      unless denom['denomination'].blank?
#        total = total + (total_count * denom['denomination'].to_i)
#      end
##      Denom.find_by_device_id_and_cassette_id(device_id, bill_count['cassette_id']).each do |denom|
##        denomination = denom['denomination'].to_i
##        total = total + (total_count * denomination)
##      end
#    end
#    return total
#  end

  def send_atm_reset_command
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:send_atm_command, message: {DevID: self.id, Command: "atmReset"})
    Rails.logger.debug "** device.send_atm_reset_command response body: #{response.body}"
  end
  
  def send_atm_load_command
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:send_atm_command, message: {DevID: self.id, Command: "atmLoad"})
    Rails.logger.debug "** device.send_atm_load_command response body: #{response.body}"
  end
  
  def send_atm_up_command
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:send_atm_command, message: {DevID: self.id, Command: "atmUp"})
    Rails.logger.debug "** device.send_atm_up_command response body: #{response.body}"
  end
  
  def send_atm_down_command
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:send_atm_command, message: {DevID: self.id, Command: "atmDown"})
    Rails.logger.debug "** device.send_atm_down_command response body: #{response.body}"
  end
  
  def send_atm_disconnect_command
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:send_atm_command, message: {DevID: self.id, Command: "atmDisconnect"})
    Rails.logger.debug "** device.send_atm_disconnect_command response body: #{response.body}"
  end
  
  def add_cash(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:add_cash, message: {DevID: self.id, Bin1: bin_1, Bin2: bin_2, Bin3: bin_3, Bin4: bin_4, Bin5: bin_5, Bin6: bin_6,
        Bin7: bin_7, Bin8: bin_8})
#    Rails.logger.debug "** device.add_cash response body: #{response.body}"

    if response.success?
      unless response.body[:add_cash_response].blank? or response.body[:add_cash_response][:return] != true
        return true
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def reset_cash(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:reset_cash, message: {DevID: self.id, Bin1: bin_1, Bin2: bin_2, Bin3: bin_3, Bin4: bin_4, Bin5: bin_5, Bin6: bin_6,
        Bin7: bin_7, Bin8: bin_8})
    Rails.logger.debug "** device.reset_cash response body: #{response.body}"

    if response.success?
      unless response.body[:reset_cash_response].blank? or response.body[:reset_cash_response][:return] != true
        return true
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def add_coin(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:add_coin, message: {DevID: self.id, Bin1: bin_1, Bin2: bin_2, Bin3: bin_3, Bin4: bin_4, Bin5: bin_5, Bin6: bin_6,
        Bin7: bin_7, Bin8: bin_8})
    Rails.logger.debug "** device.add_coin response body: #{response.body}"

    if response.success?
      unless response.body[:add_coin_response].blank? or response.body[:add_coin_response][:return] != true
        return true
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def reset_coin(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:reset_coin, message: {DevID: self.id, Bin1: bin_1, Bin2: bin_2, Bin3: bin_3, Bin4: bin_4, Bin5: bin_5, Bin6: bin_6,
        Bin7: bin_7, Bin8: bin_8})
    Rails.logger.debug "** device.reset_coin response body: #{response.body}"

    if response.success?
      unless response.body[:reset_coin_response].blank? or response.body[:reset_coin_response][:return] != true
        return true
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def get_term_totals
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_term_totals, message: {DevID: self.id})
    Rails.logger.debug "** device.get_term_totals response body: #{response.body}"

    if response.success?
#      unless response.body[:get_term_totals_response].blank? or response.body[:get_term_totals_response][:return] != true 
      unless response.body[:get_term_totals_response].blank?
        return response.body[:get_term_totals_response]
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def coin_device
    Device.where(dev_id: coin_dev_id).first
  end
  
  #############################
  #     Class Methods      #
  #############################
  
  def self.wsdl_find_all
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT * FROM DEVICES"})
    Rails.logger.debug "**Device.wsdl_find_all response body: #{response.body}"
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
  
  def self.find_by_id(id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:do_query, message: {Query: "SELECT [devices].* FROM [devices] WHERE [devices].[dev_id] = N'#{id}'"})
    Rails.logger.debug "**Device.find_by_id response body: #{response.body}"
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
  
#  def self.bill_counts(device_id)
#    BillCount.find_all_by_device_id(device_id)
#  end
  
  def self.status_string(caution_flag)
    if caution_flag == '1' 
      "Caution"
    elsif caution_flag == '2'
      "Critical"
    else
      "Okay"
    end
  end
  
  def self.remaining(device_id) # Total dollar amount remaining in this Device/ATM
    total = 0
    Device.bill_counts(device_id).each do |bill_count|
      total_count = bill_count['host_start_count'].to_i - bill_count['host_cycle_count'].to_i
      denom = Denom.find_by_device_id_and_cassette_id(device_id, bill_count['cassette_id'])
      unless denom['denomination'].blank?
        total = total + (total_count * denom['denomination'].to_i)
      end
#      Denom.find_by_device_id_and_cassette_id(device_id, bill_count['cassette_id']).each do |denom|
#        denomination = denom['denomination'].to_i
#        total = total + (total_count * denomination)
#      end
    end
    return total
  end
  
  ### Start - bill_count records ###
  def self.bill_count_1(device_id)
    BillCount.find_by_device_id_and_cassette_id(device_id, "1")
  end
  
  def self.bill_count_2(device_id)
    BillCount.find_by_dev_id_and_cassette_id(device_id, "2")
  end
  
  def self.bill_count_3(device_id)
    BillCount.find_by_dev_id_and_cassette_id(device_id, "3")
  end
  
  def self.bill_count_4(device_id)
    BillCount.find_by_dev_id_and_cassette_id(device_id, "4")
  end
  
  def self.bill_count_5(device_id)
    BillCount.find_by_dev_id_and_cassette_id(device_id, "5")
  end
  
  def self.bill_count_6(device_id)
    BillCount.find_by_dev_id_and_cassette_id(device_id, "6")
  end
  
  def self.bill_count_7(device_id)
    BillCount.find_by_dev_id_and_cassette_id(device_id, "7")
  end
  
  def self.bill_count_8(device_id)
    BillCount.find_by_dev_id_and_cassette_id(device_id, "8")
  end
  
  def self.bill_count_a(device_id) # Previously cassette 99
    BillCount.find_by_dev_id_and_cassette_id(device_id, "A")
  end
  ### End - bill_count records ###
  
end