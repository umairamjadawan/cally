class PromptConfig < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  validates :config_type, presence: true
  validates :description, presence: true
  
  # Configuration types
  FAMILY_INFO = 'family_info'.freeze
  BEHAVIORAL = 'behavioral'.freeze
  SAFETY = 'safety'.freeze
  PERSONALIZATION = 'personalization'.freeze
  
  scope :family_info, -> { where(config_type: FAMILY_INFO) }
  scope :behavioral, -> { where(config_type: BEHAVIORAL) }
  scope :safety, -> { where(config_type: SAFETY) }
  scope :personalization, -> { where(config_type: PERSONALIZATION) }
  
  def self.get_config(key)
    find_by(key: key)&.value
  end
  
  def self.set_config(key, value, config_type: FAMILY_INFO, description: '')
    config = find_or_initialize_by(key: key)
    config.update!(
      value: value,
      config_type: config_type,
      description: description
    )
    config
  end
  
  def self.family_context
    family_configs = family_info.pluck(:key, :value).to_h
    
    context_parts = []
    
    # Family member names
    if family_configs['dad_name'].present?
      context_parts << "The child's dad is named #{family_configs['dad_name']}"
    end
    
    if family_configs['mom_name'].present?
      context_parts << "The child's mom is named #{family_configs['mom_name']}"
    end
    
    if family_configs['child_name'].present?
      context_parts << "You are talking to #{family_configs['child_name']}"
    end
    
    if family_configs['other_family'].present?
      context_parts << "Other family members: #{family_configs['other_family']}"
    end
    
    # Interests and preferences
    if family_configs['child_interests'].present?
      context_parts << "The child likes: #{family_configs['child_interests']}"
    end
    
    if family_configs['child_age'].present?
      context_parts << "The child is #{family_configs['child_age']} years old"
    end
    
    # Family rules
    if family_configs['family_rules'].present?
      context_parts << "Family rules to remember: #{family_configs['family_rules']}"
    end
    
    # Special instructions
    if family_configs['special_instructions'].present?
      context_parts << "Special instructions: #{family_configs['special_instructions']}"
    end
    
    context_parts.join('. ') + '.' if context_parts.any?
  end
  
  def self.behavioral_context
    behavioral_configs = behavioral.pluck(:key, :value).to_h
    
    context_parts = []
    
    if behavioral_configs['response_style'].present?
      context_parts << "Response style: #{behavioral_configs['response_style']}"
    end
    
    if behavioral_configs['encouragement_level'].present?
      context_parts << "Encouragement level: #{behavioral_configs['encouragement_level']}"
    end
    
    if behavioral_configs['explanation_detail'].present?
      context_parts << "Explanation detail: #{behavioral_configs['explanation_detail']}"
    end
    
    context_parts.join('. ') + '.' if context_parts.any?
  end
  
  def self.build_system_prompt
    base_prompt = <<~PROMPT
      You are Cally, a safe and friendly AI assistant for children under 10 years old. 
      Your name is Cally and you should respond when children call you by that name.
      Always explain things simply, clearly, and in a fun way. 
      Never talk about violence, scary things, or adult topics. 
      If you don't know the answer, just say "I don't know, maybe you can ask Mom or Dad."
      Be warm, encouraging, and patient with children. Use simple words they can understand.
    PROMPT
    
    # Add family context if available
    family_ctx = family_context
    if family_ctx.present?
      base_prompt += "\n\nFamily Context: #{family_ctx}"
    end
    
    # Add behavioral context if available
    behavioral_ctx = behavioral_context
    if behavioral_ctx.present?
      base_prompt += "\n\nBehavioral Guidelines: #{behavioral_ctx}"
    end
    
    # Add any safety overrides
    safety_rules = safety.pluck(:value).join('. ')
    if safety_rules.present?
      base_prompt += "\n\nAdditional Safety Rules: #{safety_rules}"
    end
    
    base_prompt
  end
  
  def self.seed_default_configs
    defaults = [
      # Family Information
      { key: 'dad_name', value: '', config_type: FAMILY_INFO, description: 'Father\'s name' },
      { key: 'mom_name', value: '', config_type: FAMILY_INFO, description: 'Mother\'s name' },
      { key: 'child_name', value: '', config_type: FAMILY_INFO, description: 'Child\'s name' },
      { key: 'child_age', value: '', config_type: FAMILY_INFO, description: 'Child\'s age' },
      { key: 'other_family', value: '', config_type: FAMILY_INFO, description: 'Other family members (siblings, grandparents, etc.)' },
      { key: 'child_interests', value: '', config_type: FAMILY_INFO, description: 'Child\'s interests and hobbies' },
      { key: 'family_rules', value: '', config_type: FAMILY_INFO, description: 'Important family rules to remember' },
      { key: 'special_instructions', value: '', config_type: FAMILY_INFO, description: 'Any special instructions for Cally' },
      
      # Behavioral Settings
      { key: 'response_style', value: 'friendly and encouraging', config_type: BEHAVIORAL, description: 'How Cally should respond (friendly, enthusiastic, calm, etc.)' },
      { key: 'encouragement_level', value: 'high', config_type: BEHAVIORAL, description: 'How much encouragement to give (low, medium, high)' },
      { key: 'explanation_detail', value: 'simple', config_type: BEHAVIORAL, description: 'Level of detail in explanations (simple, detailed, very simple)' },
      
      # Safety Overrides
      { key: 'additional_safety_rule_1', value: '', config_type: SAFETY, description: 'Custom safety rule 1' },
      { key: 'additional_safety_rule_2', value: '', config_type: SAFETY, description: 'Custom safety rule 2' },
      
      # Personalization
      { key: 'greeting_style', value: 'Hi there!', config_type: PERSONALIZATION, description: 'How Cally greets the child' },
      { key: 'favorite_emoji', value: '🤖', config_type: PERSONALIZATION, description: 'Cally\'s favorite emoji to use' }
    ]
    
    defaults.each do |config|
      find_or_create_by(key: config[:key]) do |c|
        c.value = config[:value]
        c.config_type = config[:config_type]
        c.description = config[:description]
      end
    end
  end
end
