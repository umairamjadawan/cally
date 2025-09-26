class SettingsController < ApplicationController
  def index
    @family_configs = PromptConfig.family_info.order(:key)
    @behavioral_configs = PromptConfig.behavioral.order(:key)
    @safety_configs = PromptConfig.safety.order(:key)
    @personalization_configs = PromptConfig.personalization.order(:key)
  end
  
  def update
    begin
      config_params.each do |key, value|
        next if key.blank? || value.nil?
        
        # Find the existing config to get its type and description
        existing_config = PromptConfig.find_by(key: key)
        if existing_config
          existing_config.update!(value: value.to_s.strip)
        else
          # For new configs, default to family_info type
          PromptConfig.set_config(
            key, 
            value.to_s.strip, 
            config_type: PromptConfig::FAMILY_INFO,
            description: key.humanize
          )
        end
      end
      
      flash[:notice] = "✅ Cally's settings have been updated successfully!"
      redirect_to settings_path
    rescue => e
      Rails.logger.error "Settings update error: #{e.message}"
      flash[:error] = "❌ Sorry, there was an error updating the settings. Please try again."
      redirect_to settings_path
    end
  end
  
  def reset_to_defaults
    begin
      PromptConfig.delete_all
      PromptConfig.seed_default_configs
      
      flash[:notice] = "🔄 Cally's settings have been reset to defaults!"
      redirect_to settings_path
    rescue => e
      Rails.logger.error "Settings reset error: #{e.message}"
      flash[:error] = "❌ Sorry, there was an error resetting the settings."
      redirect_to settings_path
    end
  end
  
  def test_prompt
    begin
      current_prompt = PromptConfig.build_system_prompt
      render json: { 
        prompt: current_prompt,
        length: current_prompt.length,
        word_count: current_prompt.split.length
      }
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end
  
  private
  
  def config_params
    params.require(:prompt_configs).permit!
  end
end
