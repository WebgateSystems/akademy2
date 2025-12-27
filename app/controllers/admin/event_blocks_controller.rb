# frozen_string_literal: true

# rubocop:disable I18n/GetText/DecorateString
class Admin::EventBlocksController < Admin::BaseController
  def preview
    event = Event.find(params[:id])
    kind = params[:kind].presence || params.dig(:event_block, :kind)
    kind = kind.to_s

    rule = ::Admin::EventBlockRuleBuilder.new(event: event, kind: kind, params: params).call
    return render_invalid_kind if rule.nil?
    return render_error(rule[:error]) if rule[:error].present?

    render json: { ok: true, **rule.slice(:rule_type, :value, :resolution, :ip) }
  rescue ActiveRecord::RecordNotFound
    render json: { ok: false, error: 'Event not found' }, status: :not_found
  end

  def create
    event = Event.find(params[:id])
    rule = build_rule_for_event(event)
    return render_invalid_kind if rule.nil?
    return render_error(rule[:error]) if rule[:error].present?

    create_block_rule!(rule)
    lock_devise_user_if_needed(rule)
    render json: { ok: true, rule_type: rule[:rule_type], value: rule[:value] }
  rescue ActiveRecord::RecordNotUnique
    render json: { ok: true, duplicated: true }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { ok: false, error: 'Event not found' }, status: :not_found
  end

  private

  def build_rule_for_event(event)
    kind = (params[:kind].presence || params.dig(:event_block, :kind)).to_s
    ::Admin::EventBlockRuleBuilder.new(event: event, kind: kind, params: params).call
  end

  def create_block_rule!(rule)
    RequestBlockRule.create!(
      rule_type: rule.fetch(:rule_type),
      value: rule.fetch(:value),
      created_by: current_admin,
      note: rule[:note]
    )
  end

  def lock_devise_user_if_needed(rule)
    return unless rule[:rule_type] == 'user'

    user = User.find_by(id: rule[:value])
    return unless user
    return unless user.respond_to?(:lock_access!)

    user.lock_access! if user.locked_at.blank?
  rescue StandardError
    nil
  end

  def render_invalid_kind
    render json: { ok: false, error: 'Nieprawidłowy typ blokady.' }, status: :unprocessable_entity
  end

  def render_error(message)
    render json: { ok: false, error: message }, status: :unprocessable_entity
  end
end
# rubocop:enable I18n/GetText/DecorateString
