# coding : utf-8
class SearchController < ApplicationController

  def get_keyword
    keyword = params[:keyword]
    users = []
    hash_tags = []
    ask_deals = []
    brand = false
    is_empty_result = false
    unless keyword.blank?
      hash_tags = HashTag.where("keyword like ?", "%#{keyword}%").select(:keyword).distinct(:keyword)
      ask_deal = true unless AskDeal.where("title like ?", "%#{keyword}%" ).blank?
      brand = true unless AskDeal.where("brand like ?", "%#{keyword}%" ).blank?
      # users = User.where("string_id like ?", "%#{keyword}%")
      asks = Ask.select(:user_id).distinct(:user_id) #AJS추가 - 글 쓴 내용이 없는 경우 검색 미리보기에 잡히지 않음
      users = User.where("string_id like ?", "#{keyword}%").where(:id => asks.map(&:user_id)).select(:string_id).distinct(:string_id) #AJS추가(수정) - 유저의 경우에도 string_id가 keyword가 되도록 로직 변경
    end
    is_empty_result = true if users.blank? && hash_tags.blank? && ask_deals.blank? && brand.blank?
    render :json => {:users => users, :hash_tags => hash_tags, :ask_deal => ask_deal, :brand => brand, :is_empty_result => is_empty_result}
  end

end
