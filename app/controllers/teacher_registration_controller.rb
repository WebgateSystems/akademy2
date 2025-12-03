class TeacherRegistrationController < ApplicationController
  # GET /join/school/:token
  # Handle both new teacher registration and existing teacher enrollment
  # Token format: xxxx-xxxx-xxxxxxxxxxxx (last 3 segments of UUID)
  def join_school
    token = params[:token]
    school = School.find_by(join_token: token)

    unless school
      redirect_to root_path, alert: 'Nieprawidłowy token szkoły'
      return
    end

    # If user is already signed in as a teacher
    if user_signed_in? && current_user.teacher?
      # Check if already enrolled
      enrollment = current_user.teacher_school_enrollments.find_by(school: school)

      if enrollment&.status == 'approved'
        redirect_to dashboard_path, notice: 'Jesteś już przypisany do tej szkoły'
        return
      end

      # If pending enrollment exists, show dashboard
      if enrollment&.status == 'pending'
        redirect_to dashboard_path, notice: 'Twój wniosek oczekuje na akceptację'
        return
      end

      # If no enrollment, redirect to dashboard where they can join via API
      redirect_to dashboard_path, notice: 'Możesz teraz dołączyć do szkoły'
      return
    end

    # For new users, store school info in session for registration flow
    session[:join_school_token] = token
    session[:join_school_id] = school.id

    # Redirect to teacher registration page with join token
    redirect_to register_teacher_path(join_token: token)
  end
end
