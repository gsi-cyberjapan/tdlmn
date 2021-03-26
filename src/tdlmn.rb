#
# 地理院タイルダウンロードツール
#

require './common_function'
require './arg_data'
require './inifile'
require './download_mokuroku_nippo'
require './merge'
require './download_tile'
require 'fileutils'

# タイルのベースURL
$BASE_URL = "https://maps.gsi.go.jp/xyz"

# mokuroku・nippoダウンロード時のタイムアウト(秒)
$TIME_OUT = 300

# タイルダウンロードの並列スレッド数
$N_DOWNLOAD_THREADS = 8

# タイルダウンロードの進捗表示間隔(秒)
$PROGRESS_WAIT = 10

$WORK_FOLDER = File.absolute_path("./work")
$LIST_FOLDER = File.absolute_path("./list")

CommonFunction.init_log()

$logger.info("プログラム開始")
$std_logger.info("プログラム開始")

# 実行時引数の取得
$arg_data = ArgData.new(ARGV)
if !$arg_data.valid?
  $logger.error("実行時引数不正のため終了")
  $std_logger.error("実行時引数不正のため終了")
  return
end

# iniファイル読み込み
$iniFile = IniFile.new("program.ini")
if !$iniFile.valid?
  $logger.error("iniファイル不正のため終了")
  $std_logger.error("iniファイルのため終了")
  return
end

FileUtils.mkdir_p($WORK_FOLDER)
FileUtils.mkdir_p($LIST_FOLDER)

# mokuroku、nippoのダウンロード
DownloadMokurokuNippo.execute()

# mokuroku、nippoの合成
Merge.execute()

# タイルのダウンロード
DownloadTile.execute()

# フォルダクリア
if $arg_data.option_clear
  CommonFunction.clear_folder($WORK_FOLDER)
  CommonFunction.clear_folder($LIST_FOLDER)
end

$logger.info("プログラム終了")
$std_logger.info("プログラム終了")
