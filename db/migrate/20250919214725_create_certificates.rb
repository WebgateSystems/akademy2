class CreateCertificates < ActiveRecord::Migration[8.0]
  def change
    create_table :certificates, id: :uuid do |t|
      t.references :quiz_result,
                   null: false,
                   type: :uuid,
                   foreign_key: { on_delete: :cascade },
                   index: { unique: true, name: 'index_certificates_on_quiz_result_id' }

      t.uuid     :certificate_number, null: false
      t.string   :pdf,                null: false
      t.datetime :issued_at,          null: false
      t.timestamps
    end

    add_index :certificates, :certificate_number, unique: true
  end
end
