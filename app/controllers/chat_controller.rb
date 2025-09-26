class ChatController < ApplicationController
  protect_from_forgery with: :null_session
  
  def index
    # Main chat interface
  end
  
  def send_message
    user_message = params[:message]
    session_id = params[:session_id] || generate_session_id
    
    if user_message.blank?
      render json: { error: 'Message cannot be empty' }, status: 400
      return
    end
    
    begin
      # Get recent conversation context for this session (last 10 messages)
      conversation_context = ConversationLogger.conversations_by_session(session_id)
                                               .limit(10)
                                               .map { |conv| 
                                                 { 
                                                   user_message: conv.user_message, 
                                                   ai_response: conv.ai_response 
                                                 } 
                                               }
      
      # Send message to Ollama with conversation context
      response = OllamaService.new.chat(user_message, conversation_context)
      
      # Log the conversation with session ID
      ConversationLogger.log(user_message, response, session_id)
      
      render json: { 
        response: response,
        timestamp: Time.current.iso8601,
        session_id: session_id
      }
    rescue => e
      Rails.logger.error "Chat error: #{e.message}"
      render json: { 
        error: 'Sorry, I had trouble understanding that. Can you try asking again?',
        timestamp: Time.current.iso8601
      }, status: 500
    end
  end
  
  def history
    # Load conversations directly for template rendering
    begin
      @conversations = Conversation.recent_conversations(limit: 50)
      @total_count = Conversation.count
    rescue => e
      Rails.logger.error "History fetch error: #{e.message}"
      @conversations = []
      @total_count = 0
      @error_message = "Database not ready. Please run: rails db:create && rails db:migrate && rails db:seed"
    end
  end
  
  def clear_history
    begin
      ConversationLogger.clear_logs
      render json: { message: 'Chat history cleared successfully' }
    rescue => e
      Rails.logger.error "Error clearing history: #{e.message}"
      render json: { error: 'Failed to clear history' }, status: 500
    end
  end
  
  private
  
  def generate_session_id
    # Generate session ID based on current hour (groups conversations by hour)
    Time.current.strftime('%Y%m%d_%H')
  end
end
