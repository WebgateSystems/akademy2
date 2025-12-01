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
    # Build params hash for serializer, including school_id if present
    serializer_params = {}

    # Safely convert result to hash for serializer params
    if result.respond_to?(:to_h)
      begin
        hash_result = result.to_h
        serializer_params.merge!(hash_result)
      rescue ActionController::UnfilteredParameters
        # If to_h fails, try to_unsafe_h (safe here as we're only reading)
        serializer_params.merge!(result.to_unsafe_h) if result.respond_to?(:to_unsafe_h)
      end
    end

    # Ensure school_id is set if present in result (override any from to_h)
    # Interactor context stores school_id directly
    if result.respond_to?(:school_id) && result.school_id
      serializer_params[:school_id] = result.school_id
      Rails.logger.debug "HandleStatusCode: school_id from result.school_id: #{result.school_id}"
    elsif serializer_params[:school_id]
      Rails.logger.debug "HandleStatusCode: school_id from serializer_params: #{serializer_params[:school_id]}"
    else
      Rails.logger.debug 'HandleStatusCode: No school_id found!'
    end

    Rails.logger.debug "HandleStatusCode: Final serializer_params[:school_id]: #{serializer_params[:school_id].inspect}"

    data = if result.form.is_a?(Hash)
             result.form
           elsif result.form.is_a?(Array)
             # Return array directly wrapped in data key
             { data: result.form }
           elsif result.serializer
             result.serializer.new(result.form, params: serializer_params).serializable_hash
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
