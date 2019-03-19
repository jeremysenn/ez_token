class Decrypt
  
  #############################
  #     Class Methods      #
  #############################
  
  def self.decryption(data)
    decipher = OpenSSL::Cipher::AES256.new(:CBC)
    decipher.decrypt
    decipher.key = [ENV['AES_ENCRYPTION_KEY']].pack("H*")
    decipher.iv = [ENV['AES_ENCRYPTION_IV']].pack("H*")
    plain = decipher.update([data].pack("H*")) + decipher.final
    return plain
    rescue
      return ''
  end
  
  def self.encryption(data)
    decipher = OpenSSL::Cipher::AES256.new(:CBC)
    decipher.encrypt
    decipher.key = [ENV['AES_ENCRYPTION_KEY']].pack("H*")
    decipher.iv = [ENV['AES_ENCRYPTION_IV']].pack("H*")
    encrypted = decipher.update(data) + decipher.final
    return encrypted
  end
  
  
end
