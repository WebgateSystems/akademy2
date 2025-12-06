# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_05_220000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "academic_years", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ended_at"
    t.boolean "is_current", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.uuid "school_id", null: false
    t.date "started_at"
    t.datetime "updated_at", null: false
    t.string "year", null: false
    t.index ["school_id", "is_current"], name: "index_academic_years_on_school_and_current"
    t.index ["school_id", "year"], name: "index_academic_years_on_school_and_year", unique: true
    t.index ["school_id"], name: "index_academic_years_on_school_id"
  end

  create_table "certificates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "certificate_number", null: false
    t.datetime "created_at", null: false
    t.datetime "issued_at", null: false
    t.string "pdf", null: false
    t.uuid "quiz_result_id", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_number"], name: "index_certificates_on_certificate_number", unique: true
    t.index ["quiz_result_id"], name: "index_certificates_on_quiz_result_id", unique: true
  end

  create_table "content_likes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["content_id"], name: "index_content_likes_on_content_id"
    t.index ["user_id", "content_id"], name: "index_content_likes_on_user_id_and_content_id", unique: true
    t.index ["user_id"], name: "index_content_likes_on_user_id"
  end

  create_table "contents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.integer "duration_sec"
    t.string "file"
    t.string "file_format"
    t.string "file_hash"
    t.uuid "learning_module_id", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "order_index", default: 0, null: false
    t.jsonb "payload", default: {}, null: false
    t.string "poster"
    t.string "subtitles"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "youtube_url"
    t.index ["content_type"], name: "index_contents_on_content_type"
    t.index ["file_hash"], name: "index_contents_on_file_hash"
    t.index ["learning_module_id", "order_index"], name: "index_contents_on_module_and_order"
    t.index ["learning_module_id"], name: "index_contents_on_learning_module_id"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "client"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "event_type", null: false
    t.datetime "occurred_at", null: false
    t.uuid "school_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["occurred_at"], name: "index_events_on_occurred_at"
    t.index ["school_id"], name: "index_events_on_school_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "jwt_refresh_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp", null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["token_digest"], name: "index_jwt_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id", "exp"], name: "index_jwt_tokens_on_user_and_exp"
    t.index ["user_id"], name: "index_jwt_refresh_tokens_on_user_id"
  end

  create_table "learning_modules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "order_index", default: 0, null: false
    t.boolean "published", default: false, null: false
    t.boolean "single_flow", default: false, null: false
    t.string "slug"
    t.string "title", null: false
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_learning_modules_on_published"
    t.index ["slug"], name: "index_learning_modules_on_slug", unique: true
    t.index ["unit_id"], name: "index_learning_modules_on_unit_id"
  end

  create_table "notification_reads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "notification_id", null: false
    t.datetime "read_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["notification_id"], name: "index_notification_reads_on_notification_id"
    t.index ["user_id", "notification_id"], name: "index_notification_reads_on_user_id_and_notification_id", unique: true
    t.index ["user_id"], name: "index_notification_reads_on_user_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.uuid "read_by_user_id"
    t.datetime "resolved_at"
    t.uuid "school_id"
    t.string "target_role", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["read_by_user_id"], name: "index_notifications_on_read_by_user_id"
    t.index ["resolved_at"], name: "index_notifications_on_resolved_at"
    t.index ["school_id"], name: "index_notifications_on_school_id"
    t.index ["target_role", "school_id", "read_at"], name: "index_notifications_on_target_role_and_school_id_and_read_at"
    t.index ["target_role"], name: "index_notifications_on_target_role"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "parent_student_links", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "parent_id", null: false
    t.string "relation", null: false
    t.uuid "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "student_id"], name: "index_parent_student_unique", unique: true
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "features", default: {}, null: false
    t.string "key", null: false
    t.jsonb "limits", default: {}, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_plans_on_key", unique: true
  end

  create_table "quiz_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}, null: false
    t.uuid "learning_module_id", null: false
    t.boolean "passed", null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["learning_module_id"], name: "index_quiz_results_on_learning_module_id"
    t.index ["user_id", "learning_module_id"], name: "index_quiz_results_unique_user_module", unique: true
    t.index ["user_id"], name: "index_quiz_results_on_user_id"
  end

  create_table "registration_flows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}
    t.datetime "expires_at", null: false
    t.string "phone_code"
    t.boolean "phone_verified", default: false
    t.string "pin_temp"
    t.string "step", default: "profile", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_registration_flows_on_expires_at"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_roles_on_key", unique: true
  end

  create_table "school_classes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "join_token"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.uuid "qr_token", null: false
    t.uuid "school_id", null: false
    t.datetime "updated_at", null: false
    t.string "year", null: false
    t.index ["join_token"], name: "index_school_classes_on_join_token", unique: true
    t.index ["qr_token"], name: "index_school_classes_on_qr_token", unique: true
    t.index ["school_id", "name", "year"], name: "index_classes_on_school_name_year", unique: true
    t.index ["school_id"], name: "index_school_classes_on_school_id"
  end

  create_table "schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address"
    t.string "city", default: "Gdynia", null: false
    t.string "country", default: "PL", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "homepage"
    t.string "join_token"
    t.string "logo"
    t.string "name", null: false
    t.string "phone"
    t.string "postcode"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["join_token"], name: "index_schools_on_join_token", unique: true
    t.index ["slug"], name: "index_schools_on_slug", unique: true
  end

  create_table "student_class_enrollments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.uuid "school_class_id", null: false
    t.string "status", default: "pending", null: false
    t.uuid "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["school_class_id"], name: "index_student_class_enrollments_on_school_class_id"
    t.index ["student_id", "school_class_id"], name: "index_student_enrollments_unique", unique: true
  end

  create_table "student_video_likes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "student_video_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["student_video_id", "user_id"], name: "index_student_video_likes_on_student_video_id_and_user_id", unique: true
    t.index ["student_video_id"], name: "index_student_video_likes_on_student_video_id"
    t.index ["user_id"], name: "index_student_video_likes_on_user_id"
  end

  create_table "student_videos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_sec"
    t.string "file", null: false
    t.bigint "file_size_bytes"
    t.integer "likes_count", default: 0, null: false
    t.datetime "moderated_at"
    t.uuid "moderated_by_id"
    t.text "rejection_reason"
    t.uuid "school_id"
    t.string "status", default: "pending", null: false
    t.uuid "subject_id", null: false
    t.string "thumbnail"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "youtube_id"
    t.datetime "youtube_uploaded_at"
    t.string "youtube_url"
    t.index ["created_at"], name: "index_student_videos_on_created_at"
    t.index ["moderated_by_id"], name: "index_student_videos_on_moderated_by_id"
    t.index ["school_id", "status"], name: "index_student_videos_on_school_id_and_status"
    t.index ["school_id"], name: "index_student_videos_on_school_id"
    t.index ["status"], name: "index_student_videos_on_status"
    t.index ["subject_id", "status"], name: "index_student_videos_on_subject_id_and_status"
    t.index ["subject_id"], name: "index_student_videos_on_subject_id"
    t.index ["user_id", "status"], name: "index_student_videos_on_user_id_and_status"
    t.index ["user_id"], name: "index_student_videos_on_user_id"
  end

  create_table "subjects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "color_dark"
    t.string "color_light"
    t.datetime "created_at", null: false
    t.string "icon"
    t.integer "order_index", default: 0, null: false
    t.uuid "school_id"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "slug"], name: "index_subjects_on_school_and_slug", unique: true
    t.index ["school_id"], name: "index_subjects_on_school_id"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expires_on", null: false
    t.string "external_ref"
    t.uuid "plan_id", null: false
    t.uuid "school_id", null: false
    t.date "starts_on", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["school_id", "plan_id", "starts_on"], name: "index_subs_on_school_plan_start"
    t.index ["school_id"], name: "index_subscriptions_on_school_id"
  end

  create_table "teacher_class_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.uuid "school_class_id", null: false
    t.uuid "teacher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["school_class_id"], name: "index_teacher_class_assignments_on_school_class_id"
    t.index ["teacher_id", "school_class_id", "role"], name: "index_teacher_assignments_unique_with_role", unique: true
  end

  create_table "teacher_school_enrollments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.uuid "school_id", null: false
    t.string "status", default: "pending", null: false
    t.uuid "teacher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_teacher_school_enrollments_on_school_id"
    t.index ["teacher_id", "school_id"], name: "index_teacher_enrollments_unique", unique: true
  end

  create_table "units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "order_index", default: 0, null: false
    t.uuid "subject_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_units_on_subject_id"
  end

  create_table "user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "role_id", null: false
    t.uuid "school_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["school_id"], name: "index_user_roles_on_school_id"
    t.index ["user_id", "role_id", "school_id"], name: "index_user_roles_unique_triplet", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "birthdate"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.uuid "jti", default: -> { "gen_random_uuid()" }, null: false
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.string "locale", default: "pl", null: false
    t.datetime "locked_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.uuid "school_id"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["school_id", "last_name", "first_name"], name: "index_users_on_school_and_name"
    t.index ["school_id"], name: "index_users_on_school_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "academic_years", "schools", on_delete: :cascade
  add_foreign_key "certificates", "quiz_results", on_delete: :cascade
  add_foreign_key "content_likes", "contents"
  add_foreign_key "content_likes", "users"
  add_foreign_key "contents", "learning_modules"
  add_foreign_key "events", "schools", on_delete: :cascade
  add_foreign_key "events", "users", on_delete: :cascade
  add_foreign_key "jwt_refresh_tokens", "users"
  add_foreign_key "learning_modules", "units"
  add_foreign_key "notification_reads", "users"
  add_foreign_key "notifications", "schools", on_delete: :cascade
  add_foreign_key "notifications", "users", column: "read_by_user_id", on_delete: :cascade
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "parent_student_links", "users", column: "parent_id"
  add_foreign_key "parent_student_links", "users", column: "student_id"
  add_foreign_key "quiz_results", "learning_modules"
  add_foreign_key "quiz_results", "users"
  add_foreign_key "school_classes", "schools", on_delete: :cascade
  add_foreign_key "student_class_enrollments", "school_classes", on_delete: :cascade
  add_foreign_key "student_class_enrollments", "users", column: "student_id"
  add_foreign_key "student_video_likes", "student_videos"
  add_foreign_key "student_video_likes", "users"
  add_foreign_key "student_videos", "schools"
  add_foreign_key "student_videos", "subjects"
  add_foreign_key "student_videos", "users"
  add_foreign_key "student_videos", "users", column: "moderated_by_id"
  add_foreign_key "subjects", "schools", on_delete: :cascade
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "schools", on_delete: :cascade
  add_foreign_key "teacher_class_assignments", "school_classes", on_delete: :cascade
  add_foreign_key "teacher_class_assignments", "users", column: "teacher_id"
  add_foreign_key "teacher_school_enrollments", "schools", on_delete: :cascade
  add_foreign_key "teacher_school_enrollments", "users", column: "teacher_id"
  add_foreign_key "units", "subjects"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "schools", on_delete: :cascade
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "schools", on_delete: :cascade
end
