# 🤖 Cally - Safe AI Assistant for Children

A lightweight, offline AI chat application designed specifically for children under 10 years old. Built with Ruby on Rails and powered by Ollama's phi3:mini model.

## ✨ Features

- 🛡️ **Child-Safe**: Built-in content filtering and age-appropriate responses
- 🗣️ **Voice Input**: Kids can speak their questions using voice-to-text
- 🔊 **Voice Output**: Click to hear AI responses read aloud
- 💾 **Offline**: Runs completely offline using local Ollama models
- 📊 **Fast Database**: SQLite database for quick chat history access
- 🎨 **Modern UI**: Beautiful, responsive design for all devices
- 📝 **Conversation Logging**: Parents can review chat history

## 🚀 Quick Start

### Prerequisites

1. **Ruby 3.4.1** (using RVM)
2. **Ollama** installed on your system  
3. **Bundler** gem

### Setup Instructions

1. **Install dependencies**:
   ```bash
   rvm use ruby-3.4.1@cally
   bundle install
   ```

2. **Setup database**:
   ```bash
   ./bin/setup_database
   ```

3. **Setup Ollama and Cally's brain**:
   ```bash
   ./bin/setup_ollama
   ```

4. **Start Cally**:
   ```bash
   bundle exec rails server
   ```

5. **Meet Cally**:
   ```
   http://localhost:3000
   ```

## 🎯 How to Use Cally

1. **Type or Speak**: Kids can either type questions or click 🎤 to speak
2. **Get Answers**: Cally responds with safe, age-appropriate answers
3. **Listen**: Click 🔊 to hear responses read aloud
4. **Review**: Parents can check conversation history at `/chat/history`

## 🛡️ Safety Features

### Built-in Guardrails
- **System Prompt**: Cally knows she's helping kids and acts appropriately
- **Content Filtering**: Blocks inappropriate topics before sending to AI
- **Simple Language**: Cally uses simple, fun explanations
- **Safe Fallback**: When uncertain, Cally suggests asking parents

### Conversation Monitoring
- All conversations stored in SQLite database
- Fast querying and filtering capabilities
- Timestamps and session tracking for parental review
- No external network calls (completely offline)

## 🔧 Technical Details

### Architecture
- **Backend**: Ruby on Rails 7.1
- **AI Model**: Ollama phi3:mini (lightweight, family-friendly)
- **Database**: SQLite3 (fast, local storage)
- **Frontend**: Modern responsive HTML/CSS/JavaScript with Web Speech APIs

### Voice Features
- **Speech-to-Text**: Web Speech Recognition API (Chrome/Edge)
- **Text-to-Speech**: Web Speech Synthesis API (all modern browsers)
- **Manual Control**: Kids choose when to hear responses

### API Endpoints
- `GET /` - Main chat interface
- `POST /chat` - Send message to Cally
- `GET /chat/history` - View conversation history
- `DELETE /chat/clear` - Clear chat history
- `GET /health` - Health check

## 📱 Responsive Design

Cally works beautifully on:
- 📱 **Mobile phones** (iPhone, Android)
- 📟 **Tablets** (iPad, Android tablets)
- 💻 **Laptops and desktops**
- 🖥️ **Large monitors**

## 🚨 Parental Controls

### Viewing Chat History
Visit `http://localhost:3000/chat/history` to see recent conversations with a beautiful, organized interface.

### Clearing History
Use the "Clear All" button on the history page or visit the API endpoint.

### Customizing Cally's Behavior
Edit `app/services/ollama_service.rb` to modify:
- System prompt instructions
- Content filtering rules
- Response sanitization

---

**Remember**: Cally runs completely offline for privacy and safety. No data is sent to external servers.