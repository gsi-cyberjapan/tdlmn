# mokuroku、nippoのダウンロード

require './common_function'
require 'open-uri'
require 'timeout'
require 'date'

module DownloadMokurokuNippo

  #
  #
  def execute()

    if !$arg_data.download_mokuroku && !$arg_data.download_nippo
      $logger.info("mokuroku、nippoダウンロードしない")
      return
    end

    # workフォルダをクリア
    CommonFunction.clear_folder($WORK_FOLDER)

    # mokurokuをダウンロード
    if $arg_data.download_mokuroku
      $iniFile.tile_ids.each{ |tile_id|
        local_folder = "#{$WORK_FOLDER}/#{tile_id}"
        FileUtils.mkdir_p(local_folder)
        download_file("https://cyberjapandata.gsi.go.jp/xyz/#{tile_id}/mokuroku.csv.gz", "#{local_folder}/mokuroku.csv.gz")
      }
    end
    
    # nippoをダウンロード
    if $arg_data.download_nippo
      (Date.parse($arg_data.download_nippo_from)..Date.parse($arg_data.download_nippo_to)).each do |date|
        date_str = date.strftime("%Y%m%d")
        download_file("https://cyberjapandata.gsi.go.jp/nippo/#{date_str}-nippo.csv.gz", "#{$WORK_FOLDER}/#{date_str}-nippo.csv.gz")
      end
    end
  end


  #
  # ファイルをダウンロードしてローカルに保存する
  # @param url [String] ダウンロードするファイルURL
  # @param local_path [String] 保存ファイル名
  #
  def download_file(url, local_path)
    $logger.info("ダウンロード : #{url} -> #{local_path}")
    $std_logger.info("ダウンロード : #{url} -> #{local_path}")

    begin
      Timeout.timeout($TIME_OUT) {
        URI.open(url,
                  {:proxy => $iniFile.proxy,
                  :http_basic_authentication => [$iniFile.proxy_user, $iniFile.proxy_password]}) do |res|
          IO.copy_stream(res, local_path)
        end
      }
    rescue TimeoutError => e
      $logger.info(e)
    rescue OpenURI::HTTPError => e
      # 404 Not Found
      $logger.info(e)
    rescue => e
      # timeout以外の例外処理
      $logger.error(e)
      retry
    end
  end

  module_function :execute
  module_function :download_file

end
