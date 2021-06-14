# タイルのダウンロード

require 'open-uri'
require 'timeout'
require 'thread'
require 'time'
require 'digest/md5'

module DownloadTile

  # タイルダウンロードキューの深さ
  Q_SIZE = 2000

  #
  #
  def execute()

    if !$arg_data.download_tile
      $logger.info("タイルダウンロードしない")
      return
    end

    $download_queue = SizedQueue.new(Q_SIZE)

    nippo_files = get_nippo_files()
    if nippo_files.length > 1
      $logger.error("listフォルダにnippoファイルが2つ以上あるため、タイルダウンロード中止")
      $std_logger.error("listフォルダにnippoファイルが2つ以上あるため、タイルダウンロード中止")
      return
    end
    nippo_file = nippo_files.length == 1 ? nippo_files[0] : nil

    $iniFile.tile_ids.each{ |tile_id|
      $logger.info("#{tile_id} タイルダウンロード")
      $std_logger.info("#{tile_id} タイルダウンロード")
      
      download_by_tile_id(tile_id, nippo_file)
    }

  end

  #
  # タイルをダウンロードする
  # @param [String] tile_id 処理対象のタイルID
  # @param [String] nippo_file nippoファイル
  #
  def download_by_tile_id(tile_id, nippo_file)

    mokuroku_file = get_mokuroku_file(tile_id)

    if mokuroku_file && nippo_file
      $logger.error("#{tile_id} listフォルダにmokurokuファイルとnippoファイルが混在するため、タイルダウンロード中止")
      $std_logger.error("#{tile_id} listフォルダにmokurokuファイルとnippoファイルが混在するため、タイルダウンロード中止")
      return
    elsif !mokuroku_file && !nippo_file
      $logger.error("#{tile_id} listフォルダにmokurokuファイルもnippoファイルもないため、タイルダウンロード中止")
      $std_logger.error("#{tile_id} listフォルダにmokurokuファイルもnippoファイルもないため、タイルダウンロード中止")
      return
    end

    # ファイルの行数とタイルのダウンロード数(ok, ng, skip)をカウント
    $count = 0
    $status = {:skip => 0, :ok => 0, :ng => 0}

    threads = Array.new($N_DOWNLOAD_THREADS)
    threads.size.times {|i|
      threads[i] = Thread.new(i) do
        while o = $download_queue.pop
    
          $logger.debug{"タイルダウンロード : " + o[:url]}

          buf = nil
          begin
            URI.open(o[:url],
                    {:proxy => $iniFile.proxy,
                    :http_basic_authentication => [$iniFile.proxy_user, $iniFile.proxy_password]}) do |res|
              buf = res.read
            end
          rescue OpenURI::HTTPError => e
            # 404 Not Found
            $logger.info(e)
            $status[:ng] += 1
          rescue
            print $!, " -- retrying...\n"
            sleep rand
            retry
          end

          if buf != nil
            buf_md5 = Digest::MD5.hexdigest(buf)
            if o[:md5] != buf_md5
              $logger.error("MD5エラー : #{o[:url]}")
              $status[:ng] += 1
            else
              [File.dirname(o[:local_path])].each{|it|
                FileUtils.mkdir_p(it) unless File.directory?(it)
              }

              File.open("#{o[:local_path]}", 'wb') {|w| w.print buf}

              File.utime(o[:date], o[:date], o[:local_path])

              $status[:ok] += 1
            end
          end
        end
      end
    }

    # 進捗表示
    watcher = Thread.new do
      while threads.reduce(false) {|any_alive, t| any_alive or t.alive?}
        last_status = $status.clone
        sleep $PROGRESS_WAIT
        $std_logger.info("#{$count}行、OK #{$status[:ok]}, NG #{$status[:ng]}, SKIP #{$status[:skip]}")
      end
    end

    if mokuroku_file
      # mokurokuを元にダウンロード
      $logger.info("#{tile_id} タイルダウンロード開始 : #{mokuroku_file}")
      $std_logger.info("#{tile_id} タイルダウンロード開始 : #{mokuroku_file}")
      download_by_mokuroku(tile_id, mokuroku_file)
      
    elsif nippo_file
      # nippoを元にダウンロード
      $logger.info("#{tile_id} タイルダウンロード開始 : #{nippo_file}")
      $std_logger.info("#{tile_id} タイルダウンロード開始 : #{nippo_file}")
      download_by_nippo(tile_id, nippo_file)
      
    end

    threads.size.times {|i| $download_queue.push(nil)}

    # ダウンロードスレッドの終了待ち
    threads.each {|t| t.join}
    watcher.join
    
    $logger.info("#{tile_id} タイルダウンロード終了 (OK  #{$status[:ok]}, NG #{$status[:ng]}, SKIP #{$status[:skip]})")
    $std_logger.info("#{tile_id} タイルダウンロード終了 (OK  #{$status[:ok]}, NG #{$status[:ng]}, SKIP #{$status[:skip]})")
    
  end

  #
  # listフォルダ配下のmokurokuファイルを取得する
  # @param [String] tile_id 処理対象のタイルID
  # @return [String] mokurokuファイル
  #
  def get_mokuroku_file(tile_id)
    mokuroku_file = "#{$LIST_FOLDER}/#{tile_id}/mokuroku.csv.gz"
    if !File.exist?(mokuroku_file)
      return nil
    end
    
    return mokuroku_file
  end

  #
  # listフォルダ配下のnippoファイルのリストを取得する
  # @return [Array] nippoファイルのリスト
  #
  def get_nippo_files()
    return Dir.glob("#{$LIST_FOLDER}/*-nippo.csv.gz")
  end

  #
  # mokurokuを元にタイルをダウンロード
  # @param [String] tile_id 処理対象のタイルID
  # @param [String] mokuroku_file mokurokuファイル
  #
  def download_by_mokuroku(tile_id, mokuroku_file)
    Zlib::GzipReader.open(mokuroku_file) {|reader|
      reader.each_line {|mokuroku_data|
        $count += 1
        (path, date, size, md5) = mokuroku_data.strip.split(',')

        date = date.to_i
        url = "#{$BASE_URL}/#{tile_id}/#{path}"
        local_path = "#{$iniFile.tile_folder}/#{tile_id}/#{path}"

        # ダウンロード対象のズームレベルでなければスキップ
        zoom = path.split("/")[0]
        unless download_zoom?(local_path, zoom)
          $status[:skip] += 1
          next
        end

        if download_tile?(local_path, md5)
          $download_queue.push({:url => url, :date => date, :md5 => md5, :local_path => local_path})
        end
      }
    }
  end

  #
  # nippoを元にタイルをダウンロード
  # @param [String] tile_id 処理対象のタイルID
  # @param [String] nippo_file nippoファイル
  #
  def download_by_nippo(tile_id, nippo_file)
    Zlib::GzipReader.open(nippo_file) {|reader|
      reader.each_line {|nippo_data|
        $count += 1
        (path, date, size, md5) = nippo_data.strip.split(',')
        (tid, zoom) = path.split("/")

        date = date.to_i
        url = "#{$BASE_URL}/#{path}"
        local_path = "#{$iniFile.tile_folder}/#{path}"
      
        # ダウンロード対象のタイルIDでなければスキップ
        if tid != tile_id
          next
        end

        # ダウンロード対象のズームレベルでなければスキップ
        unless download_zoom?(local_path, zoom)
          next
        end

        if download_tile?(local_path, md5)
          $download_queue.push({:url => url, :date => date, :md5 => md5, :local_path => local_path})
        end
      }
    }
  end

  #
  # ダウンロード対象のズームレベルか調べる
  # @param [String] local_path ローカルタイルのパス
  # @param [int] zoom ズームレベル
  # @return [bool] ダウンロード対象ならtrue、対象外ならfalse
  #
  def download_zoom?(local_path, zoom)
    unless $iniFile.zoom_levels.include?(zoom)
      $logger.debug{"ダウンロード対象外ズームレベル : #{local_path}"}
      $status[:skip] += 1
      return false
    end
    
    return true
  end
  
  #
  # ダウンロード対象のファイルか調べる
  # @param [String] local_path ローカルタイルのパス
  # @param [String] md5 mokuroku、nippoに書かれているMD5値
  # @return [bool] ダウンロード対象ならtrue、対象外ならfalse
  #
  def download_tile?(local_path, md5)
    # /diffモードで既存ファイルとMD5が一致すればダウンロードしない
    if $arg_data.option_difference && File.exist?(local_path)
      local_md5 = Digest::MD5.file(local_path).to_s
      if local_md5 == md5
        $logger.debug{"MD5一致によるスキップ : #{local_path}"}
        $status[:skip] += 1
        return false
      end
    end

    return true
  end

  module_function :execute
  module_function :download_by_tile_id
  module_function :get_nippo_files
  module_function :get_mokuroku_file
  module_function :download_by_mokuroku
  module_function :download_by_nippo
  module_function :download_zoom?
  module_function :download_tile?
  
end

