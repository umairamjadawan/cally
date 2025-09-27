class CreateCharacters < ActiveRecord::Migration[7.1]
  def change
    create_table :characters do |t|
      t.string :name
      t.text :personality_prompt
      t.text :voice_settings
      t.string :emoji
      t.boolean :active

      t.timestamps
    end
  end
end
