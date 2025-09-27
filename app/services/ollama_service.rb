require 'faraday'
require 'json'

class OllamaService
  OLLAMA_URL = ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
  MODEL_NAME = 'phi3.5:3.8b-mini-instruct-q4_K_M'
  
  # Base system prompt - will be enhanced with family configuration
  def self.build_system_prompt
    # Try to get customized prompt from database
    begin
      PromptConfig.build_system_prompt
    rescue => e
      Rails.logger.warn "Failed to load custom prompt config: #{e.message}"
      # Fallback to default prompt
      default_system_prompt
    end
  end
  
  def self.default_system_prompt
    <<~PROMPT
      You are Cally, a safe and friendly AI assistant for children under 10 years old. 
      Your name is Cally and you should respond when children call you by that name.
      Always explain things simply, clearly, and in a fun way. 
      Never talk about violence, scary things, or adult topics. 
      If you don't know the answer, just say "I don't know, maybe you can ask Mom or Dad."
      Be warm, encouraging, and patient with children. Use simple words they can understand.
    PROMPT
  end
  
  def initialize
    @client = Faraday.new(url: OLLAMA_URL) do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end
  
  def chat(user_message, conversation_context = [], character_id = nil)
    # Ensure Ollama is running
    unless ollama_running?
      raise "Ollama is not running. Please start Ollama first."
    end
    
    # Ensure model is available
    unless model_available?
      pull_model
    end
    
    # Get character personality if specified
    character = nil
    if character_id.present?
      character = Character.active.find_by(id: character_id)
    end
    
    # Build conversation history with context
    messages = [
      {
        role: 'system',
        content: character&.personality_prompt || self.class.build_system_prompt
      }
    ]
    
    # Add conversation context (previous messages)
    conversation_context.each do |msg|
      messages << { role: 'user', content: msg[:user_message] }
      messages << { role: 'assistant', content: msg[:ai_response] }
    end
    
    # Add current user message
    messages << {
      role: 'user',
      content: sanitize_input(user_message)
    }
    
    # Send chat request with full conversation context
    response = @client.post('/api/chat') do |req|
      req.body = {
        model: MODEL_NAME,
        messages: messages,
        stream: false
      }
    end
    
    if response.success?
      response.body.dig('message', 'content') || 'I had trouble understanding that. Can you try again?'
    else
      raise "Ollama API error: #{response.status} - #{response.body}"
    end
  end
  
  private
  
  def ollama_running?
    response = @client.get('/api/tags')
    response.success?
  rescue
    false
  end
  
  def model_available?
    response = @client.get('/api/tags')
    return false unless response.success?
    
    models = response.body['models'] || []
    models.any? { |model| model['name'].include?(MODEL_NAME) }
  rescue
    false
  end
  
  def pull_model
    Rails.logger.info "Pulling #{MODEL_NAME} model..."
    response = @client.post('/api/pull') do |req|
      req.body = { name: MODEL_NAME }
    end
    
    unless response.success?
      raise "Failed to pull model: #{response.body}"
    end
  end
  
  def sanitize_input(input)
    # Basic input sanitization for child safety
    # Remove any potentially harmful content
    sanitized = input.to_s.strip
    
    # Remove common unsafe patterns (basic filtering)
    unsafe_patterns = [
      /\b(kill|death|die|hurt|pain|blood)\b/i,
      /\b(sex|sexual|porn|nude)\b/i,
      /\b(drugs|alcohol|smoking)\b/i
    ]
    
    unsafe_patterns.each do |pattern|
      if sanitized.match?(pattern)
        return "Can you ask me something else? I like to talk about fun and safe things!"
      end
    end
    
    sanitized
  end
end
