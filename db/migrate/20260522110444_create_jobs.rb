class CreateJobs < ActiveRecord::Migration[7.2]
  def change
    create_table :jobs do |t|
      t.string :job_class, null: false
      t.text :args, null: false, default: "[]"
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.integer :max_attempts, null: false, default: 3
      t.text :last_error

      t.timestamps
    end

    add_index :jobs, :status
  end
end
