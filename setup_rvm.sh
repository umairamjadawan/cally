#!/bin/bash

echo "🔧 Cally - RVM Environment Setup"
echo "================================="

# Source RVM
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
    echo "✅ RVM loaded successfully"
else
    echo "❌ RVM not found at $HOME/.rvm/scripts/rvm"
    echo "Please install RVM first: https://rvm.io/rvm/install"
    exit 1
fi

# Create and use the correct gemset
echo "🔄 Setting up Ruby 3.4.1 with gemset 'cally'..."
rvm use ruby-3.4.1@cally --create

if [ $? -eq 0 ]; then
    echo "✅ Successfully switched to Ruby $(ruby --version)"
    echo "✅ Using gemset: $(rvm gemset name)"
    echo ""
    echo "🎯 You're now ready to run Cally!"
    echo ""
    echo "Next steps:"
    echo "1. bundle install"
    echo "2. rails db:create && rails db:migrate && rails db:seed"
    echo "3. rails server"
    echo ""
    echo "Or simply run: ./start_app.sh"
else
    echo "❌ Failed to set up RVM environment"
    echo "Please check if Ruby 3.4.1 is installed: rvm list"
    exit 1
fi
