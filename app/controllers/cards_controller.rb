class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource
  
  helper_method :cards_sort_column, :cards_sort_direction
  
  def index
    @start_date = params[:start_date] ||= Date.today.to_s
    @end_date = params[:end_date] ||= Date.today.to_s
    @receipt_number = params[:receipt_nbr]
#    @cards = Kaminari.paginate_array(Card.order(sort_column + ' ' + sort_direction)).page(params[:cards_page]).per(20)
    if @receipt_number.blank?
      if @start_date.blank? or @end_date.blank?
        @start_date = Date.today.to_s
        @end_date = Date.today.to_s
      end
      @all_cards = current_user.company.cards.where(last_activity_date: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order(cards_sort_column + ' ' + cards_sort_direction)
#      @all_cards = current_user.company.cards.where(issued_date: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order(cards_sort_column + ' ' + cards_sort_direction)
      @cards = @all_cards.page(params[:cards_page]).per(20)
    else
      @start_date = nil
      @end_date = nil
      @all_cards = current_user.company.cards.where(receipt_nbr: params[:receipt_nbr]).order(cards_sort_column + ' ' + cards_sort_direction)
      @cards = @all_cards.page(params[:cards_page]).per(20)
    end
    respond_to do |format|
      format.html {
        @issued_amount_total = 0
        @available_amount_total = 0
        @issued_priored_paid_in_period_total = 0
        @all_cards.each do |card|
          @issued_amount_total = @issued_amount_total + card.card_amt
          unless card.void?
            @available_amount_total = @available_amount_total + card.avail_amt
          end
          if (card.issued_date < @start_date) and (card.last_activity_date >= @start_date and card.last_activity_date <= @end_date)
            @issued_priored_paid_in_period_total = @issued_priored_paid_in_period_total + card.card_amt
          end
        end
        }
      format.csv { 
        send_data @all_cards.to_csv, filename: "cards-#{@receipt_number}-#{@start_date}-#{@end_date}.csv" 
        }
    end
  end
  
  def show
  end
  
  private
  
    def set_card
      @card = Card.find(params[:id])
    end

    ### Secure the cards sort direction ###
    def cards_sort_direction
      %w[asc desc].include?(params[:cards_direction]) ?  params[:cards_direction] : "desc"
    end

    ### Secure the cards sort column name ###
    def cards_sort_column
      ["card_nbr", "bank_id_nbr", "dev_id", "card_amt", "avail_amt", "card_status", "issued_date", "last_activity_date", "receipt_nbr", "barcodeHash", "card_seq"].include?(params[:cards_column]) ? params[:cards_column] : "last_activity_date"
    end
end
