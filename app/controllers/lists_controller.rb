class ListsController < ApplicationController
  def index
    @lists = List.all.order("created_at DESC").page(params[:page]).per(10)
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
    if @list.location.path.split(".").last != "xlsx"
      flash[:alert] = "只允許xlsx檔案格式"
      redirect_to root_path
    else
      xlsx = Roo::Excelx.new(@list.location.path)
      sheet = xlsx.sheet('服務案件明細表')
      url = "https://maps.googleapis.com/maps/api/directions/json"
      map_config = Rails.application.config_for(:map)
      key = map_config["secret"]
      # 讀入每一行資料
      sheet.each(number: "報修單號", origin_area: "服務區域", dest: "拖吊地點", dest_area: "目的區域", driver_km: "拖吊里程") do |hash|
        if hash[:driver_km].to_i > 10 && hash[:origin_area][0..1] != "國道" && hash[:number] != "報修單號"
          if hash[:dest_area].nil?
            @list.tmsrecords.new(number: hash[:number], post_code: hash[:origin_area], dest: hash[:dest], driver_km: hash[:driver_km], c_km: 0, diff_km: 0, status: "目的區域不可空白")
            @list.save
          elsif hash[:dest].nil?
            @list.tmsrecords.new(number: hash[:number], post_code: hash[:origin_area], dest: hash[:dest], driver_km: hash[:driver_km], c_km: 0, diff_km: 0, status: "拖吊地點不可空白")
            @list.save
          else
            c_dest = hash[:dest].split("(").first.split("/").map! {|x| x.length >= 5 ? x : "" }.join("").split("ZZZ").map! {|x| x.length >= 5 ? x : "" }.join("").split(" ").map! {|x| x.length >= 5 ? x : "" }.join("")
            c_dest = hash[:dest_area] + c_dest
            origin = hash[:origin_area]
            json_rep = RestClient.get url, {params: {origin: origin, destination: c_dest , language: 'zh-TW', key: key, avoid: "highways" }}
            respond = JSON.parse(json_rep)
            c_km = 0
            if respond["status"] == "OK"
              c_km = respond["routes"][0]["legs"][0]["distance"]["value"] / 1000
            end
            @list.tmsrecords.new(number: hash[:number], post_code: hash[:origin_area], dest: hash[:dest], driver_km: hash[:driver_km], c_km: c_km, diff_km: hash[:driver_km] - c_km, status: respond["status"])
            @list.save
          end
        end
      end
      if @list.update(status: "IMPORT")
        flash[:notice] = "已匯入完成"
        redirect_to lists_path
      else
        @lists = List.all.order("created_at DESC")
        flash.now[:alert] = "無法匯入"
        render :index
      end
    end
  end

  private

  def list_params
    params.require(:list).permit(:location)
  end
end
