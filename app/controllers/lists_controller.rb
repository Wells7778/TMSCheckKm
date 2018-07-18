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
    if @list.location.path.split(".").last != "xlsx"
      flash[:alert] = "只允許xlsx檔案格式"
      redirect_to root_path
    else
      xlsx = Roo::Excelx.new(@list.location.path)
      url = "https://maps.googleapis.com/maps/api/directions/json"
      map_config = Rails.application.config_for(:map)
      key = map_config["secret"]
      # 讀入每一行資料
      xlsx.each(number: "報修單號", post_code: "郵遞區號", dest: "目的地地址", driver_km: "公里數") do |hash|
        if hash[:driver_km].to_i > 10 && hash[:number] != "報修單號"
          dest_code = hash[:dest][0..5]
          c_dest = hash[:dest][6..-1].split("(").first.split("/").map! {|x| x.length >= 5 ? x : "" }.join("").split("ZZZ").map! {|x| x.length >= 5 ? x : "" }.join("").split(" ").map! {|x| x.length >= 5 ? x : "" }.join("")
          c_dest = dest_code + c_dest
          origin = Post.find_by(code: hash[:post_code]).name
          json_rep = RestClient.get url, {params: {origin: origin, destination: c_dest , language: 'zh-TW', key: key, avoid: "highways" }}
          respond = JSON.parse(json_rep)
          c_km = 0
          if respond["status"] == "OK"
            c_km = respond["routes"][0]["legs"][0]["distance"]["value"] / 1000
          end
          @list.tmsrecords.create(number: hash[:number], post_code: hash[:post_code], dest: hash[:dest], driver_km: hash[:driver_km], c_km: c_km, diff_km: hash[:driver_km] - c_km, status: respond["status"])
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
