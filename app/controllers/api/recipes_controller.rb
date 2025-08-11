class Api::RecipesController < ApplicationController
  before_action :set_recipe, only: [:show]
  
  def index
    @recipes = Recipe.includes(:tags)
                    .by_industry(params[:industry])
                    .by_purpose(params[:purpose])
                    .by_difficulty(params[:difficulty])
                    .by_access_level(params[:access_level])
                    .page(params[:page])
                    .per(12)
    
    render json: {
      recipes: @recipes.map { |recipe| recipe_summary(recipe) },
      pagination: {
        current_page: @recipes.current_page,
        total_pages: @recipes.total_pages,
        total_count: @recipes.total_count
      }
    }
  end
  
  def show
    render json: {
      recipe: recipe_detail(@recipe)
    }
  end
  
  private
  
  def set_recipe
    @recipe = Recipe.includes(:tags).find(params[:id])
  end
  
  def recipe_summary(recipe)
    {
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      thumbnail_url: recipe.thumbnail_streaming_url,
      industry: recipe.industry,
      purpose: recipe.purpose,
      difficulty_level: recipe.difficulty_level,
      duration: recipe.formatted_duration,
      access_level: recipe.access_level,
      tags: recipe.tags.pluck(:name)
    }
  end
  
  def recipe_detail(recipe)
    {
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      video_url: recipe.video_streaming_url(current_user),
      thumbnail_url: recipe.thumbnail_streaming_url,
      has_hls_video: recipe.has_hls_video?,
      available_qualities: recipe.available_qualities,
      processing_status: recipe.processing_status,
      processing_completed: recipe.processing_completed?,
      industry: recipe.industry,
      purpose: recipe.purpose,
      difficulty_level: recipe.difficulty_level,
      duration_minutes: recipe.duration_minutes,
      duration: recipe.formatted_duration,
      access_level: recipe.access_level,
      preview_seconds: recipe.preview_seconds,
      preview_available: recipe.preview_available?,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      tips: recipe.tips,
      tags: recipe.tags.map { |tag| { id: tag.id, name: tag.name } },
      created_at: recipe.created_at,
      updated_at: recipe.updated_at
    }
  end
end