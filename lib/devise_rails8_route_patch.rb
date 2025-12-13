# frozen_string_literal: true

# Monkey-patch for Devise 4.9.4 to fix Rails 8.x deprecation warnings
# See: https://github.com/heartcombo/devise/issues/5735
#
# Devise uses old-style hash arguments for the `resource` route helper.
# Rails 8.x deprecated this in favor of keyword arguments.
# This patch converts hash arguments to keyword arguments.
#
# TODO: Remove this once Devise releases a version with the fix (likely 4.10+)

module DeviseRails8RoutePatch
  def resource(*args, &block)
    # If the last argument is a Hash (not keyword args), convert it
    if args.length > 1 && args.last.is_a?(Hash)
      options = args.pop
      super(*args, **options, &block)
    else
      super
    end
  end
end
