#!/bin/bash

echo "🤖 Cally - RVM Environment Wrapper"
echo "=================================="

# Source RVM
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
    echo "✅ RVM loaded"
    
    # Switch to correct Ruby and gemset
    rvm use ruby-3.4.1@cally --create
    
    if [ $? -eq 0 ]; then
        echo "✅ Switched to Ruby $(ruby --version)"
        echo "✅ Using gemset: $(rvm gemset name)"
        echo ""
        
        # Now run the command passed as argument
        if [ $# -eq 0 ]; then
            echo "Usage: $0 <command>"
            echo "Example: $0 'bundle install'"
            echo "Example: $0 'rails server'"
            exit 1
        fi
        
        echo "🚀 Running: $*"
        echo ""
        eval "$*"
    else
        echo "❌ Failed to switch to Ruby 3.4.1@cally"
        echo "Please ensure Ruby 3.4.1 is installed: rvm install ruby-3.4.1"
        exit 1
    fi
else
    echo "❌ RVM not found"
    echo "Please install RVM or run commands manually with correct Ruby version"
    exit 1
fi
