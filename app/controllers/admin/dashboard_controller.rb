class Admin::DashboardController < Admin::BaseController
  def index
    @schools_count = School.count
    @headmasters_count = User.joins(:roles).where(roles: { key: 'principal' }).distinct.count
    @teachers_count = User.joins(:roles).where(roles: { key: 'teacher' }).distinct.count
    @pupils_count = User.joins(:roles).where(roles: { key: 'student' }).distinct.count

    # Activity log statistics
    @logins_count = Event.where(event_type: 'user_login').count
    @videos_viewed_count = Event.where(event_type: 'video_view').count
    @quizzes_completed_count = Event.where(event_type: 'quiz_complete').count

    # Top performing schools (placeholder - można dodać logikę completion rate)
    @top_schools = School.limit(5)
  end
end
