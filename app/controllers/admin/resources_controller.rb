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
  before_action :set_record, only: %i[ show edit update destroy ]

  def index
    @records = @resource_class.order(created_at: :desc).limit(200)
  end

  def show; end

  def new
    @record = @resource_class.new
  end

  def edit; end

  def create
    @record = @resource_class.new(permitted_params)
    if @record.save
      redirect_to admin_resource_path(resource: params[:resource], id: @record.id), notice: 'Utworzono.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @record.update(permitted_params)
      redirect_to admin_resource_path(resource: params[:resource], id: @record.id), notice: 'Zaktualizowano.'
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
    params.require(@resource_class.model_name.param_key).permit(columns)
  end
end


