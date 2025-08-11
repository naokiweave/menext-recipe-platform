<template>
  <div class="hls-video-player">
    <div class="video-container" :class="{ 'processing': !recipe.processing_completed }">
      <!-- 動画処理中の表示 -->
      <div v-if="!recipe.processing_completed" class="processing-overlay">
        <div class="processing-message">
          <div class="spinner"></div>
          <h3>動画を処理中です</h3>
          <p>高画質での配信準備を行っています。しばらくお待ちください。</p>
          <div class="processing-status">
            状態: {{ getProcessingStatusText(recipe.processing_status) }}
          </div>
        </div>
      </div>
      
      <!-- HLS動画プレイヤー -->
      <video
        v-else
        ref="videoPlayer"
        class="video-player"
        :poster="recipe.thumbnail_url"
        controls
        preload="metadata"
        @loadedmetadata="onVideoLoaded"
        @timeupdate="onTimeUpdate"
        @error="onVideoError"
      >
        <p>お使いのブラウザは動画再生に対応していません。</p>
      </video>
      
      <!-- 画質選択UI -->
      <div v-if="recipe.available_qualities && recipe.available_qualities.length > 1" 
           class="quality-selector">
        <button class="quality-btn" @click="toggleQualityMenu">
          {{ currentQuality || 'Auto' }}
          <span class="quality-icon">⚙️</span>
        </button>
        
        <div v-if="showQualityMenu" class="quality-menu">
          <button 
            v-for="quality in ['Auto', ...recipe.available_qualities]"
            :key="quality"
            class="quality-option"
            :class="{ active: currentQuality === quality }"
            @click="selectQuality(quality)"
          >
            {{ quality }}
          </button>
        </div>
      </div>
      
      <!-- プレミアム動画のプレビュー制限表示 -->
      <div v-if="showPreviewLimit" class="preview-overlay">
        <div class="preview-message">
          <h3>プレビュー終了</h3>
          <p>続きを視聴するにはプレミアムプランへの登録が必要です</p>
          <button class="upgrade-btn" @click="$emit('show-upgrade-modal')">
            プレミアムプランに登録
          </button>
        </div>
      </div>
    </div>
    
    <!-- 動画情報 -->
    <div class="video-controls" v-if="recipe.processing_completed">
      <div class="playback-info">
        <span class="current-time">{{ formatTime(currentTime) }}</span>
        <span class="separator">/</span>
        <span class="duration">{{ formatTime(duration) }}</span>
        <span v-if="currentQuality" class="quality-indicator">{{ currentQuality }}</span>
      </div>
      
      <div class="video-stats" v-if="showStats">
        <div class="stat-item">
          <span class="stat-label">画質:</span>
          <span class="stat-value">{{ currentQuality || 'Auto' }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">バッファ:</span>
          <span class="stat-value">{{ bufferHealth }}%</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import Hls from 'hls.js'

export default {
  name: 'HLSVideoPlayer',
  props: {
    recipe: {
      type: Object,
      required: true
    }
  },
  emits: ['show-upgrade-modal', 'video-loaded', 'time-update'],
  setup(props, { emit }) {
    const videoPlayer = ref(null)
    const hls = ref(null)
    const currentTime = ref(0)
    const duration = ref(0)
    const currentQuality = ref(null)
    const showQualityMenu = ref(false)
    const showPreviewLimit = ref(false)
    const showStats = ref(false)
    const bufferHealth = ref(100)
    
    const initializeHLS = () => {
      if (!props.recipe.video_url || !props.recipe.processing_completed) return
      
      if (Hls.isSupported()) {
        hls.value = new Hls({
          debug: false,
          enableWorker: true,
          lowLatencyMode: false,
          backBufferLength: 90
        })
        
        hls.value.loadSource(props.recipe.video_url)
        hls.value.attachMedia(videoPlayer.value)
        
        // HLSイベントリスナー
        hls.value.on(Hls.Events.MANIFEST_PARSED, onManifestParsed)
        hls.value.on(Hls.Events.LEVEL_SWITCHED, onLevelSwitched)
        hls.value.on(Hls.Events.ERROR, onHLSError)
        hls.value.on(Hls.Events.BUFFER_APPENDED, updateBufferHealth)
        
      } else if (videoPlayer.value.canPlayType('application/vnd.apple.mpegurl')) {
        // Safari等のネイティブHLS対応ブラウザ
        videoPlayer.value.src = props.recipe.video_url
      } else {
        console.error('HLS is not supported in this browser')
      }
    }
    
    const onManifestParsed = () => {
      console.log('HLS manifest parsed, levels:', hls.value.levels)
      currentQuality.value = 'Auto'
    }
    
    const onLevelSwitched = (event, data) => {
      const level = hls.value.levels[data.level]
      if (level) {
        currentQuality.value = `${level.height}p`
      }
    }
    
    const onHLSError = (event, data) => {
      console.error('HLS Error:', data)
      
      if (data.fatal) {
        switch (data.type) {
          case Hls.ErrorTypes.NETWORK_ERROR:
            console.log('Network error, trying to recover...')
            hls.value.startLoad()
            break
          case Hls.ErrorTypes.MEDIA_ERROR:
            console.log('Media error, trying to recover...')
            hls.value.recoverMediaError()
            break
          default:
            console.log('Fatal error, destroying HLS instance')
            hls.value.destroy()
            break
        }
      }
    }
    
    const selectQuality = (quality) => {
      if (!hls.value) return
      
      if (quality === 'Auto') {
        hls.value.currentLevel = -1 // Auto quality
        currentQuality.value = 'Auto'
      } else {
        const levelIndex = hls.value.levels.findIndex(level => 
          `${level.height}p` === quality
        )
        if (levelIndex !== -1) {
          hls.value.currentLevel = levelIndex
          currentQuality.value = quality
        }
      }
      
      showQualityMenu.value = false
    }
    
    const toggleQualityMenu = () => {
      showQualityMenu.value = !showQualityMenu.value
    }
    
    const onVideoLoaded = () => {
      duration.value = videoPlayer.value.duration
      emit('video-loaded')
    }
    
    const onTimeUpdate = () => {
      currentTime.value = videoPlayer.value.currentTime
      
      // プレミアム動画のプレビュー制限チェック
      if (props.recipe.access_level === 'premium' && 
          props.recipe.preview_seconds && 
          currentTime.value >= props.recipe.preview_seconds) {
        videoPlayer.value.pause()
        showPreviewLimit.value = true
      }
      
      emit('time-update', currentTime.value)
    }
    
    const onVideoError = (event) => {
      console.error('Video error:', event)
    }
    
    const updateBufferHealth = () => {
      if (!videoPlayer.value) return
      
      const buffered = videoPlayer.value.buffered
      if (buffered.length > 0) {
        const bufferEnd = buffered.end(buffered.length - 1)
        const currentTime = videoPlayer.value.currentTime
        const bufferAhead = bufferEnd - currentTime
        bufferHealth.value = Math.min(100, Math.max(0, (bufferAhead / 30) * 100))
      }
    }
    
    const formatTime = (seconds) => {
      if (!seconds || isNaN(seconds)) return '0:00'
      
      const hours = Math.floor(seconds / 3600)
      const minutes = Math.floor((seconds % 3600) / 60)
      const secs = Math.floor(seconds % 60)
      
      if (hours > 0) {
        return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
      } else {
        return `${minutes}:${secs.toString().padStart(2, '0')}`
      }
    }
    
    const getProcessingStatusText = (status) => {
      const statusMap = {
        'pending': '待機中',
        'processing': '処理中',
        'completed': '完了',
        'failed': '失敗'
      }
      return statusMap[status] || status
    }
    
    // ウォッチャー
    watch(() => props.recipe.processing_completed, (completed) => {
      if (completed) {
        setTimeout(initializeHLS, 100)
      }
    })
    
    onMounted(() => {
      if (props.recipe.processing_completed) {
        initializeHLS()
      }
      
      // キーボードショートカット
      document.addEventListener('keydown', (e) => {
        if (e.key === 's' && e.ctrlKey) {
          e.preventDefault()
          showStats.value = !showStats.value
        }
      })
    })
    
    onUnmounted(() => {
      if (hls.value) {
        hls.value.destroy()
      }
    })
    
    return {
      videoPlayer,
      currentTime,
      duration,
      currentQuality,
      showQualityMenu,
      showPreviewLimit,
      showStats,
      bufferHealth,
      selectQuality,
      toggleQualityMenu,
      onVideoLoaded,
      onTimeUpdate,
      onVideoError,
      formatTime,
      getProcessingStatusText
    }
  }
}
</script><sty
le scoped>
.hls-video-player {
  width: 100%;
}

.video-container {
  position: relative;
  width: 100%;
  max-width: 800px;
  margin: 0 auto;
  background-color: #000;
  border-radius: 8px;
  overflow: hidden;
}

.video-container.processing {
  aspect-ratio: 16/9;
  display: flex;
  align-items: center;
  justify-content: center;
}

.video-player {
  width: 100%;
  height: auto;
  display: block;
}

/* 処理中オーバーレイ */
.processing-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  text-align: center;
}

