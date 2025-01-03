# frozen_string_literal: true

class Errors::ErrorReportingService
  attr_reader :error, :handled, :severity, :context, :current_user

  def initialize(error, handled, severity, context, user)
    @error = error
    @handled = handled
    @severity = severity
    @context = context
    @current_user = user
  end

  def call
    begin
    Error.create!(
      message: @error&.message,
      backtrace: @error&.backtrace&.reject{ |e| e.include? '/gems/ruby' },
      error_type: @error&.exception&.class&.name,
      handled: @handled,
      severity: @severity.to_s,
      context: context_details,
      user_id: @current_user.id
    )
    rescue
      p "Error generation failed..."
    end
  end

  private

  def context_details
    {
      'controller' => @context[:controller]&.class&.name,
      'action' => @context[:controller]&.action_name,
      'url' => @context[:url],
      'source' => @context[:source] || 'application',
    } if @context
  end
end
