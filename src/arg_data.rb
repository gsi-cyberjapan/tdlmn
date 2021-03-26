# 実行時引数クラス

require './common_function'

class ArgData

  #
  # 初期化
  # @param [Array] args 実行時引数配列
  #
  def initialize(args)
  
    # mokurokuをダウンロードするか (true / false)
    @download_mokuroku = false
    
    # nippoをダウンロードするか (true / false)
    @download_nippo = false

    # ダウンロードするnippoの期間
    @download_nippo_from = nil
    @download_nippo_to = nil
    
    # タイルをダウンロードするか (true / false)
    @download_tile = false
    
    # mokuroku、nippoを合成するするか (true / false)
    @option_merge = false
    
    # 更新タイルのみダウンロードするするか (true / false)
    @option_difference = false
    
    # 終了時に作業フォルダ、リストフォルダをクリアするするか (true / false)
    @option_clear = false
    
    # 無効なオプションを指定したか
    @invalid_option = false
  
    args.each{ |arg|
      if arg == "-m"
        # mokurokuをダウンロード
        @download_mokuroku = true
        
      elsif arg == "-nt"
        # 今日のnippoをダウンロード
        @download_nippo = true
        @download_nippo_from = Date.today.strftime("%Y%m%d")
        @download_nippo_to = Date.today.strftime("%Y%m%d")
        
      elsif arg.start_with?("-n")
        @download_nippo = true

        if arg.length == 10
          # 指定日のnippoをダウンロード
          @download_nippo_from = arg[2, 8]
          @download_nippo_to = arg[2, 8]
          
        elsif arg.length == 19
          # 指定期間のnippoをダウンロード
          @download_nippo = true
          @download_nippo_from = arg[2, 8]
          @download_nippo_to = arg[11, 8]
          
        else
          $logger.error("-nの期間指定不正 : #{arg}")
        end
        
      elsif arg == "-mn"
        # mokurokuと前月1日～今日のnippoをダウンロード
        @download_mokuroku = true
        @download_nippo = true
        @download_nippo_from = DateTime.now.prev_month.strftime("%Y%m01")
        @download_nippo_to = Date.today.strftime("%Y%m%d")
        
      elsif arg == "-dt"
        @download_tile = true
        
      elsif arg == "-merge"
        @option_merge = true
        
      elsif arg == "-diff"
        @option_difference = true
        
      elsif arg == "-clear"
        @option_clear = true
        
      else
        @invalid_option = true
        $logger.error("不正な実行時引数 : #{arg}")
        $std_logger.error("不正な実行時引数 : #{arg}")
      end
    }
  end
  
  #
  # 実行時引数にエラーがないか調べる
  # @return [bool] true : OK、false : NG
  #
  def valid?
    if @invalid_option
       return false
    end
    
    if @download_nippo
      if !CommonFunction.date_valid?(@download_nippo_from)
       $logger.error("from日付不正 : #{@download_nippo_from}" )
       return false
      elsif !CommonFunction.date_valid?(@download_nippo_to)
       $logger.error("to日付不正 : #{@download_nippo_to}")
       return false
      end
    end

    return true
  end

  def download_mokuroku
    @download_mokuroku
  end

  def download_nippo
    @download_nippo
  end

  def download_nippo_from
    @download_nippo_from
  end

  def download_nippo_to
    @download_nippo_to
  end

  def download_tile
    @download_tile
  end

  def option_merge
    @option_merge
  end

  def option_difference
    @option_difference
  end

  def option_clear
    @option_clear
  end

end
