class Contract < ActiveRecord::Base
  
  self.table_name= 'fine_print_contracts'
  
  belongs_to :company
  has_many :account_types
  has_many :signatures
  
  has_many :same_name, class_name: 'Contract',
             primary_key: :name, foreign_key: :name
  
  #############################
  #     Instance Methods      #
  #############################
  
  def is_published?
    !version.nil?
  end
  
  def publish
    errors.add(:base, I18n.t('fine_print.contract.errors.already_published')) \
      if is_published?
    return false unless errors.empty?

    self.version = (same_name.published.first.try(:version) || 0) + 1

    save.tap do |success|
      instance_exec(self, &FinePrint.config.contract_published_proc) if success
    end
  end

  def unpublish
    errors.add(:base, I18n.t('fine_print.contract.errors.not_latest')) \
      unless is_latest?
    return false unless errors.empty?

    self.version = nil
    save
  end

  def new_version
    Contract.where(name: name, version: nil).first || \
      dup.tap{|contract| contract.version = nil}
  end
  
  #############################
  #     Class Methods         #
  #############################
  
  
end