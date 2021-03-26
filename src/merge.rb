# mokuroku、nippoの合成

require './common_function'
require 'date'
require 'zlib'

module Merge

  #
  #
  def execute()

    # listフォルダをクリア
    CommonFunction.clear_folder($LIST_FOLDER)

    if $arg_data.option_merge

      # まずnippoを合成して1ファイルにする
      nippo_files = get_nippo_files()
      nippo_file = merge_nippo(nippo_files)

      # mokurokuと合成
      mokuroku_files = get_mokuroku_files()
      if mokuroku_files.length > 0
        mokuroku_files.each{ |tile_id, mokuroku_file|
          if nippo_file
            # mokuroku + nippo -> mokuroku
            merge_mokuroku_nippo(tile_id, mokuroku_file, nippo_file)

          else
            # mokurokuしかないのでlistフォルダに移動
            to = "#{$LIST_FOLDER}/#{File.basename(mokuroku_file)}"
            FileUtils.mv(mokuroku_file, to)
          end
        }

      elsif nippo_file
        # mokurokuがなければnippoファイルをlistフォルダに移動
        to = "#{$LIST_FOLDER}/#{File.basename(nippo_file)}"
        FileUtils.mv(nippo_file, to)
        
      end

    else
      # workフォルダのファイルをlistフォルダに移動
      Dir.glob("#{$WORK_FOLDER}/*").each do |f|
        to = "#{$LIST_FOLDER}/#{File.basename(f)}"
        FileUtils.mv(f, to)
      end
    end
  end

  #
  # workフォルダ配下のmokurokuファイルのリストを取得する
  # @return [Hash] key : タイルID, value : mokurokuファイル
  #
  def get_mokuroku_files()
    files = Hash.new
    
    $iniFile.tile_ids.each{ |tile_id|
      mokuroku_file = "#{$WORK_FOLDER}/#{tile_id}/mokuroku.csv.gz"
      if File.exist?(mokuroku_file)
        files[tile_id] = mokuroku_file
      end
    }
    
    return files
  end

  #
  # workフォルダ配下のnippoファイルのリストを取得する
  # @return [Array] nippoファイルのリスト
  #
  def get_nippo_files()
    return Dir.glob("#{$WORK_FOLDER}/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-nippo.csv.gz")
  end

  #
  # nippoファイルを合成して1つのnippoファイルにする
  # @param [Array] nippo_files nippoファイルのリスト
  # @return [String] 合成したnippoファイル
  #
  def merge_nippo(nippo_files)
    if nippo_files.length == 0
      # nippoファイルなし
      return nil
    end
    
    if nippo_files.length == 1
      # nippoファイルが1つしかないので合成しない
      return nippo_files[0]
    end

    $logger.info("複数nippoファイルの合成")
    $std_logger.info("複数nippoファイルの合成")

    # nippoが複数ある場合は合成して1ファイルにする
    records = Hash.new()
    nippo_files.sort().each{ |file|
      Zlib::GzipReader.open(file) {|reader|
        reader.each_line {|l|
          path = l.split(",")[0]
          records[path] = l
        }
      }
    }
    
    # 合成結果を出力
    merged_nippo_file = "#{$WORK_FOLDER}/merge-nippo.csv.gz"
    Zlib::GzipWriter.open(merged_nippo_file, Zlib::BEST_COMPRESSION) {|writer|
      records.each_value{ |val|
        writer.puts(val)
      }
    }
    
    return merged_nippo_file
  end

  #
  # mokurokuファイルとnippoファイルを合成してmokurokuファイルにする
  # @param [String] tile_id 処理対象のタイルID
  # @param [String] mokuroku_file mokurokuファイル
  # @param [String] nippo_file nippoファイル
  # @return [String] 合成したmokurokuファイル
  #
  def merge_mokuroku_nippo(tile_id, mokuroku_file, nippo_file)
  
    $logger.info("mokurokuとnippoの合成 : #{mokuroku_file}, [#{nippo_file}]")
    $std_logger.info("mokurokuとnippoの合成 : #{mokuroku_file}, [#{nippo_file}]")

    # nippoファイルを読み込んで、対象のタイルIDの行をハッシュにためる
    nippo_records = Hash.new()
    Zlib::GzipReader.open(nippo_file) {|reader|
      reader.each_line {|nippo_data|
        nippo_path = nippo_data.split(",")[0]
        tid = nippo_path.split("/")[0]
        if tid == tile_id
          mokuroku_path = nippo_path[tid.length + 1, nippo_path.length - tid.length - 1]
          mokuroku_data = nippo_data[tid.length + 1, nippo_data.length - tid.length - 1]
          nippo_records[mokuroku_path] = mokuroku_data
        end
      }
    }

    FileUtils.mkdir_p("#{$LIST_FOLDER}/#{tile_id}")
    merge_mokuroku_file = "#{$LIST_FOLDER}/#{tile_id}/mokuroku.csv.gz"
    Zlib::GzipWriter.open(merge_mokuroku_file, Zlib::BEST_COMPRESSION) {|writer|
      Zlib::GzipReader.open(mokuroku_file) {|reader|
        reader.each_line {|mokuroku_data|

          mokuroku_path = mokuroku_data.split(",")[0]

          # nippoのデータで上書き
          nippo_data = nippo_records[mokuroku_path]
          if nippo_data
            mokuroku_data = nippo_records[mokuroku_path]
          end

          writer.puts(mokuroku_data)
        }
      }
    }
    
    return merge_mokuroku_file
  end

  module_function :execute
  module_function :get_mokuroku_files
  module_function :get_nippo_files
  module_function :merge_nippo
  module_function :merge_mokuroku_nippo

end
