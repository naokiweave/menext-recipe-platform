<template>
  <div class="recipe-detail" v-if="recipe">
    <!-- ヘッダー部分 -->
    <div class="recipe-header">
      <div class="breadcrumb">
        <router-link to="/" class="breadcrumb-link">ホーム</router-link>
        <span class="breadcrumb-separator">></span>
        <span class="breadcrumb-current">{{ recipe.title }}</span>
      </div>
      
      <h1 class="recipe-title">{{ recipe.title }}</h1>
      
      <div class="recipe-meta">
        <span class="meta-item industry">{{ recipe.industry }}</span>
        <span class="meta-item purpose">{{ recipe.purpose }}</span>
        <span class="meta-item difficulty" :class="difficultyClass">
          {{ recipe.difficulty_level }}
        </span>
        <span class="meta-item duration">{{ recipe.duration }}</span>
        <span class="meta-item access" :class="accessClass">
          {{ recipe.access_level === 'free' ? '無料' : 'プレミアム' }}
        </span>
      </div>
    </div>

    <!-- HLS動画プレイヤー部分 -->
    <div class="video-section">
      <HLSVideoPlayer 
        :recipe="recipe"
        @show-upgrade-modal="showUpgradeModal"
        @video-loaded="onVideoLoaded"
        @time-update="onTimeUpdate"
      />
      
      <!-- 動画情報 -->
      <div class="video-info">
        <p class="recipe-description">{{ recipe.description }}</p>
        
        <div class="tags">
          <span v-for="tag in recipe.tags" :key="tag.id" class="tag">
            {{ tag.name }}
          </span>
        </div>
      </div>
    </div>

    <!-- レシピ詳細 -->
    <div class="recipe-content">
      <div class="content-tabs">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          class="tab-button"
          :class="{ active: activeTab === tab.id }"
          @click="activeTab = tab.id"
        >
          {{ tab.label }}
        </button>
      </div>
      
      <div class="tab-content">
        <!-- 材料・素材タブ -->
        <div v-if="activeTab === 'ingredients'" class="ingredients-section">
          <h3>必要な材料・素材</h3>
          <div v-html="recipe.ingredients" class="content-text"></div>
        </div>
        
        <!-- 手順タブ -->
        <div v-if="activeTab === 'instructions'" class="instructions-section">
          <h3>作業手順</h3>
          <div v-html="recipe.instructions" class="content-text"></div>
        </div>
        
        <!-- コツ・ポイントタブ -->
        <div v-if="activeTab === 'tips'" class="tips-section">
          <h3>コツ・ポイント</h3>
          <div v-html="recipe.tips" class="content-text"></div>
        </div>
        
        <!-- AI Q&Aタブ -->
        <div v-if="activeTab === 'qa'" class="qa-section">
          <h3>AI Q&A</h3>
          <div class="qa-input">
            <textarea 
              v-model="qaQuestion" 
              placeholder="このレシピについて質問してください..."
              class="qa-textarea"
            ></textarea>
            <button @click="askAI" class="qa-submit" :disabled="!qaQuestion.trim()">
              質問する
            </button>
          </div>
          
          <div v-if="qaHistory.length > 0" class="qa-history">
            <div v-for="(qa, index) in qaHistory" :key="index" class="qa-item">
              <div class="question">
                <strong>Q:</strong> {{ qa.question }}
              </div>
              <div class="answer">
                <strong>A:</strong> {{ qa.answer }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 関連レシピ -->
    <div class="related-recipes">
      <h3>関連するレシピ</h3>
      <div class="related-grid">
        <div v-for="related in relatedRecipes" :key="related.id" class="related-item">
          <router-link :to="`/recipes/${related.id}`" class="related-link">
            <img :src="related.thumbnail_url" :alt="related.title" class="related-thumbnail">
            <div class="related-info">
              <h4 class="related-title">{{ related.title }}</h4>
              <span class="related-duration">{{ related.duration }}</span>
            </div>
          </router-link>
        </div>
      </div>
    </div>
  </div>
  
  <div v-else class="loading">
    <p>レシピを読み込み中...</p>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import HLSVideoPlayer from './HLSVideoPlayer.vue'

export default {
  name: 'RecipeDetail',
  components: {
    HLSVideoPlayer
  },
  setup() {
    const route = useRoute()
    const recipe = ref(null)
    const activeTab = ref('ingredients')
    const qaQuestion = ref('')
    const qaHistory = ref([])
    const relatedRecipes = ref([])
    
    const tabs = [
      { id: 'ingredients', label: '材料・素材' },
      { id: 'instructions', label: '手順' },
      { id: 'tips', label: 'コツ・ポイント' },
      { id: 'qa', label: 'AI Q&A' }
    ]
    
    const difficultyClass = computed(() => {
      if (!recipe.value) return ''
      return `difficulty-${recipe.value.difficulty_level}`
    })
    
    const accessClass = computed(() => {
      if (!recipe.value) return ''
      return `access-${recipe.value.access_level}`
    })
    
    const fetchRecipe = async () => {
      try {
        const response = await axios.get(`/api/recipes/${route.params.id}`)
        recipe.value = response.data.recipe
        
        // 関連レシピも取得
        fetchRelatedRecipes()
      } catch (error) {
        console.error('レシピの取得に失敗しました:', error)
      }
    }
    
    const fetchRelatedRecipes = async () => {
      try {
        const response = await axios.get('/api/recipes', {
          params: {
            industry: recipe.value.industry,
            limit: 4
          }
        })
        relatedRecipes.value = response.data.recipes.filter(r => r.id !== recipe.value.id)
      } catch (error) {
        console.error('関連レシピの取得に失敗しました:', error)
      }
    }
    
    const onVideoLoaded = () => {
      console.log('動画が読み込まれました')
    }
    
    const onTimeUpdate = (currentTime) => {
      // 動画の再生時間更新処理
      console.log('Current time:', currentTime)
    }
    
    const askAI = async () => {
      if (!qaQuestion.value.trim()) return
      
      try {
        // AI APIへの質問送信
        const response = await axios.post('/api/ai/ask', {
          recipe_id: recipe.value.id,
          question: qaQuestion.value
        })
        
        qaHistory.value.unshift({
          question: qaQuestion.value,
          answer: response.data.answer
        })
        
        qaQuestion.value = ''
      } catch (error) {
        console.error('AI質問の送信に失敗しました:', error)
        // フォールバック回答
        qaHistory.value.unshift({
          question: qaQuestion.value,
          answer: '申し訳ございません。現在AI機能は準備中です。'
        })
        qaQuestion.value = ''
      }
    }
    
    const showUpgradeModal = () => {
      // プレミアムプラン登録モーダルを表示
      alert('プレミアムプラン登録画面を表示します')
    }
    
    onMounted(() => {
      fetchRecipe()
    })
    
    return {
      recipe,
      activeTab,
      tabs,
      qaQuestion,
      qaHistory,
      relatedRecipes,
      difficultyClass,
      accessClass,
      onVideoLoaded,
      onTimeUpdate,
      askAI,
      showUpgradeModal
    }
  }
}
</script><sty
le scoped>
.recipe-detail {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

/* ヘッダー部分 */
.recipe-header {
  margin-bottom: 30px;
}

.breadcrumb {
  margin-bottom: 15px;
  font-size: 14px;
  color: #666;
}

.breadcrumb-link {
  color: #007bff;
  text-decoration: none;
}

.breadcrumb-separator {
  margin: 0 8px;
}

.recipe-title {
  font-size: 28px;
  font-weight: bold;
  margin-bottom: 15px;
  color: #333;
}

.recipe-meta {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.meta-item {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
}

.meta-item.industry {
  background-color: #e3f2fd;
  color: #1976d2;
}

.meta-item.purpose {
  background-color: #f3e5f5;
  color: #7b1fa2;
}

.meta-item.difficulty-初級 {
  background-color: #e8f5e8;
  color: #2e7d32;
}

.meta-item.difficulty-中級 {
  background-color: #fff3e0;
  color: #f57c00;
}

.meta-item.difficulty-上級 {
  background-color: #ffebee;
  color: #d32f2f;
}

.meta-item.duration {
  background-color: #f5f5f5;
  color: #424242;
}

.meta-item.access-free {
  background-color: #e8f5e8;
  color: #2e7d32;
}

.meta-item.access-premium {
  background-color: #fff8e1;
  color: #f57f17;
}

/* 動画セクション */
.video-section {
  margin-bottom: 40px;
}

.video-info {
  text-align: center;
  margin-top: 20px;
}

.recipe-description {
  font-size: 16px;
  line-height: 1.6;
  color: #555;
  margin-bottom: 15px;
}

.tags {
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap;
}

.tag {
  background-color: #f0f0f0;
  color: #666;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
}

/* コンテンツタブ */
.recipe-content {
  margin-bottom: 40px;
}

.content-tabs {
  display: flex;
  border-bottom: 2px solid #e0e0e0;
  margin-bottom: 20px;
}

.tab-button {
  background: none;
  border: none;
  padding: 12px 20px;
  font-size: 16px;
  cursor: pointer;
  border-bottom: 3px solid transparent;
  transition: all 0.3s;
}

.tab-button:hover {
  background-color: #f5f5f5;
}

.tab-button.active {
  border-bottom-color: #007bff;
  color: #007bff;
  font-weight: 600;
}

.tab-content {
  min-height: 200px;
}

.content-text {
  line-height: 1.8;
  color: #333;
}

.content-text h3 {
  margin-bottom: 15px;
  color: #333;
}

/* AI Q&A セクション */
.qa-input {
  margin-bottom: 20px;
}

.qa-textarea {
  width: 100%;
  min-height: 100px;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  resize: vertical;
  margin-bottom: 10px;
}

.qa-submit {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
}

.qa-submit:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.qa-history {
  space-y: 20px;
}

.qa-item {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 15px;
}

.question {
  margin-bottom: 10px;
  color: #333;
}

.answer {
  color: #555;
  background-color: #f8f9fa;
  padding: 10px;
  border-radius: 4px;
}

/* 関連レシピ */
.related-recipes h3 {
  margin-bottom: 20px;
  font-size: 20px;
  color: #333;
}

.related-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
}

.related-item {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.3s, box-shadow 0.3s;
}

.related-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.related-link {
  text-decoration: none;
  color: inherit;
  display: block;
}

.related-thumbnail {
  width: 100%;
  height: 140px;
  object-fit: cover;
}

.related-info {
  padding: 12px;
}

.related-title {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 5px;
  color: #333;
}

.related-duration {
  font-size: 12px;
  color: #666;
}

/* ローディング */
.loading {
  text-align: center;
  padding: 40px;
  color: #666;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .recipe-detail {
    padding: 15px;
  }
  
  .recipe-title {
    font-size: 24px;
  }
  
  .content-tabs {
    overflow-x: auto;
  }
  
  .tab-button {
    white-space: nowrap;
    min-width: 100px;
  }
  
  .related-grid {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 15px;
  }
}
</style>