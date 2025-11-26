class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :verify_authenticity_token
  respond_to :json

  def create
    invite = find_and_validate_invite!
    build_resource(sign_up_params)

    resource.skip_confirmation_notification!
    if resource.save
      create_domain_links(invite)
      invite.mark_used!
      resource.send_confirmation_instructions
      render json: { user_id: resource.id, status: 'pending_approval' }, status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create_domain_links(invite)
    case invite.kind
    when 'teacher'
      create_teacher_role(invite)
    when 'student'
      create_student_enrollment(invite)
    end
  end

  def create_teacher_role(invite)
    UserRole.create!(
      user: resource,
      role: Role.find_by!(key: :teacher),
      school_id: invite.school_id
    )
  end

  def create_student_enrollment(invite)
    StudentClassEnrollment.create!(
      student_id: resource.id,
      school_class_id: invite.school_class_id,
      status: 'pending'
    )
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :locale)
  end

  def find_and_validate_invite!
    token = params[:invite_token] || params[:class_token]
    raise ActiveRecord::RecordNotFound if token.blank?

    InviteTokens::Validator.call!(token) # patrz punkt 3
  end
end
