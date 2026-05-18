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

ActiveRecord::Schema[8.1].define(version: 2026_05_18_062646) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "red_connect_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["red_connect_id", "created_at"], name: "index_chat_messages_on_red_connect_id_and_created_at"
    t.index ["red_connect_id"], name: "index_chat_messages_on_red_connect_id"
    t.index ["sender_id"], name: "index_chat_messages_on_sender_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "parent_id"
    t.bigint "post_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id", "parent_id", "created_at"], name: "index_comments_on_post_id_and_parent_id_and_created_at"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "connect_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gen_week", null: false
    t.bigint "requester_id", null: false
    t.boolean "retried", default: false, null: false
    t.integer "status", default: 0, null: false
    t.bigint "target_id", null: false
    t.datetime "updated_at", null: false
    t.index ["requester_id", "gen_week"], name: "index_connect_requests_on_requester_id_and_gen_week"
    t.index ["requester_id"], name: "index_connect_requests_on_requester_id"
    t.index ["status", "created_at"], name: "index_connect_requests_on_status_and_created_at"
    t.index ["target_id", "gen_week"], name: "index_connect_requests_on_target_id_and_gen_week"
    t.index ["target_id"], name: "index_connect_requests_on_target_id"
  end

  create_table "credit_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.integer "kind", null: false
    t.text "memo"
    t.bigint "related_id"
    t.string "related_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["related_type", "related_id"], name: "index_credit_transactions_on_related"
    t.index ["user_id", "created_at"], name: "index_credit_transactions_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_credit_transactions_on_user_id"
  end

  create_table "downvotes", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "from_user_id", null: false
    t.integer "kind", null: false
    t.bigint "red_connect_id", null: false
    t.bigint "to_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id"], name: "index_downvotes_on_from_user_id"
    t.index ["red_connect_id", "from_user_id"], name: "index_downvotes_on_red_connect_id_and_from_user_id", unique: true
    t.index ["red_connect_id"], name: "index_downvotes_on_red_connect_id"
    t.index ["to_user_id", "kind"], name: "index_downvotes_on_to_user_id_and_kind"
    t.index ["to_user_id"], name: "index_downvotes_on_to_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "accepted_by_id"
    t.boolean "boosted", default: false, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "invitee_email"
    t.bigint "inviter_id", null: false
    t.boolean "paid_extra", default: false, null: false
    t.text "recommendation_comment"
    t.integer "status", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_by_id"], name: "index_invitations_on_accepted_by_id"
    t.index ["code"], name: "index_invitations_on_code", unique: true
    t.index ["invitee_email"], name: "index_invitations_on_invitee_email"
    t.index ["inviter_id", "created_at"], name: "index_invitations_on_inviter_id_and_created_at"
    t.index ["inviter_id"], name: "index_invitations_on_inviter_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "likeable_id", null: false
    t.string "likeable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id", "likeable_type", "likeable_id"], name: "index_likes_on_user_and_likeable", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "match_exposures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "target_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "viewer_id", null: false
    t.index ["target_id"], name: "index_match_exposures_on_target_id"
    t.index ["viewer_id", "target_id"], name: "index_match_exposures_on_viewer_id_and_target_id", unique: true
    t.index ["viewer_id"], name: "index_match_exposures_on_viewer_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.integer "count", default: 1, null: false
    t.datetime "created_at", null: false
    t.string "group_key"
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_id_and_created_at"
    t.index ["recipient_id", "group_key"], name: "index_notifications_on_recipient_and_group_key_unread", where: "((read_at IS NULL) AND (group_key IS NOT NULL))"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "post_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "tag_id"], name: "index_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["status", "created_at"], name: "index_posts_on_status_and_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh_key", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "red_connects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "release_reason"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_a_id", null: false
    t.bigint "user_b_id", null: false
    t.index ["user_a_id", "user_b_id"], name: "index_red_connects_on_user_a_id_and_user_b_id", unique: true
    t.index ["user_a_id"], name: "index_red_connects_on_user_a_id"
    t.index ["user_b_id", "status"], name: "index_red_connects_on_user_b_id_and_status"
    t.index ["user_b_id"], name: "index_red_connects_on_user_b_id"
  end

  create_table "reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "reason", null: false
    t.bigint "reportable_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reporter_id", null: false
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id", "status"], name: "index_reports_on_reportable_type_and_reportable_id_and_status"
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["resolved_by_id"], name: "index_reports_on_resolved_by_id"
    t.index ["status", "created_at"], name: "index_reports_on_status_and_created_at"
  end

  create_table "score_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delta", null: false
    t.text "memo"
    t.integer "reason", null: false
    t.bigint "related_id"
    t.string "related_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["related_type", "related_id"], name: "index_score_events_on_related"
    t.index ["user_id", "created_at"], name: "index_score_events_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_score_events_on_user_id"
  end

  create_table "seed_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "email", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_seed_emails_on_created_by_id"
    t.index ["email"], name: "index_seed_emails_on_email", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "avatar_url"
    t.text "bio"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.integer "gender"
    t.string "google_uid"
    t.text "hobby"
    t.datetime "invitation_accepted_at"
    t.bigint "invited_by_id"
    t.string "job_title"
    t.datetime "matching_activated_at"
    t.boolean "matching_enabled", default: false, null: false
    t.string "name"
    t.string "nickname"
    t.jsonb "notification_preferences", default: {}, null: false
    t.integer "residence_area"
    t.boolean "seed", default: false, null: false
    t.integer "smoking"
    t.datetime "suspended_until"
    t.integer "ticket_credits", default: 0, null: false
    t.integer "ticket_score", default: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["nickname"], name: "index_users_on_nickname", unique: true, where: "(nickname IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_messages", "red_connects"
  add_foreign_key "chat_messages", "users", column: "sender_id"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "connect_requests", "users", column: "requester_id"
  add_foreign_key "connect_requests", "users", column: "target_id"
  add_foreign_key "credit_transactions", "users"
  add_foreign_key "downvotes", "red_connects"
  add_foreign_key "downvotes", "users", column: "from_user_id"
  add_foreign_key "downvotes", "users", column: "to_user_id"
  add_foreign_key "invitations", "users", column: "accepted_by_id"
  add_foreign_key "invitations", "users", column: "inviter_id"
  add_foreign_key "likes", "users"
  add_foreign_key "match_exposures", "users", column: "target_id"
  add_foreign_key "match_exposures", "users", column: "viewer_id"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "posts", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "red_connects", "users", column: "user_a_id"
  add_foreign_key "red_connects", "users", column: "user_b_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "resolved_by_id"
  add_foreign_key "score_events", "users"
  add_foreign_key "seed_emails", "users", column: "created_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "users", column: "invited_by_id"
end
