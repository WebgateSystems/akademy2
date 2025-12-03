class TeacherRegistrationController < ApplicationController
  # GET /join/school/:token
  # Redirect to teacher registration with school context
  def join_school
    token = params[:token]
    school = School.find_by(join_token: token)

    unless school
      redirect_to root_path, alert: 'Nieprawidłowy token szkoły'
      return
    end

    # Store school info in session for registration flow
    session[:join_school_token] = token
    session[:join_school_id] = school.id

    # Redirect to teacher registration page with school slug
    redirect_to register_teacher_path(school_slug: school.slug)
  end
end
