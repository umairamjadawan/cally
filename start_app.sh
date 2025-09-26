#!/bin/bash

echo "🤖 Starting Cally - Your Friendly AI Helper"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "Gemfile" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Setup RVM environment
echo "🔧 Setting up RVM environment..."
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
    rvm use ruby-3.4.1@cally --create
    if [ $? -ne 0 ]; then
        echo "❌ Failed to set up RVM environment"
        echo "Please run manually: rvm use ruby-3.4.1@cally --create"
        exit 1
    fi
    echo "✅ Using Ruby $(ruby --version) with gemset 'cally'"
else
    echo "⚠️  RVM not found. Make sure you're using the correct Ruby version (3.4.1)"
fi

# Check if Ruby is available
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby is not installed or not in PATH"
    echo "Please install Ruby 3.4.1 first"
    exit 1
fi

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed!"
    echo "Please install Ollama first: curl -fsSL https://ollama.ai/install.sh | sh"
    exit 1
fi

echo "✅ Ruby and Ollama are available"

# Setup Ollama
echo "🔄 Setting up Ollama..."
./bin/setup_ollama

if [ $? -ne 0 ]; then
    echo "❌ Ollama setup failed"
    exit 1
fi

# Create necessary directories
mkdir -p log tmp/pids db

echo "🚀 Starting Rails server..."
echo "📱 App will be available at: http://localhost:3000"
echo "🛑 Press Ctrl+C to stop the server"
echo ""

# Start Rails server
bundle exec rails server