.processing-message h3 {
  margin-bottom: 10px;
  font-size: 24px;
}

.processing-message p {
  margin-bottom: 20px;
  font-size: 16px;
  opacity: 0.9;
}

.processing-status {
  font-size: 14px;
  opacity: 0.8;
  margin-top: 15px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top: 4px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 画質選択UI */
.quality-selector {
  position: absolute;
  top: 10px;
  right: 10px;
}

.quality-btn {
  background: rgba(0, 0, 0, 0.7);
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 5px;
}

.quality-btn:hover {
  background: rgba(0, 0, 0, 0.9);
}

.quality-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: rgba(0, 0, 0, 0.9);
  border-radius: 4px;
  margin-top: 5px;
  min-width: 80px;
  z-index: 10;
}

.quality-option {
  display: block;
  width: 100%;
  background: none;
  border: none;
  color: white;
  padding: 8px 12px;
  text-align: left;
  cursor: pointer;
  font-size: 12px;
}

.quality-option:hover {
  background: rgba(255, 255, 255, 0.1);
}

.quality-option.active {
  background: rgba(255, 255, 255, 0.2);
  font-weight: bold;
}

/* プレビュー制限オーバーレイ */
.preview-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  text-align: center;
}

.preview-message h3 {
  margin-bottom: 10px;
  font-size: 24px;
}

.preview-message p {
  margin-bottom: 20px;
  font-size: 16px;
}

.upgrade-btn {
  background-color: #ff6b35;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.upgrade-btn:hover {
  background-color: #e55a2b;
}

/* 動画コントロール情報 */
.video-controls {
  padding: 10px;
  background: #f8f9fa;
  border-radius: 0 0 8px 8px;
}

.playback-info {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #666;
}

.separator {
  color: #ccc;
}

.quality-indicator {
  background: #007bff;
  color: white;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 11px;
  margin-left: auto;
}

.video-stats {
  margin-top: 10px;
  display: flex;
  gap: 20px;
  font-size: 12px;
  color: #888;
}

.stat-item {
  display: flex;
  gap: 5px;
}

.stat-label {
  font-weight: 500;
}

.stat-value {
  color: #333;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .quality-selector {
    top: 5px;
    right: 5px;
  }
  
  .quality-btn {
    padding: 6px 8px;
    font-size: 11px;
  }
  
  .video-stats {
    flex-direction: column;
    gap: 5px;
  }
}
</style>