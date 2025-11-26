class Admin::ResourcesController < Admin::BaseController
  RESOURCES = {
    'users' => User,
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

  def index
    if params[:resource] == 'schools'
      @records = @resource_class.order(created_at: :desc).limit(200)
      render 'admin/resources/schools' and return
    elsif params[:resource] == 'users'
      # Filter for headmasters (principals)
      @records = @resource_class.joins(:roles).where(roles: { key: 'principal' }).distinct.order(created_at: :desc).limit(200)
      render 'admin/resources/headmasters' and return
    elsif params[:resource] == 'events'
      @records = @resource_class.includes(:user, :school).order(occurred_at: :desc, created_at: :desc).limit(200)
      render 'admin/resources/activity_log' and return
    end
    
    @records = @resource_class.order(created_at: :desc).limit(200)
  end

  def show; end

  def new
    @record = @resource_class.new
  end

  def edit; end

  def create
    @record = @resource_class.new(permitted_params)
    
    # Special handling for User creation as headmaster
    if @resource_class == User && params[:user][:role_key] == 'principal'
      @record.metadata = (@record.metadata || {}).merge(phone: params.dig(:user, :metadata, :phone)) if params.dig(:user, :metadata, :phone).present?
    end
    
    if @record.save
      # Assign principal role if creating headmaster
      if @resource_class == User && params[:user][:role_key] == 'principal'
        principal_role = Role.find_by(key: 'principal')
        UserRole.create!(user: @record, role: principal_role, school: @record.school) if principal_role
      end
      
      redirect_to admin_resource_collection_path(resource: params[:resource]), notice: 'Utworzono.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    update_params = permitted_params
    
    # Handle metadata for User
    if @resource_class == User && params[:user][:metadata].present?
      current_metadata = @record.metadata || {}
      new_metadata = params[:user][:metadata].to_unsafe_h
      update_params[:metadata] = current_metadata.merge(new_metadata)
    end
    
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
    
    # Handle metadata for User
    if @resource_class == User && params[:user][:metadata].present?
      permitted[:metadata] = (permitted[:metadata] || {}).merge(params[:user][:metadata].to_unsafe_h)
    end
    
    permitted
  end
end
