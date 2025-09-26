class CreatePromptConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :prompt_configs do |t|
      t.string :key, null: false
      t.text :value, null: false
      t.string :config_type, null: false
      t.text :description
      t.boolean :is_active, default: true
      
      t.timestamps
    end
    
    # Add indexes for better performance
    add_index :prompt_configs, :key, unique: true
    add_index :prompt_configs, :config_type
    add_index :prompt_configs, :is_active
  end
end
