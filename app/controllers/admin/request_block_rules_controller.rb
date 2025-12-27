# frozen_string_literal: true

# rubocop:disable I18n/GetText/DecorateString
class Admin::RequestBlockRulesController < Admin::BaseController
  def index
    @query = params[:q].to_s.strip

    rules = RequestBlockRule.order(created_at: :desc)

    if @query.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      rules = rules.where('value ILIKE ? OR rule_type ILIKE ? OR note ILIKE ?', like, like, like)

      user_ids = User.where(
        "email ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q OR (first_name || ' ' || last_name) ILIKE :q",
        q: like
      ).pluck(:id).map(&:to_s)

      rules = rules.or(RequestBlockRule.where(rule_type: 'user', value: user_ids)) if user_ids.any?
    end

    @rules = rules.limit(500)

    user_value_ids = @rules.select { |r| r.rule_type == 'user' }.map(&:value).uniq
    @blocked_users_by_id = User.where(id: user_value_ids).index_by { |u| u.id.to_s }
  end

  def destroy
    rule = RequestBlockRule.find(params[:id])
    unlocked = unlock_user_for_rule(rule)
    rule.destroy!

    respond_to do |format|
      format.html do
        redirect_to admin_request_block_rules_path, notice: destroy_notice(unlocked)
      end
      format.json { render json: { ok: true, unlocked: unlocked } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to admin_request_block_rules_path, alert: 'Nie znaleziono reguły.' }
      format.json { render json: { ok: false, error: 'Not found' }, status: :not_found }
    end
  end

  private

  def unlock_user_for_rule(rule)
    return false unless rule.rule_type == 'user'

    user = User.find_by(id: rule.value)
    return false unless user
    return false unless user.respond_to?(:unlock_access!)
    return false if user.locked_at.blank?

    user.unlock_access!
    true
  end

  def destroy_notice(unlocked)
    return 'Usunięto regułę i odblokowano konto użytkownika.' if unlocked

    'Usunięto regułę.'
  end
end
# rubocop:enable I18n/GetText/DecorateString
