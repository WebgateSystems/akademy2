module Register
  class WizardController < ApplicationController
    layout 'register'

    before_action :build_flow

    before_action -> { ensure_step_allowed(:verify_phone) }, only: %i[verify_phone verify_phone_submit]
    before_action -> { ensure_step_allowed(:set_pin) }, only: %i[set_pin set_pin_submit]
    before_action -> { ensure_step_allowed(:set_pin_confirm) }, only: %i[set_pin_confirm set_pin_confirm_submit]
    before_action -> { ensure_step_allowed(:confirm_email) }, only: [:confirm_email]

    # === STEP 1: PROFILE ===

    def profile
      # Profile is for general registration (without specific school/class token)
      # If there's a class token, redirect to student registration
      class_token = session[:join_class_token] || params[:class_token]
      if class_token.present?
        redirect_to register_student_path(class_token: class_token)
        return
      end

      # If there's a school token, redirect to teacher registration
      school_token = session[:join_school_token] || params[:school_token]
      if school_token.present?
        redirect_to register_teacher_path(school_token: school_token)
        return
      end

      # Mark as student registration by default (general registration)
      @flow.data['registration_type'] = 'student' if @flow['registration_type'].blank?

      @form = ProfileForm.new(@flow['profile'] || {})
    end

    def profile_submit
      # Use different form for teacher registration
      if @flow['registration_type'] == 'teacher'
        handle_teacher_profile_submit
      else
        handle_student_profile_submit
      end
    end

    # === STEP 2: VERIFY PHONE ===

    def verify_phone
      @form = VerifyPhoneForm.new
      @phone = @flow['phone']['phone']
    end

    def resend_code
      phone = @flow.get(:phone)&.dig('phone')
      ::Register::SendSmsCode.call(phone:, flow: @flow)

      render json: { ok: true }
    end

    def verify_phone_submit
      result = Register::VerifyPhoneSubmit.call(params:, flow: @flow)

      @form  = result.form
      @phone = result.phone

      unless result.success?
        flash.now[:alert] = result.error
        return render :verify_phone, status: :unprocessable_entity
      end

      # For teacher registration, create user and redirect to dashboard
      if @flow['registration_type'] == 'teacher'
        teacher_result = Register::CreateTeacherAfterVerify.call(flow: @flow)
        if teacher_result.success?
          sign_in(teacher_result.user)
          redirect_to dashboard_path,
                      notice: 'Rejestracja zakończona pomyślnie. Oczekuj na akceptację administracji szkoły.'
        else
          flash.now[:alert] = teacher_result.message || 'Wystąpił błąd podczas tworzenia konta'
          render :verify_phone, status: :unprocessable_entity
        end
      else
        # For student registration, continue to PIN setup
        redirect_to register_set_pin_path
      end
    end

    # === STEP 3: SET PIN ===

    def set_pin
      @form = PinForm.new
    end

    def set_pin_submit
      result = Register::SetPinSubmit.call(params:, flow: @flow)
      @form = result.form

      return redirect_to register_set_pin_confirm_path if result.success?

      render :set_pin, status: :unprocessable_entity
    end

    # === STEP 4: CONFIRM PIN ===

    def set_pin_confirm
      @form = PinForm.new
    end

    def set_pin_confirm_submit
      result = Register::SetPinConfirmSubmit.call(params:, flow: @flow)
      @form  = result.form

      result.success? ? handle_success : handle_failure(result)
    end

    # === STEP 5: CONFIRM EMAIL SCREEN ===

    def confirm_email
      user_id = @flow['user']&.dig('user_id')
      @user = User.find_by(id: user_id)
      sign_in(@user) if @user

      @user_email = @user&.email

      # Check if student registered with class token - enrollment is already created
      if student_registered_with_class_token?
        handle_student_registration_complete
        return
      end

      # For teacher registration or general student registration
      @flow.finish!
    end

    # === TEACHER REGISTRATION ===

    def teacher
      # Try to find school by join_token if provided (optional)
      # Note: school_token is for joining a school, not a class
      join_token = params[:school_token] || params[:join_token] || session[:join_school_token]
      @school = School.find_by(join_token: join_token) if join_token.present?

      # Also check session for school_id
      @school = School.find_by(id: session[:join_school_id]) if @school.nil? && session[:join_school_id].present?

      # Store join_token in session if school found
      if @school.present?
        session[:join_school_token] = @school.join_token
        # Initialize flow with school info
        @flow.update(:school, { 'join_token' => @school.join_token })
      end

      # Mark this as teacher registration
      @flow.data['registration_type'] = 'teacher'

      # Initialize form with only teacher-specific fields (exclude birthdate)
      profile_data = @flow['profile'] || {}
      teacher_profile_data = profile_data.slice('first_name', 'last_name', 'email', 'phone', 'password',
                                                'password_confirmation')
      @form = TeacherProfileForm.new(teacher_profile_data)
    end

    # === STUDENT REGISTRATION ===

    def student
      # Check for class join token from session or params (when coming from /join/class/:token)
      class_token = session[:join_class_token] || params[:class_token]
      if class_token.present?
        # rubocop:disable Rails/DynamicFindBy
        school_class = SchoolClass.find_by_join_token(class_token)
        # rubocop:enable Rails/DynamicFindBy
        if school_class
          # Store class and school info in flow
          session[:join_class_token] = class_token
          @flow.update(:school_class, {
                         'join_token' => class_token,
                         'school_class_id' => school_class.id,
                         'school_id' => school_class.school_id
                       })
          @flow.update(:school, {
                         'school_id' => school_class.school_id
                       })

          # Set instance variables for view
          @school_class = school_class
          @school = school_class.school
        end
      end

      # Mark this as student registration (not teacher)
      @flow.data['registration_type'] = 'student'

      # Initialize form with student-specific fields (include birthdate)
      profile_data = @flow['profile'] || {}
      @form = ProfileForm.new(profile_data)
    end

    private

    def build_flow
      @flow = WizardFlow.new(session)
    end

    def handle_teacher_profile_submit
      result = Register::TeacherProfileSubmit.call(params:, flow: @flow)
      @form = result.form
      return redirect_to register_verify_phone_path if result.success?

      render :teacher, status: :unprocessable_entity
    end

    def handle_student_profile_submit
      result = Register::ProfileSubmit.call(params:, flow: @flow)
      @form = result.form

      reload_school_and_class_info

      return redirect_to register_verify_phone_path if result.success?

      render_student_or_profile_view
    end

    def reload_school_and_class_info
      class_data = @flow['school_class']
      return unless class_data.present? && class_data['school_class_id'].present?

      @school_class = SchoolClass.find_by(id: class_data['school_class_id'])
      @school = @school_class&.school
    end

    def render_student_or_profile_view
      if @flow['registration_type'] == 'student' && @school_class.present?
        render :student, status: :unprocessable_entity
      else
        render :profile, status: :unprocessable_entity
      end
    end

    def student_registered_with_class_token?
      class_token = session[:join_class_token] || @flow['school_class']&.dig('join_token')
      class_token.present? && @user&.student?
    end

    def handle_student_registration_complete
      session.delete(:join_class_token) # Clean up session
      @flow.finish!
      # Redirect to dashboard - student will see pending enrollment screen
      redirect_to public_home_path,
                  notice: 'Rejestracja zakończona pomyślnie. Oczekuj na akceptację dołączenia do klasy.'
    end

    def ensure_step_allowed(step)
      # Redirect to appropriate registration path based on registration type
      if @flow['registration_type'] == 'teacher'
        redirect_to register_teacher_path unless @flow.can_access?(step)
      elsif @flow['registration_type'] == 'student' && @flow['school_class'].present?
        redirect_to register_student_path unless @flow.can_access?(step)
      else
        redirect_to register_profile_path unless @flow.can_access?(step)
      end
    end

    def handle_success
      redirect_to register_confirm_email_path
    end

    def handle_failure(result)
      flash[:alert] = result.message

      return redirect_to(result.redirect_path) if result.redirect_path.present?

      flash.now[:alert] = result.message
      render :set_pin_confirm, status: :unprocessable_entity
    end
  end
end
