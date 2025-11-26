class Admin::DashboardController < Admin::BaseController
  def index
    @schools_count = School.count
    @headmasters_count = User.joins(:roles).where(roles: { key: 'principal' }).distinct.count
    @teachers_count = User.joins(:roles).where(roles: { key: 'teacher' }).distinct.count
    @pupils_count = User.joins(:roles).where(roles: { key: 'student' }).distinct.count

    # Top performing schools (placeholder - można dodać logikę completion rate)
    @top_schools = School.limit(5)
  end
end
