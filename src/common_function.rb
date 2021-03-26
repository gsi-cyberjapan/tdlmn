# 関数

require 'time'
require 'logger'

module CommonFunction

  #
  # ログの初期化
  #
  def init_log()

    # ログファイル
    # 10MB、5ファイルまで残す
    $logger = Logger.new('./log.txt', 5, 10 * 1024 * 1024)
    $logger.level = Logger::INFO

    # 標準出力
    $std_logger = Logger.new(STDOUT)
    $std_logger.level = Logger::INFO
    $std_logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime}] #{severity} : #{msg}\n"
    end
  end

  #
  # 日付がyyyymmddの形式で正しい日付か調べる
  # @param [String] date_str 日付文字列
  # @return [bool] true : OK、false : NG
  #
  def date_valid?(date_str)
    begin
      y = date_str[0, 4].to_i
      m = date_str[4, 2].to_i
      d = date_str[6, 2].to_i
      return Date.valid_date?(y, m, d)
    rescue
      return false
    end
  end

  #
  # 配列の各要素から先頭末尾の空白を取り除く
  # @param [Array] datas 配列
  #
  def trim_datas(datas)!
    datas.size.times {|i|
      datas[i] = datas[i].strip
    }
  end

  #
  # フォルダ内のファイルを全て削除する
  # @param [String] folder フォルダ名
  #
  def clear_folder(folder)
    Dir.glob("#{folder}/*") do |f|
      if FileTest.directory? f
        FileUtils.rm_rf(f)
      else
        FileUtils.rm(f)
      end
    end
  end

  module_function :init_log
  module_function :date_valid?
  module_function :trim_datas
  module_function :clear_folder
end
