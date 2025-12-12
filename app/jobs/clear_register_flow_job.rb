class ClearRegisterFlowJob < BaseSidekiqJob
  def perform
    RegistrationFlow.destroy_all
  end
end
