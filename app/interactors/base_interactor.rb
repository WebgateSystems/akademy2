class BaseInteractor
  include Interactor

  delegate :current_user, to: :context

  def access_denied
    context.message = ['Access Denied']
    context.status = :forbidden
    context.fail!
  end

  def not_found
    context.status = :not_found
    context.message = ['Not Found']
    context.fail!
  end

  def no_content
    context.status = :no_content
    context.fail!
  end

  def bad_outcome
    context.errors = current_form.errors
    context.message = current_form.messages
    context.status = :unprocessable_entity
    context.fail!
  end

  def bad_result(form)
    context.message = form.message
    context.status = form.status
    context.fail!
  end
end
