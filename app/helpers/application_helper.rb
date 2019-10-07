module ApplicationHelper
  
  def device_state_descriptions
    ["Ready", "Disconnected", "Waiting for Up response", "Waiting for Down response", "Waiting for Status", "Down", "Waiting for Transaction reply", 
      "Waiting for Down response (to begin load)", "Loading...", "Waiting for Config", "Supervisor mode", "Wait Reset", "Wait Read Cassettes", 
      "Wait Present", "Wait Totals", "Wait Reset Totals", "Wait Present", "Wait Test Dispense", "Wait Test Reject", "Wait Totals pre-Dispense", 
      "Wait Totals after Timeout", "Wait for Reset on bad dispense", "No Server", "Unknown", "Wait for ID", "Wait for Read Cassettes before redispense", 
      "Waiting for notes to be rejected", "Waiting for notes to be rejected", "Waiting for Lifts Up", "Waiting for new key", "Waiting for user response", 
      "Waiting for Bill Pay screen", "Waiting for bill pay amount", "Waiting for Bill Pay Confirmation", "WaitPortNbr", "WaitFeeAck", "WaitReject1",
      "WaitResponse", "WaitEnable", "EscrowReady", "WaitAccept", "WaitStore", "Last"]
  end
  
  def device_states
    
  end
  
  def generate_qr(text)
    require 'barby'
    require 'barby/barcode'
    require 'barby/barcode/qr_code'
    require 'barby/outputter/png_outputter'

    barcode = Barby::QrCode.new(text, level: :q, size: 5)
    base64_output = Base64.encode64(barcode.to_png({ xdim: 5 }))
#    "data:image/png;base64,#{base64_output}"
    "#{base64_output}"
  end
  
end
