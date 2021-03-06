class DealsController < ApplicationController
  # load_and_authorize_resource
  before_action :set_deal, only: [:ajax_deal_info, :on, :off, :approve, :delete, :show, :edit, :update, :destroy]

  # GET /deals
  # GET /deals.json
  def index
    authorize! :read, Deal
    
    respond_to do |format|
      format.html
      format.json { render json: Deal.select2_options(params, @current_user) }
    end
  end

  # GET /deals/1
  # GET /deals/1.json
  def show
    authorize! :read, @deal
  end

  # GET /deals/new
  def new
    authorize! :create, Deal
    
    @deal = Deal.new
  end

  # GET /deals/1/edit
  def edit
    authorize! :update, @deal
  end

  # POST /deals
  # POST /deals.json
  def create
    authorize! :create, Deal
    
    @deal = Deal.new(deal_params)
    @deal.pb_member_id = @current_user.id
    respond_to do |format|
      if @deal.save
        @deal.update_top_industry
        format.html { redirect_to deals_path, notice: 'DEAL đã được tạo thành công!' }
        format.json { render :show, status: :created, location: @deal }
      else
        format.html { render :new }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deals/1
  # PATCH/PUT /deals/1.json
  def update
    authorize! :create, @deal
    
    respond_to do |format|
      if @deal.update(deal_params)
        @deal.update_top_industry
        format.html { redirect_to deals_path, notice: 'DEAL đã được sửa thành công!' }
        format.json { render :show, status: :ok, location: @deal }
      else
        format.html { render :edit }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deals/1
  # DELETE /deals/1.json
  def destroy
    authorize! :destroy, @deal
    
    @deal.destroy
    respond_to do |format|
      format.html { redirect_to deals_url, notice: 'Deal was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def datatable
    authorize! :read, Deal
    
    result = Deal.datatable(params, @current_user)
    
    render json: result[:result]
  end
  
  def corp_deals
    authorize! :corp_deals, Deal
    
    respond_to do |format|
      format.html
      format.json { render json: Deal.corp_deals(params, @current_user)[:result] }
    end
  end
  
  def corp_members
    authorize! :corp_members, Deal
    
    respond_to do |format|
      format.html
      format.json { render json: Deal.corp_members(params, @current_user)[:result] }
    end
  end
  
  def corp_customers
    authorize! :corp_customers, Deal

    respond_to do |format|
      format.html
      format.json { render json: Deal.corp_customers(params, @current_user)[:result] }
    end
  end
  
  def corp_non_member_customers
    authorize! :corp_non_member_customers, Deal

    respond_to do |format|
      format.html
      format.json { render json: Deal.corp_non_member_customers(params, @current_user)[:result] }
    end
  end

  def agent_list
    authorize! :agent_list, Deal
    
    respond_to do |format|
      format.html
      format.json {
        result = Deal.agent_list(params, @current_user)    
        render json: result[:result]
      }
    end    
  end
  
  def admin_agent_list
    authorize! :admin_agent_list, Deal
    
    respond_to do |format|
      format.html
      format.json {
        result = Deal.admin_agent_list(params, @current_user)    
        render json: result[:result]
      }
    end    
  end
  
  def admin_deal_list
    authorize! :admin_deal_list, Deal
    
    respond_to do |format|
      format.html
      format.json {
        result = Deal.admin_deal_list(params, @current_user)    
        render json: result[:result]
      }
    end    
  end
  
  def customer_list
    authorize! :customer_list, Deal
    
    respond_to do |format|
      format.html
      format.json {
        result = Deal.customer_list(params, @current_user)    
        render json: result[:result]
      }
    end    
  end

  def delete
    authorize! :destroy, Deal
    
    @message = "DEAL sản phẩm <strong>#{@deal.pb_product.name}</strong> đã được xóa."
    @deal.destroy
    respond_to do |format|      
      format.html { render "/home/ajax_success", layout: nil }
      format.json { head :no_content }
    end
  end
  
  def approve
    authorize! :approve, Deal
    
    @message = "DEAL sản phẩm <strong>#{@deal.pb_product.name}</strong> đã được duyệt."
    @deal.update_attribute(:approved, 1)
    respond_to do |format|      
      format.html { render "/home/ajax_success", layout: nil }
      format.json { head :no_content }
    end
  end
  
  def on
    authorize! :on, Deal
    
    @message = "DEAL sản phẩm <strong>#{@deal.pb_product.name}</strong> đã được bật."
    @deal.update_attribute(:status, 1)
    respond_to do |format|      
      format.html { render "/home/ajax_success", layout: nil }
      format.json { head :no_content }
    end
  end
  
  def off
    authorize! :off, Deal
    
    @message = "DEAL sản phẩm <strong>#{@deal.pb_product.name}</strong> đã được tắt."
    @deal.update_attribute(:status, 0)
    respond_to do |format|      
      format.html { render "/home/ajax_success", layout: nil }
      format.json { head :no_content }
    end
  end

  def show_product_details
    authorize! :show_product_details, Deal
    @product = PbProduct.find(params[:product_id])
    render layout: nil
  end
  
  def agent_page
    authorize! :agent_page, Deal
    
    respond_to do |format|
      format.html
      format.json { render json: PbSaleorderitem.agent_corp_list(params, @current_user)[:result] }
    end
  end
  
  def home
    @industries = PbIndustry.all.where(level: 1).order("display_order")
    
    render layout: nil   
  end

  def ajax_deal_info
    if params[:hash].present?
      mem = PbMember.where(username: params[:hash].split("_share_")[0]).first
      str = []
      str << "Bạn đã được thành viên <strong>#{mem.display_name}</strong> giới thiệu mua sản phẩm với giá ưu đãi: <span class=\"deal_price\">#{ApplicationController.helpers.format_price(@deal.share_amout)} VNĐ</span> (Giá gốc: <span class=\"deal_old_price\">#{ApplicationController.helpers.format_price(@deal.pb_product.price)} VNĐ</span> | <strong>giảm #{@deal.share_percent}%</strong>).<br/>Mua ngay sản phẩm bên dưới để được giá ưu đãi."
      
      render text: str.join("")
    else
      str = ["<h5>Chương trình khuyến mãi đặc biệt dành cho sản phẩm</h5><ul>"]
      str << "<li>Mua ngay sản phẩm với giá chỉ: <span class=\"deal_price\">#{ApplicationController.helpers.format_price(@deal.price)} VNĐ</span> (Giá gốc: <span class=\"deal_old_price\">#{ApplicationController.helpers.format_price(@deal.pb_product.price)} VNĐ</span> | <strong>giảm #{@deal.deal_percent}%</strong>)</li>"
      #str << "<li>Khách hàng được giới thiệu giảm ngay <strong>#{@deal.share_percent}%</strong>, với giá: <span class=\"deal_price\">#{ApplicationController.helpers.format_price(@deal.share_amout)} VNĐ</span></li>"
      
      if @deal.deal_type == 'discount'
        str << "<li>Nếu tham gia chương trình Cộng tác viên, bạn sẽ được nhận <span class=\"icome_price\">#{ApplicationController.helpers.format_price(@deal.agent_amount)} VNĐ</span> (<strong>#{@deal.agent_percent}%</strong>) trên mỗi sản phẩm giới thiệu được mua"
      elsif @deal.deal_type == 'gift'
        str << "<li>Nếu tham gia chương trình Cộng tác viên, bạn giới thiệu được <strong>#{@deal.free_count} người mua</strong> (với giá ưu đãi: <span class=\"deal_price\">#{ApplicationController.helpers.format_price(@deal.share_amout)} VNĐ</span>), bạn sẽ được tặng <strong>1 sản phẩm</strong>"
      end  
      render text: str.join("")
    end
  end
  
  def item_list
    authorize! :item_list, Deal
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deal
      @deal = Deal.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def deal_params
      params.require(:deal).permit(:deal_type, :free_count, :agent_price, :share_price, :pb_product_id, :pb_company_id, :start_at, :end_at, :quantity, :price, :status, :description)
    end

end
