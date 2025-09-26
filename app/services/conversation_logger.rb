class ConversationLogger
  def self.log(user_message, ai_response, session_id = nil)
    begin
      conversation = Conversation.log_conversation(user_message, ai_response, session_id)
      Rails.logger.info "Conversation logged to database: ID #{conversation.id}, #{user_message[0..50]}..."
      conversation
    rescue => e
      Rails.logger.error "Failed to log conversation to database: #{e.message}"
      # Fallback to file logging if database fails
      fallback_file_log(user_message, ai_response, session_id)
      nil
    end
  end
  
  def self.recent_conversations(limit: 50)
    begin
      conversations = Conversation.recent_conversations(limit)
      conversations.map do |conv|
        {
          timestamp: conv.timestamp.iso8601,
          user_message: conv.user_message,
          ai_response: conv.ai_response,
          session_id: conv.session_id,
          id: conv.id,
          formatted_time: conv.time_ago,
          full_timestamp: conv.formatted_timestamp
        }
      end
    rescue => e
      Rails.logger.error "Failed to fetch conversations from database: #{e.message}"
      # Fallback to empty array if database fails
      []
    end
  end
  
  def self.clear_logs
    begin
      count = Conversation.count
      Conversation.clear_all_conversations
      Rails.logger.info "Cleared #{count} conversations from database"
      true
    rescue => e
      Rails.logger.error "Failed to clear conversations from database: #{e.message}"
      false
    end
  end
  
  def self.conversation_count
    Conversation.count
  rescue
    0
  end
  
  def self.conversations_by_session(session_id)
    Conversation.by_session(session_id).recent
  rescue
    []
  end
  
  private
  
  def self.fallback_file_log(user_message, ai_response, session_id = nil)
    # Fallback to file logging if database is unavailable
    log_file = Rails.root.join('log', 'conversations_fallback.json')
    
    conversation_entry = {
      timestamp: Time.current.iso8601,
      user_message: user_message,
      ai_response: ai_response,
      session_id: session_id || generate_session_id
    }
    
    File.open(log_file, 'a') do |file|
      file.puts(conversation_entry.to_json)
    end
    
    Rails.logger.info "Conversation logged to fallback file: #{user_message[0..50]}..."
  end
  
  def self.generate_session_id
    Time.current.strftime('%Y%m%d_%H')
  end
end
