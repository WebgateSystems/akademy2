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

  before_action :set_resource_class, except: %i[reorder_subjects reorder_learning_module_contents]
  before_action :set_record, only: %i[show edit update destroy]

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
    when 'subjects'
      load_subjects
    when 'units'
      load_units
    when 'learning_modules'
      load_learning_modules
    when 'contents'
      load_contents
    else
      load_default_records
    end
  end

  def show
    case params[:resource]
    when 'subjects'
      render 'admin/resources/subjects_show'
    when 'units'
      render 'admin/resources/units_show'
    when 'learning_modules'
      render 'admin/resources/learning_modules_show'
    when 'contents'
      render 'admin/resources/contents_show'
    end
  end

  def new
    case params[:resource]
    when 'subjects'
      @record = @resource_class.new
      render 'admin/resources/subjects_new'
    when 'units'
      @record = @resource_class.new
      render 'admin/resources/units_new'
    when 'learning_modules'
      @record = @resource_class.new
      render 'admin/resources/learning_modules_new'
    when 'contents'
      @record = @resource_class.new
      render 'admin/resources/contents_new'
    else
      @record = @resource_class.new
    end
  end

  def edit
    case params[:resource]
    when 'subjects'
      render 'admin/resources/subjects_edit'
    when 'units'
      render 'admin/resources/units_edit'
    when 'learning_modules'
      render 'admin/resources/learning_modules_edit'
    when 'contents'
      render 'admin/resources/contents_edit'
    end
  end

  def create
    create_params = permitted_params
    handle_content_payload(create_params) if creating_content?

    @record = @resource_class.new(create_params)
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
    handle_content_payload(update_params) if updating_content?

    # Handle icon removal for Subject
    @record.remove_icon! if @resource_class == Subject && params[:subject][:remove_icon] == '1'

    if @record.update(update_params)
      redirect_to admin_resource_collection_path(resource: params[:resource]), notice: 'Zaktualizowano.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @record.destroy
      redirect_to admin_resource_collection_path(resource: params[:resource]), notice: 'Usunięto.'
    else
      error_messages = @record.errors.full_messages.presence || ['Nie można usunąć rekordu']
      redirect_to admin_resource_collection_path(resource: params[:resource]), alert: error_messages.join(', ')
    end
  rescue ActiveRecord::InvalidForeignKey
    # Check what's blocking deletion
    blocking_message = check_blocking_associations
    alert_message = blocking_message || 'Nie można usunąć rekordu, ponieważ jest używany przez inne elementy.'
    redirect_to admin_resource_collection_path(resource: params[:resource]), alert: alert_message
  rescue StandardError => e
    Rails.logger.error("Destroy failed: #{e.message}")
    alert_message = 'Nie można usunąć rekordu. Sprawdź czy nie jest używany przez inne elementy.'
    redirect_to admin_resource_collection_path(resource: params[:resource]), alert: alert_message
  end

  def reorder_subjects
    subject_ids = params[:subject_ids]
    return head :bad_request unless subject_ids.is_a?(Array)

    # Validate that all IDs are valid UUIDs
    return head :bad_request unless subject_ids.all? do |id|
      id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end

    # Build a single SQL query with CASE WHEN to update all order_index values at once
    # This is much more efficient than updating each record separately
    case_when = subject_ids.each_with_index.map do |subject_id, index|
      sanitized_id = Subject.connection.quote(subject_id)
      "WHEN #{sanitized_id} THEN #{index + 1}"
    end.join(' ')

    sanitized_ids = subject_ids.map { |id| Subject.connection.quote(id) }.join(', ')

    sql = <<-SQL.squish
      UPDATE subjects
      SET order_index = CASE id
        #{case_when}
      END
      WHERE id IN (#{sanitized_ids})
    SQL

    Subject.connection.execute(sql)

    head :ok
  end

  def reorder_learning_module_contents
    learning_module = LearningModule.find(params[:id])
    content_ids = params[:content_ids]

    return head :bad_request unless content_ids.is_a?(Array)
    return head :bad_request unless content_ids.all? do |id|
      id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end

    # Verify all contents belong to this learning module
    contents = Content.where(id: content_ids, learning_module_id: learning_module.id)
    return head :bad_request unless contents.count == content_ids.count

    # Build a single SQL query with CASE WHEN to update all order_index values at once
    case_when = content_ids.each_with_index.map do |content_id, index|
      sanitized_id = Content.connection.quote(content_id)
      "WHEN #{sanitized_id} THEN #{index + 1}"
    end.join(' ')

    sanitized_ids = content_ids.map { |id| Content.connection.quote(id) }.join(', ')

    sql = <<-SQL.squish
      UPDATE contents
      SET order_index = CASE id
        #{case_when}
      END
      WHERE id IN (#{sanitized_ids})
        AND learning_module_id = #{Content.connection.quote(learning_module.id)}
    SQL

    Content.connection.execute(sql)

    head :ok
  end

  def check_blocking_associations
    case @resource_class.name
    when 'Subject'
      check_subject_blocking
    when 'Unit'
      check_unit_blocking
    when 'LearningModule'
      check_learning_module_blocking
    end
  end

  def check_subject_blocking
    units_count = @record.units.count
    learning_modules_count = LearningModule.joins(:unit).where(units: { subject_id: @record.id }).count
    if learning_modules_count.positive?
      suffix = polish_pluralize(learning_modules_count, '', 'y', 'ów')
      return "Nie można usunąć przedmiotu, ponieważ zawiera #{learning_modules_count} moduł#{suffix} edukacyjnych."
    elsif units_count.positive?
      suffix = polish_pluralize(units_count, 'ę', 'i', '')
      return "Nie można usunąć przedmiotu, ponieważ zawiera #{units_count} jednostek#{suffix}."
    end
    nil
  end

  def check_unit_blocking
    learning_modules_count = @record.learning_modules.count
    return nil unless learning_modules_count.positive?

    suffix = polish_pluralize(learning_modules_count, '', 'y', 'ów')
    "Nie można usunąć jednostki, ponieważ zawiera #{learning_modules_count} moduł#{suffix} edukacyjnych."
  end

  def check_learning_module_blocking
    contents_count = @record.contents.count
    quiz_results_count = QuizResult.where(learning_module_id: @record.id).count
    if quiz_results_count.positive?
      suffix = polish_pluralize(quiz_results_count, '', 'i', 'ów')
      return "Nie można usunąć modułu, ponieważ ma #{quiz_results_count} wynik#{suffix} quizów."
    elsif contents_count.positive?
      suffix = polish_pluralize(contents_count, '', 'y', 'ów')
      return "Nie można usunąć modułu, ponieważ zawiera #{contents_count} materiał#{suffix}."
    end
    nil
  end

  def polish_pluralize(count, singular_suffix, plural_2_4_suffix, plural_5plus_suffix)
    return singular_suffix if count == 1
    return plural_2_4_suffix if count < 5

    plural_5plus_suffix
  end

  private

  def set_resource_class
    @resource_class = RESOURCES[params[:resource]]
    head :not_found and return unless @resource_class
  end

  def set_record
    # Use eager loading only for destroy action to avoid N+1 queries during cascade deletion
    # For other actions (show, edit, update), regular find is sufficient
    @record = if action_name == 'destroy'
                if @resource_class == Subject
                  @resource_class.with_associations_for_destroy.find(params[:id])
                elsif @resource_class == Unit
                  @resource_class.includes(learning_modules: :contents).find(params[:id])
                elsif @resource_class == LearningModule
                  @resource_class.includes(:contents).find(params[:id])
                else
                  @resource_class.find(params[:id])
                end
              elsif action_name == 'show' && @resource_class == LearningModule
                # Eager load contents for show view
                @resource_class.includes(:contents).find(params[:id])
              elsif action_name == 'edit' && @resource_class == LearningModule
                # Eager load contents and all available contents for edit view
                @resource_class.includes(:contents).find(params[:id])
              else
                @resource_class.find(params[:id])
              end
  end

  def permitted_params
    columns = @resource_class.columns.map(&:name) - %w[id created_at updated_at]
    columns += %w[password password_confirmation] if @resource_class == User

    # For Subject
    if @resource_class == Subject
      # Icon is handled by CarrierWave uploader (file upload)
      columns += %w[icon] unless columns.include?('icon')
      # Exclude slug and order_index from create (they are auto-generated)
      # But allow them in update (slug can be edited)
      columns -= %w[slug order_index school_id] if action_name == 'create'
    end

    # For Unit
    if (@resource_class == Unit) && (action_name == 'create')
      # Exclude order_index from create (it is auto-generated)
      columns -= %w[order_index]
    end

    # For LearningModule
    if (@resource_class == LearningModule) && (action_name == 'create')
      # Exclude order_index from create (it is auto-generated)
      columns -= %w[order_index]
    end

    # For Content
    if @resource_class == Content
      # Include file upload fields
      columns += %w[file poster subtitles] unless columns.include?('file')
      # Exclude order_index from create (it is auto-generated)
      columns -= %w[order_index] if action_name == 'create'
    end

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

  def load_subjects
    # Global subjects (school_id is nil) first, then school-specific
    @records = @resource_class
               .order(Arel.sql('school_id NULLS FIRST, order_index ASC, created_at DESC'))
               .limit(200)
    render 'admin/resources/subjects'
  end

  def load_units
    @records = @resource_class
               .includes(:subject)
               .order('subjects.order_index ASC, units.order_index ASC')
               .limit(200)
    render 'admin/resources/units'
  end

  def load_learning_modules
    @records = @resource_class
               .includes(unit: :subject)
               .order('units.order_index ASC, learning_modules.order_index ASC')
               .limit(200)
    render 'admin/resources/learning_modules'
  end

  def load_contents
    order_clause = 'subjects.order_index ASC, units.order_index ASC, ' \
                   'learning_modules.order_index ASC, contents.order_index ASC'
    @records = @resource_class
               .includes(learning_module: { unit: :subject })
               .order(order_clause)
               .limit(200)
    render 'admin/resources/contents'
  end

  def load_default_records
    @records = @resource_class.order(created_at: :desc).limit(200)
  end

  def prepare_record_for_creation
    handle_headmaster_metadata if creating_headmaster?
    handle_school_slug if creating_school?
    handle_subject_slug_and_order if creating_subject?
    handle_unit_order if creating_unit?
    handle_learning_module_order if creating_learning_module?
    handle_content_order if creating_content?
  end

  def creating_headmaster?
    @resource_class == User && params[:user][:role_key] == 'principal'
  end

  def creating_school?
    @resource_class == School
  end

  def creating_subject?
    @resource_class == Subject
  end

  def creating_unit?
    @resource_class == Unit
  end

  def creating_learning_module?
    @resource_class == LearningModule
  end

  def creating_content?
    @resource_class == Content
  end

  def updating_content?
    @resource_class == Content
  end

  def handle_content_payload(params_hash)
    return unless @resource_class == Content

    # Handle payload_json (for quiz)
    if params[:content] && params[:content][:payload_json].present?
      begin
        parsed_payload = JSON.parse(params[:content][:payload_json])
        params_hash[:payload] = parsed_payload
      rescue JSON::ParserError => e
        # Add error to record - Rails will handle validation failure
        if @record
          @record.errors.add(:payload, "Invalid JSON: #{e.message}")
        else
          # For create action, we'll validate in the model
          params_hash[:payload] = {}
        end
      end
    end

    # Handle payload_subtitles_lang (for video)
    if params[:content] && params[:content][:payload_subtitles_lang].present?
      params_hash[:payload] = { 'subtitles_lang' => params[:content][:payload_subtitles_lang] }
    end

    # Remove temporary fields from params_hash
    params_hash.delete(:payload_json) if params_hash.key?(:payload_json)
    params_hash.delete(:payload_subtitles_lang) if params_hash.key?(:payload_subtitles_lang)
  end

  def handle_content_order
    return unless @resource_class == Content

    # Set order_index to be last for the learning module (highest + 1 within the module)
    if @record.learning_module_id.present?
      max_order = Content.where(learning_module_id: @record.learning_module_id).maximum(:order_index) || 0
      @record.order_index = max_order + 1
    else
      # If no learning module selected, set to 0 (will be updated when module is selected)
      @record.order_index = 0
    end
  end

  def handle_unit_order
    return unless @resource_class == Unit

    # Set order_index to be last for the subject (highest + 1 within the subject)
    if @record.subject_id.present?
      max_order = Unit.where(subject_id: @record.subject_id).maximum(:order_index) || 0
      @record.order_index = max_order + 1
    else
      # If no subject selected, set to 0 (will be updated when subject is selected)
      @record.order_index = 0
    end
  end

  def handle_subject_slug_and_order
    return unless @resource_class == Subject

    # Generate slug from title if not provided
    @record.slug = @record.title.parameterize if @record.title.present? && @record.slug.blank?

    # Set order_index to be last (highest + 1)
    max_order = Subject.maximum(:order_index) || 0
    @record.order_index = max_order + 1
  end

  def handle_learning_module_order
    return unless @resource_class == LearningModule

    # Set order_index to be last for the unit (highest + 1 within the unit)
    if @record.unit_id.present?
      max_order = LearningModule.where(unit_id: @record.unit_id).maximum(:order_index) || 0
      @record.order_index = max_order + 1
    else
      # If no unit selected, set to 0 (will be updated when unit is selected)
      @record.order_index = 0
    end
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
