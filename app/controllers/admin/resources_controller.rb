class Admin::ResourcesController < Admin::BaseController
  RESOURCES = {
    'users' => User,
    'teachers' => User,
    'students' => User,
    'roles' => Role,
    'user_roles' => UserRole,
    'schools' => School,
    'school_classes' => SchoolClass,
    'teacher_class_assignments' => TeacherClassAssignment,
    'student_class_enrollments' => StudentClassEnrollment,
    'parent_student_links' => ParentStudentLink,
    'subjects' => Subject,
    'units' => Unit,
    'learning_modules' => LearningModule,
    'contents' => Content,
    'quiz_results' => QuizResult,
    'events' => Event,
    'plans' => Plan,
    'subscriptions' => Subscription,
    'certificates' => Certificate,
    'jwt_refresh_tokens' => JwtRefreshToken
  }.freeze

  before_action :set_resource_class
  before_action :set_record, only: %i[show edit update destroy]

  # rubocop:disable Metrics/MethodLength
  def index
    case params[:resource]
    when 'schools'
      load_schools
    when 'users'
      load_headmasters
    when 'teachers'
      load_teachers
    when 'students'
      load_students
    when 'events'
      load_events
    else
      load_default_records
    end
  end
  # rubocop:enable Metrics/MethodLength

  def show; end

  def new
    @record = @resource_class.new
  end

  def edit; end

  def create
    @record = @resource_class.new(permitted_params)
    prepare_record_for_creation
    assign_principal_role if creating_headmaster?

    if @record.save
      redirect_to admin_resource_collection_path(resource: params[:resource]), notice: 'Utworzono.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    update_params = permitted_params
    prepare_params_for_update(update_params)

    if @record.update(update_params)
      redirect_to admin_resource_collection_path(resource: params[:resource]), notice: 'Zaktualizowano.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @record.destroy
    redirect_to admin_resource_collection_path(resource: params[:resource]), notice: 'Usunięto.'
  end

  private

  def set_resource_class
    @resource_class = RESOURCES[params[:resource]]
    head :not_found and return unless @resource_class
  end

  def set_record
    @record = @resource_class.find(params[:id])
  end

  def permitted_params
    columns = @resource_class.columns.map(&:name) - %w[id created_at updated_at]
    columns += %w[password password_confirmation] if @resource_class == User

    permitted = params.require(@resource_class.model_name.param_key).permit(columns)
    merge_user_metadata(permitted) if @resource_class == User

    permitted
  end

  def load_schools
    @records = @resource_class.order(created_at: :desc).limit(200)
    render 'admin/resources/schools'
  end

  def load_headmasters
    @records = @resource_class
               .joins(:roles)
               .where(roles: { key: 'principal' })
               .includes(:school)
               .distinct
               .order(created_at: :desc)
               .limit(200)
    render 'admin/resources/headmasters'
  end

  def load_teachers
    # Don't load records server-side, let JavaScript load them via API
    @records = []
    render 'admin/resources/teachers'
  end

  def load_students
    # Don't load records server-side, let JavaScript load them via API
    @records = []
    render 'admin/resources/students'
  end

  def load_events
    # Don't load records server-side, let JavaScript load them via API
    @records = []
    render 'admin/resources/activity_log'
  end

  def load_default_records
    @records = @resource_class.order(created_at: :desc).limit(200)
  end

  def prepare_record_for_creation
    handle_headmaster_metadata if creating_headmaster?
    handle_school_slug if creating_school?
  end

  def creating_headmaster?
    @resource_class == User && params[:user][:role_key] == 'principal'
  end

  def creating_school?
    @resource_class == School
  end

  def handle_headmaster_metadata
    return if params.dig(:user, :metadata, :phone).blank?

    @record.metadata = (@record.metadata || {}).merge(phone: params.dig(:user, :metadata, :phone))
  end

  def handle_school_slug
    return unless @record.slug.blank? && @record.name.present?

    @record.slug = @record.name.parameterize
  end

  def assign_principal_role
    return unless creating_headmaster?

    principal_role = Role.find_by(key: 'principal')
    return unless principal_role

    UserRole.create!(user: @record, role: principal_role, school: @record.school)
  end

  def prepare_params_for_update(update_params)
    merge_user_metadata_for_update(update_params) if updating_user?
    handle_school_slug_update(update_params) if updating_school?
  end

  def updating_user?
    @resource_class == User
  end

  def updating_school?
    @resource_class == School
  end

  def merge_user_metadata_for_update(update_params)
    return if params[:user][:metadata].blank?

    current_metadata = @record.metadata || {}
    new_metadata = params[:user][:metadata].to_unsafe_h
    update_params[:metadata] = current_metadata.merge(new_metadata)
  end

  def handle_school_slug_update(update_params)
    return unless update_params[:slug].blank? && update_params[:name].present?

    update_params[:slug] = update_params[:name].parameterize
  end

  def merge_user_metadata(permitted)
    return if params[:user][:metadata].blank?

    permitted[:metadata] = (permitted[:metadata] || {}).merge(params[:user][:metadata].to_unsafe_h)
  end
end
