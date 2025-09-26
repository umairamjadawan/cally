module ApplicationHelper
  def placeholder_for(key)
    placeholders = {
      'dad_name' => 'e.g., Dad, Daddy, John',
      'mom_name' => 'e.g., Mom, Mommy, Sarah',
      'child_name' => 'e.g., Emma, Alex',
      'child_age' => 'e.g., 5, 7',
      'other_family' => 'e.g., Grandma Rose, Brother Tommy',
      'child_interests' => 'e.g., dinosaurs, princesses, soccer',
      'family_rules' => 'e.g., No sweets before dinner, bedtime at 8pm',
      'special_instructions' => 'e.g., Always remind about homework',
      'greeting_style' => 'e.g., Hello sweetie!, Hey buddy!',
      'favorite_emoji' => 'e.g., 🌟, 🦄, 🚀'
    }
    placeholders[key] || ''
  end
end
