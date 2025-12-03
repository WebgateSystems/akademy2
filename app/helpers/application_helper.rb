module ApplicationHelper
  def app_version
    "App version: ##{AppIdService.version}"
  end
end
