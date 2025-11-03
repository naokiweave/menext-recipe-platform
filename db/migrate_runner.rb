require_relative '../config/environment'

# マイグレーションを実行
ActiveRecord::Migration.verbose = true

# マイグレーションディレクトリのファイルを読み込んで実行
migration_files = Dir.glob(File.join(__dir__, 'migrate', '*.rb')).sort

migration_files.each do |file|
  version = File.basename(file).split('_').first.to_i

  # すでに実行済みかチェック
  if ActiveRecord::SchemaMigration.where(version: version).exists?
    puts "マイグレーション #{version} は既に実行済みです。スキップします。"
    next
  end

  puts "マイグレーション #{File.basename(file)} を実行中..."
  require file

  # クラス名を取得
  migration_class = File.basename(file, '.rb').split('_')[1..-1].map(&:capitalize).join

  begin
    Object.const_get(migration_class).new.change

    # スキーマバージョンを記録
    ActiveRecord::SchemaMigration.create!(version: version)
    puts "マイグレーション #{version} が正常に完了しました。"
  rescue => e
    puts "エラー: #{e.message}"
    puts e.backtrace
  end
end

puts "\n全てのマイグレーションが完了しました。"
