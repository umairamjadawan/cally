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

**🎯 Easy Setup (Recommended)**:
```bash
# 1. Setup RVM environment 
./setup_rvm.sh

# 2. Install all dependencies and setup database
./run_with_rvm.sh "bundle install"
./run_with_rvm.sh "rails db:create db:migrate db:seed"

# 3. Setup Ollama (if not already installed)
./bin/setup_ollama

# 4. Start Cally
./run_with_rvm.sh "rails server"
```

**🔧 Manual Setup** (if you prefer step-by-step):

1. **Setup RVM Environment**:
   ```bash
   # In your terminal (not this shell):
   rvm use ruby-3.4.1@cally --create
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Setup database**:
   ```bash
   rails db:create db:migrate db:seed
   ```

4. **Setup Ollama**:
   ```bash
   ./bin/setup_ollama
   ```

5. **Start Cally**:
   ```bash
   rails server
   ```

6. **Meet Cally**:
   ```
   http://localhost:3000
   ```

### ⚠️ Troubleshooting RVM Issues

If you encounter RVM/Ruby version issues:

1. **Use the RVM wrapper script**:
   ```bash
   ./run_with_rvm.sh "your-command-here"
   ```

2. **Check your environment**:
   ```bash
   ruby --version  # Should show 3.4.1
   rvm gemset name # Should show 'cally'
   ```

3. **Reset environment**:
   ```bash
   ./setup_rvm.sh
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

### Environment Management
- **`.ruby-version`**: Specifies Ruby 3.4.1
- **`.ruby-gemset`**: Specifies 'cally' gemset
- **`.rvmrc`**: Auto-switches environment when entering directory
- **`setup_rvm.sh`**: Manual RVM environment setup
- **`run_with_rvm.sh`**: Wrapper script for running commands with correct environment

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
Visit `http://localhost:3000/settings` to customize:
- Family information (names, ages, interests)
- Cally's personality and response style
- Custom safety rules
- Greeting preferences

Or edit `app/services/ollama_service.rb` for advanced modifications.

## 🛠️ Troubleshooting

### RVM Environment Issues
**Problem**: `uninitialized constant Gem::Resolver::APISet::GemParser (NameError)` or wrong Ruby version

**Solutions**:
```bash
# Quick fix - use the wrapper script
./run_with_rvm.sh "rails server"

# Reset environment
./setup_rvm.sh

# Manual fix
rvm use ruby-3.4.1@cally --create
bundle install
```

### Database Issues
**Problem**: "Database not ready" or migration errors

**Solution**:
```bash
./run_with_rvm.sh "rails db:create db:migrate db:seed"
```

### Ollama Issues
**Problem**: "Ollama is not running" errors

**Solution**:
```bash
# Start Ollama
ollama serve

# In another terminal, pull the model
ollama pull phi3:mini
```

### Port Issues
**Problem**: Port 3000 already in use

**Solution**:
```bash
./run_with_rvm.sh "rails server -p 3001"
# Then visit http://localhost:3001
```

## 📁 Project Structure

```
cally/
├── app/
│   ├── controllers/     # Chat, Settings, Application controllers
│   ├── models/          # Conversation, PromptConfig models
│   ├── services/        # OllamaService, ConversationLogger
│   ├── views/           # ERB templates and layouts
│   └── helpers/         # View helpers
├── bin/
│   ├── setup_ollama     # Ollama installation and model setup
│   └── setup_database   # Database initialization
├── config/              # Rails configuration
├── db/
│   ├── migrate/         # Database migrations
│   └── seeds.rb         # Default configurations
├── setup_rvm.sh         # RVM environment setup
├── run_with_rvm.sh      # RVM wrapper for commands
├── start_app.sh         # Complete app startup script
└── .rvmrc              # Auto-switching RVM config
```

---

**Remember**: Cally runs completely offline for privacy and safety. No data is sent to external servers.