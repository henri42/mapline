class CreateKeyDates < ActiveRecord::Migration[8.0]
  def change
    create_table :key_dates do |t|
      t.references :mapline, null: false, foreign_key: true
      # Année en numérotation astronomique (0 = 1 av. J.-C., -752 = 753 av. J.-C.).
      t.integer :year, null: false
      t.integer :month           # 1..12, nullable — granularité dérivée de la nullabilité
      t.integer :day             # nullable
      # year * 10_000 + (month || 1) * 100 + (day || 1) — tri chronologique, années négatives incluses.
      t.integer :sort_key, null: false
      t.string :label            # libellé libre (« vers 800 ») qui prime sur le rendu auto
      t.string :title            # ex. « Congrès de Vienne »
      t.text :description

      t.timestamps
    end

    add_index :key_dates, [ :mapline_id, :sort_key ], unique: true
  end
end
