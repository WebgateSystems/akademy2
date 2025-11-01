class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :verify_authenticity_token
  respond_to :json

  def create
    invite = find_and_validate_invite!
    build_resource(sign_up_params)

    resource.skip_confirmation_notification! # wyślesz po udanej walidacji/utworzeniu
    if resource.save
      # powiązania domenowe wg typu zaproszenia
      case invite.kind
      when "teacher"
        # rola nauczyciela „pending” do akceptacji przez dyrektora
        UserRole.create!(user: resource, role: Role.find_by!(key: :teacher), school_id: invite.school_id)
      when "student"
        # zapis do klasy z „pending” do akceptu nauczyciela
        StudentClassEnrollment.create!(student_id: resource.id, school_class_id: invite.school_class_id, status: "pending")
      end

      invite.mark_used!
      resource.send_confirmation_instructions
      render json: { user_id: resource.id, status: "pending_approval" }, status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :locale)
  end

  def find_and_validate_invite!
    token = params[:invite_token] || params[:class_token]
    raise ActiveRecord::RecordNotFound unless token.present?
    InviteTokens::Validator.call!(token) # patrz punkt 3
  end
end
