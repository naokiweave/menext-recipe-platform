# テスト用のレシピデータを作成

# タグの作成
tags = [
  'Excel基礎', 'PowerPoint', 'Word', 'データ分析', 'プレゼン',
  '営業資料', '企画書', 'グラフ作成', 'マクロ', 'ピボットテーブル'
].map do |tag_name|
  Tag.find_or_create_by(name: tag_name)
end

# レシピの作成
recipes_data = [
  {
    title: 'Excelでの売上データ分析の基本',
    description: '営業チームの売上データを効率的に分析し、視覚的なグラフで表現する方法を学びます。',
    industry: '営業・販売',
    purpose: 'データ分析',
    difficulty_level: '初級',
    duration_minutes: 15,
    access_level: 'free',
    ingredients: '<ul><li>Excel 2019以降</li><li>売上データ（CSV形式）</li><li>グラフ作成用テンプレート</li></ul>',
    instructions: '<ol><li>データの読み込み</li><li>ピボットテーブルの作成</li><li>グラフの挿入と書式設定</li><li>レポートの完成</li></ol>',
    tips: '<p>データの前処理が重要です。空白セルや不正な値がないか事前にチェックしましょう。</p>',
    video_url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
  },
  {
    title: 'PowerPointで魅力的な企画書を作る',
    description: '上司や顧客に響く企画書の構成とデザインのコツを実践的に解説します。',
    industry: '企画・マーケティング',
    purpose: '資料作成',
    difficulty_level: '中級',
    duration_minutes: 25,
    access_level: 'premium',
    preview_seconds: 60,
    ingredients: '<ul><li>PowerPoint 2019以降</li><li>企画書テンプレート</li><li>画像素材</li></ul>',
    instructions: '<ol><li>構成の設計</li><li>スライドマスターの設定</li><li>コンテンツの作成</li><li>アニメーションの追加</li></ol>',
    tips: '<p>1スライド1メッセージを心がけ、文字は最小限に抑えましょう。</p>',
    video_url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4'
  },
  {
    title: 'Wordで効率的な議事録作成',
    description: '会議の内容を素早く整理し、読みやすい議事録を作成するテクニックを紹介します。',
    industry: '総務・人事',
    purpose: '文書作成',
    difficulty_level: '初級',
    duration_minutes: 12,
    access_level: 'free',
    ingredients: '<ul><li>Word 2019以降</li><li>議事録テンプレート</li><li>会議音声データ（任意）</li></ul>',
    instructions: '<ol><li>テンプレートの準備</li><li>見出しスタイルの設定</li><li>表の挿入と書式設定</li><li>最終チェック</li></ol>',
    tips: '<p>スタイル機能を活用することで、統一感のある文書が作成できます。</p>',
    video_url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
  },
  {
    title: 'Excelマクロで業務自動化入門',
    description: '繰り返し作業をマクロで自動化し、業務効率を大幅に向上させる方法を学びます。',
    industry: 'IT・システム',
    purpose: '業務効率化',
    difficulty_level: '上級',
    duration_minutes: 35,
    access_level: 'premium',
    preview_seconds: 90,
    ingredients: '<ul><li>Excel 2019以降（マクロ有効）</li><li>VBAエディタ</li><li>サンプルデータ</li></ul>',
    instructions: '<ol><li>マクロの記録</li><li>VBAコードの編集</li><li>エラーハンドリング</li><li>実行ボタンの作成</li></ol>',
    tips: '<p>最初は簡単な処理から始めて、徐々に複雑な処理に挑戦しましょう。</p>',
    video_url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4'
  }
]

recipes_data.each_with_index do |recipe_data, index|
  recipe = Recipe.find_or_create_by(title: recipe_data[:title]) do |r|
    r.assign_attributes(recipe_data)
  end
  
  # ランダムにタグを割り当て
  recipe_tags = tags.sample(rand(2..4))
  recipe.tags = recipe_tags
  
  puts "Created recipe: #{recipe.title}"
end

puts "シードデータの作成が完了しました。"
puts "作成されたレシピ数: #{Recipe.count}"
puts "作成されたタグ数: #{Tag.count}"