class PbSaleorder < ActiveRecord::Base
  self.primary_key = :id
  
  has_many :pb_saleorderitems, foreign_key: "saleorder_id"
  belongs_to :buyer, class_name: "PbMember", foreign_key: "buyer_id"
  belongs_to :seller, class_name: "PbMember", foreign_key: "seller_id"
  
  def self.datatable(params, user)
    @records = user.pb_sell_saleorders.joins(:pb_saleorderitems).where("pb_saleorderitems.id IS NOT NULL AND pb_saleorderitems.product_id IS NOT NULL")
    
    # FILTERS
    filters = {}
    params["filters"].split('&').each do |row|
      filters[row.split("=")[0]] = row.split("=")[1]
    end
    
    @records = @records.order("pb_saleorders.created DESC")
    
    total = @records.count
    @records = @records.limit(params[:length]).offset(params["start"])
    data = []
    
    @records.uniq.each do |item|
      row = [
              "<div class=\"\">#{item.fullname}</div>",
              item.display_products,
              item.display_quantities,
              "<div class=\"text-nowrap text-right\">#{item.display_single_prices}</div>",
              "<div class=\"text-nowrap text-right\">#{item.display_prices}</div>",
              "<div class=\"text-nowrap\">#{item.ordered_time.to_datetime.strftime("%d-%m-%Y, %H:%I %p")}</div>",
              "<div class=\"text-nowrap\">#{item.display_statuses}</div>",
              "<div class=\"text-left text-nowrap\">#{item.show_link}#{item.finish_link}#{item.cancel_link}</div>"
            ]
      data << row      
    end
    
    result = {
              "drawn" => params[:drawn],
              "recordsTotal" => total,
              "recordsFiltered" => total
    }
    result["data"] = data
    
    return {result: result}
  end
  
  def self.buy_orders(params, user)
    @records = user.pb_saleorders.joins(:pb_saleorderitems).where("pb_saleorderitems.id IS NOT NULL")
    
    # FILTERS
    filters = {}
    params["filters"].split('&').each do |row|
      filters[row.split("=")[0]] = row.split("=")[1]
    end
    
    @records = @records.order("pb_saleorders.created DESC")
    
    total = @records.count
    @records = @records.limit(params[:length]).offset(params["start"])
    data = []
    
    @records.uniq.each do |item|
      row = [
              "<div class=\"\">#{item.seller_name}</div>",
              item.display_products,
              item.display_quantities,
              "<div class=\"text-nowrap text-right\">#{item.display_single_prices}</div>",
              "<div class=\"text-nowrap text-right\">#{item.display_prices}</div>",
              "<div class=\"text-nowrap\">#{item.ordered_time.to_datetime.strftime("%d-%m-%Y, %H:%I %p")}</div>",
              "<div class=\"text-nowrap\">#{item.display_statuses}</div>",
              "<div class=\"text-left text-nowrap\">#{item.show_link}</div>"
            ]
      data << row      
    end
    
    result = {
              "drawn" => params[:drawn],
              "recordsTotal" => total,
              "recordsFiltered" => total
    }
    result["data"] = data
    
    return {result: result}
  end
  
  def self.admin_list(params, user)
    @records = self.joins(:pb_saleorderitems, :seller).where("pb_saleorderitems.id IS NOT NULL")
    
    # FILTERS
    filters = {}
    params["filters"].split('&').each do |row|
      filters[row.split("=")[0]] = URI.decode(row.split("=")[1]).gsub("+"," ") if row.split("=")[1].present?
    end
    
    if filters["shop_name"].present?
      seller_ids = PbCompany.joins(:pb_member).where("LOWER(pb_companies.name) LIKE ? OR LOWER(pb_companies.shop_name) LIKE ?", "%#{filters["shop_name"].strip.mb_chars.downcase}%", "%#{filters["shop_name"].strip.mb_chars.downcase}%").map(&:member_id).uniq
      
      @records = @records.where(seller_id: seller_ids)
    end
    
    if filters["buyer"].present?
      q = "%#{filters["buyer"].strip.mb_chars.downcase}%"
      buyer_ids = PbMember.joins(:pb_memberfield).where("LOWER(pb_members.username) LIKE ? OR LOWER(pb_members.email) LIKE ? OR LOWER(pb_memberfields.first_name) LIKE ? OR LOWER(pb_memberfields.last_name) LIKE ?", q, q, q, q).map(&:id).uniq
      buyer_ids << -1
      
      @records = @records.where("pb_saleorders.buyer_id IN (#{buyer_ids.join(",")}) OR LOWER(pb_saleorders.fullname) LIKE ? OR LOWER(pb_saleorders.receiver_fullname) LIKE ? OR LOWER(pb_saleorders.mobile) LIKE ? OR LOWER(pb_saleorders.email) LIKE ? OR LOWER(pb_saleorders.receiver_mobile) LIKE ? OR LOWER(pb_saleorders.receiver_email) LIKE ?", q, q, q, q, q, q)
    end
    
    
    @records = @records.order("pb_saleorders.created DESC")
    
    total = @records.count
    @records = @records.limit(params[:length]).offset(params["start"])
    data = []
    
    @records.uniq.each do |item|
      item.seller.update_total_sales      
      row = [
              "<div class=\"\"><a target=\"_blank\" href=\"#{item.seller.pb_company.url}\">#{item.seller.pb_company.shop_name}</a><br />#{item.seller.display_name}</div>",
              "<div class=\"\">#{item.display_buyer}</div>",
              item.display_products,
              item.display_quantities,
              "<div class=\"text-nowrap text-right\">#{item.display_single_prices}</div>",
              "<div class=\"text-nowrap text-right\">#{item.display_prices}</div>",
              "<div class=\"text-nowrap\">#{item.ordered_time.to_datetime.strftime("%d-%m-%Y<br />%H:%I")}</div>",
              "<div class=\"text-nowrap\">#{item.display_statuses}</div>",
              "<div class=\"text-left text-nowrap\">#{item.show_link(true)}#{item.finish_link(true)}#{item.cancel_link(true)}</div>"
            ]
      data << row      
    end
    
    result = {
              "drawn" => params[:drawn],
              "recordsTotal" => total,
              "recordsFiltered" => total
    }
    result["data"] = data
    
    return {result: result}
  end
  
  def display_buyer
    str = []
    str << "#{fullname}"
    str << "#{mobile}"
    str << "#{email}"   
    str << "username: "+buyer.username if buyer.present?
    str << "email: "+buyer.email if buyer.present?
    str << "user's fullname"+buyer.display_name+")" if buyer.present?
    
    
    return str.join("<br />")
  end
  
  def display_statuses
    if finished == 1
      "<span class=\"text-success\">Hoàn tất</span>"
    elsif finished == -1
      "<span class=\"text-grey\">Đã hủy</span>"
    else
      "<span class=\"text-danger\">Mới đặt hàng</span>"
    end
    
  end
  
  def buyer_name
    return buyer.nil? ? "" : buyer.display_name
  end
  
  def seller_name
    return seller.nil? ? "" : (seller.pb_company.nil? ? "" : seller.pb_company.name)
  end
  
  def display_products
    names = pb_saleorderitems.uniq.map {|p| "<div title=\"#{p.pb_product_name}\" class=\"sale_product_name\"><a target=\"_blank\" href=\"#{p.pb_product_url}\">#{p.pb_product_name}</a><div>"}
    
    return names.join("<br>")
  end
  
  def display_quantities
    quantities = pb_saleorderitems.uniq.map {|p| p.quantity}
    
    return quantities.join("<br>")
  end
  
  def display_single_prices
    prices = pb_saleorderitems.uniq.map {|p| ApplicationController.helpers.format_price(p.price)}
    
    return prices.join("<br>")
  end
  
  def display_prices
    prices = pb_saleorderitems.uniq.map {|p| ApplicationController.helpers.format_price(p.total)}
    prices << ["<hr style=\"margin: 0\">#{ApplicationController.helpers.format_price(self.total)}"] if pb_saleorderitems.uniq.count > 1
    return prices.join("<br>")
  end
  
  def total
    total = 0.0
    pb_saleorderitems.each do |od|
      total += od.total
    end
    
    return total
  end
  
  def ordered_time
    Time.at(self.created).to_datetime
  end
  
  def show_link(title=nil)
    ActionView::Base.send(:include, Rails.application.routes.url_helpers)
    link_helper = ActionController::Base.helpers
    
    title = !title.nil? ? "<i class=\"icon-zoomin3\"></i> Xem".html_safe : "<i class=\"icon-zoomin3\"></i> Xem chi tiết".html_safe
    link_helper.link_to(title, {controller: "pb_saleorders", action: "show", id: self.id})
  end
  
  def finish_link(title=nil)
    return "" if finished == 1 or finished == -1
    
    ActionView::Base.send(:include, Rails.application.routes.url_helpers)
    link_helper = ActionController::Base.helpers
    
    title = !title.nil? ? "<i class=\"icon-checkmark\"></i> Hoàn tất".html_safe : "<i class=\"icon-checkmark\"></i> Xác nhận đã hoàn tất".html_safe
    "<div>"+link_helper.link_to(title, {controller: "pb_saleorders", action: "finish", id: self.id}, class: "ajax_link text-success")+"</div>"
  end
  
  def cancel_link(title=nil)
    return "" if finished == 1 or finished == -1
    
    ActionView::Base.send(:include, Rails.application.routes.url_helpers)
    link_helper = ActionController::Base.helpers
    
    title = !title.nil? ? "<i class=\"icon-close2\"></i> Hủy".html_safe : "<i class=\"icon-close2\"></i> Hủy đơn hàng".html_safe
    "<div>"+link_helper.link_to(title, {controller: "pb_saleorders", action: "cancel", id: self.id}, class: "ajax_link text-grey")+"</div>"
  end
  
end