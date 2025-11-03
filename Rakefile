require_relative 'config/environment'

namespace :db do
  desc "Run database migrations"
  task :migrate do
    ActiveRecord::Migration.verbose = true

    # schema_migrationsテーブルが存在しない場合は作成
    unless ActiveRecord::Base.connection.table_exists?(:schema_migrations)
      ActiveRecord::Base.connection.create_table :schema_migrations, id: false do |t|
        t.string :version, null: false
      end
      ActiveRecord::Base.connection.add_index :schema_migrations, :version, unique: true
    end

    # マイグレーションファイルを取得
    migration_paths = ['db/migrate']
    migrations = ActiveRecord::MigrationContext.new(migration_paths, ActiveRecord::SchemaMigration).migrations

    ActiveRecord::MigrationContext.new(migration_paths, ActiveRecord::SchemaMigration).migrate

    # スキーマダンプを生成
    Rake::Task['db:schema:dump'].invoke

    puts "マイグレーション完了!"
  end

  namespace :schema do
    desc "Create db/schema.rb file"
    task :dump do
      require 'active_record/schema_dumper'

      File.open('db/schema.rb', 'w') do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end

      puts "スキーマファイルを更新しました: db/schema.rb"
    end
  end

  desc "Reset database (drop, create, migrate)"
  task :reset do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
  end

  desc "Drop database"
  task :drop do
    db_path = 'db/development.sqlite3'
    File.delete(db_path) if File.exist?(db_path)
    puts "データベースを削除しました"
  end

  desc "Create database"
  task :create do
    require 'fileutils'
    FileUtils.mkdir_p('db')
    puts "データベースを作成しました"
  end

  desc "Seed database"
  task :seed do
    require_relative 'db/seeds'
    puts "シードデータを投入しました"
  end
end
