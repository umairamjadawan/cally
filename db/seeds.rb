# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Cally - Database seeding..."

# Seed default prompt configurations
PromptConfig.seed_default_configs

# Seed character personalities
Character.seed_characters

puts "✅ Default configuration settings created!"
puts "📊 #{PromptConfig.count} configuration options available"
puts "🎭 #{Character.count} character personalities available!"
puts ""
puts "🎯 Cally is ready with default family-friendly settings"
puts "👨‍👩‍👧‍👦 Parents can customize Cally at: /settings"