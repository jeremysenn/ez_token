module AchLogsHelper
  
  def ach_log_type_string(type_number)
    type_hash = {"0" => "Billed Directly", "1" => "Club Report", "2" => "Details Report"}
    return type_hash[type_number]
  end
  
end
