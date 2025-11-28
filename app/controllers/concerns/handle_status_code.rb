module HandleStatusCode
  def default_handler(result)
    return not_found_response(result) if result.status == :not_found
    return success_response(result) if result.status == :created
    return success_response(result) if result.status == :ok
    return no_content_response if result.status == :no_content
    return forbidden_response(result) if result.status == :forbidden

    invalid_response(result) unless result.success?
  end

  private

  def success_response(result)
    response.headers.merge!(result.headers) if result.headers.present?
    render json: success_response_params(result),
           status: result.status
  end

  def success_response_params(result)
    data = if result.form.is_a?(Hash)
             result.form
           elsif result.serializer
             result.serializer.new(result.form, params: result.to_h).serializable_hash
           else
             result.form.serializable_hash
           end
    data[:pagination] = result.pagination if result.pagination
    data[:access_token] = result.access_token if result.access_token

    # Management API should return success: true wrapper
    if self.class.name.include?('Management')
      { success: true, data: data }
    else
      data
    end
  end

  def invalid_response(result)
    status = result.status || :unprocessable_entity
    render json: { success: false, errors: result.message }, status: status
  end

  def no_content_response
    render json: {}, status: :no_content
  end

  def forbidden_response(result)
    render json: { errors: result.message }, status: :forbidden
  end

  def not_found_response(result)
    render json: { success: false, errors: result.message }, status: :not_found
  end
end
