class ListsController < ApplicationController
  def index
    @lists = List.all.order("created_at DESC")
    @list = List.new
  end

  def create
    @list = List.new(list_params)
    @list.save
    flash[:notice] = "已上傳"
    redirect_to lists_path
  end

  def show
    @list = List.find_by(id: params[:id])
    @records = @list.tmsrecords
    respond_to do |format|
      format.xlsx
    end
  end

  def generate_km
    @list = List.find_by(id: params[:list_id])
    xlsx = Roo::Excelx.new(@list.location.path)
    url = "https://maps.googleapis.com/maps/api/directions/json"
    key = "AIzaSyCjClGlyDKvskSUB_2W6J2EIuMbgezbFeA"
    # 讀入每一行資料
    xlsx.each(number: "報修單號", post_code: "郵遞區號", dest: "目的地地址", driver_km: "公里數") do |hash|
      if hash[:driver_km].to_i > 10 && hash[:number] != "報修單號"
        dest_code = hash[:dest][0..5]
        c_dest = hash[:dest][6..-1].split("(").first.split("/").map! {|x| x.length >= 5 ? x : "" }.join("").split("ZZZ").map! {|x| x.length >= 5 ? x : "" }.join("").split(" ").map! {|x| x.length >= 5 ? x : "" }.join("")
        c_dest = dest_code + c_dest
        puts c_dest
        case hash[:post_code]
        when "116"
          origin = "台北市文山區"
        when "110"
          origin = "台北市信義區"
        when "222"
          origin = "新北市深坑區"
        when "232"
          origin = "新北市坪林區"
        when "108"
          origin = "台北市萬華區"
        when "223"
          origin = "新北市石碇區"
        when "106"
          origin = "台北市大安區"
        when "226"
          origin = "新北市平溪區"
        end
        json_rep = RestClient.get url, {params: {origin: origin, destination: c_dest , language: 'zh-TW', key: key, avoid: "highways" }}
        respond = JSON.parse(json_rep)
        c_km = 0
        if respond["status"] == "OK"
          c_km = respond["routes"][0]["legs"][0]["distance"]["value"] / 1000
        end
        @list.tmsrecords.create(number: hash[:number], post_code: hash[:post_code], dest: hash[:dest], driver_km: hash[:driver_km], c_km: c_km, diff_km: hash[:driver_km] - c_km, status: respond["status"])
      end
    end
    flash[:notice] = "已匯入完成"
    redirect_to lists_path
  end

  private

  def list_params
    params.require(:list).permit(:location)
  end
end
