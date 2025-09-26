class Conversation < ApplicationRecord
  validates :user_message, presence: true
  validates :ai_response, presence: true
  validates :session_id, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_session, ->(session_id) { where(session_id: session_id) }
  
  def self.log_conversation(user_message, ai_response, session_id = nil)
    session_id ||= generate_session_id
    
    create!(
      user_message: user_message,
      ai_response: ai_response,
      session_id: session_id,
      timestamp: Time.current
    )
  end
  
  def self.recent_conversations(limit: 50)
    recent.limit(limit)
  end
  
  def self.clear_all_conversations
    delete_all
  end
  
  def self.generate_session_id
    # Generate session ID based on current hour (groups conversations by hour)
    Time.current.strftime('%Y%m%d_%H')
  end
  
  def time_ago
    time_diff = Time.current - timestamp
    
    case time_diff
    when 0..59
      "Just now"
    when 60..3599
      "#{(time_diff / 60).to_i}m ago"
    when 3600..86399
      "#{(time_diff / 3600).to_i}h ago"
    else
      "#{(time_diff / 86400).to_i}d ago"
    end
  end
  
  def formatted_timestamp
    timestamp.strftime('%B %d, %Y at %I:%M %p')
  end
end
