# iniファイルクラス

class IniFile

  #
  # 初期化
  # @param [String] ini_file_path iniファイル名
  #
  def initialize(iniFilePath)
    $logger.info("#{iniFilePath}読み込み")
    $std_logger.info("#{iniFilePath}読み込み")

    # タイルをダウンロードするフォルダ
    @tile_folder = nil

    # ダウンロード対象のタイルID (配列)
    @tile_ids = nil

    # ダウンロードするズームレベル (配列)
    @zoom_levels = nil

    # プロキシサーバ
    @proxy = nil

    # プロキシサーバのユーザ名
    @proxy_user = nil

    # プロキシサーバのパスワード
    @proxy_password = nil
    
    begin
      File.open(iniFilePath) do |file|
        file.each_line{ |l|
          (key, value) = l.strip.split("=")
          if !key
            $logger.warn("不正なiniファイル行 : #{l}")
            next
          end

          key.strip!
          value.strip!

          case key
          when "TILE_FOLDER"
            @tile_folder = value
          when "TILE_ID"
            @tile_ids = value.split(",")
            CommonFunction.trim_datas(@tile_ids)
          when "ZOOM_LEVEL"
            @zoom_levels = value.split(",")
            CommonFunction.trim_datas(@zoom_levels)
          when "PROXY"
            @proxy = value
          when "PROXY_USER"
            @proxy_user = value
          when "PROXY_PASSWORD"
            @proxy_password = value
          else
            $logger.warn("不正なiniファイル行 : #{l}")
          end
        }
      end
    rescue
    end
  end
  
  #
  # iniファイルにエラーがないか調べる
  # @return [bool] true : OK、false : NG
  #
  def valid?
    if !@tile_folder
      $logger.error("TILE_FOLDERがない" )
     return false
    elsif !@tile_ids
      $logger.error("TILE_IDがない" )
     return false
    elsif !@zoom_levels
      $logger.error("ZOOM_LEVELがない" )
     return false
    end

    return true
  end

  def tile_folder
    @tile_folder
  end

  def tile_ids
    @tile_ids
  end

  def zoom_levels
    @zoom_levels
  end

  def proxy
    @proxy
  end

  def proxy_user
    @proxy_user
  end

  def proxy_password
    @proxy_password
  end
  
end

