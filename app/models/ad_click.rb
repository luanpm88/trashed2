class AdClick < ActiveRecord::Base
  belongs_to :pb_member
  
  geocoded_by :ip
  reverse_geocoded_by :latitude, :longitude do |obj,results|
    if geo = results.first
      obj.city    = geo.city
      obj.zipcode = geo.postal_code
      obj.country = geo.country_code
    end
  end
  after_validation :geocode
  after_validation :reverse_geocode
  
  def self.datatable(params)
    filters = CGI::parse(params[:filters])
    @records = self.where(ad_id: filters["ad_id"][0])
    
    order = "ad_clicks.created_at DESC"
    if !params["order"].nil?
      case params["order"]["0"]["column"]
      when "2"
        order = "ad_clicks.name"      
      end
      order += " "+params["order"]["0"]["dir"]
    end
    @records = @records.order(order) if !order.nil?
    
    if !filters["daterange"].empty?
      from = filters["daterange"][0].split(" - ")[0].to_date
      to = filters["daterange"][0].split(" - ")[1].to_date
      @records = @records.where("created_at >= ? AND created_at <= ?", from.beginning_of_day, to.end_of_day)
    end
    
    
    total = @records.count
    @records = @records.limit(params[:length]).offset(params["start"])
    data = []
    
    @records.each do |item|
      # location = Geokit::Geocoders::IpGeocoder.geocode(item.ip).all.first
      # location = GeoIp.geolocation("118.69.191.130")
      # city = location.present? ? location[:city]+", "+location[:country_name] : ""
      row = [
              "<div class=\"text-default text-semibold\">#{item.customer}</div>",
              "<div class=\"text-default\">#{item.ip}</div><div class=\"text-muted text-size-small\"><span class=\"status-mark border-blue position-left\"></span>#{item.city.to_s}, #{item.country.to_s}</div>",
              "<div class=\"text-muted text-center\">#{item.created_at.strftime("%d/%m/%Y")}<br />#{item.created_at.strftime("%H:%m %P")}</div>"
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
  
  def customer
    pb_member.nil? ? "Khách viếng thăm" : pb_member.display_name
  end
end