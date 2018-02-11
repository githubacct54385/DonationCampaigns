# App Controller
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  # def hello
  #  render html: "hello, world!"
  # end

  # Pretty generic method to handle exceptions.
  # You'll probably want to do some logging, notifications, etc.
  def handle_error(message = 'Sorry, something failed.', view = 'new')
    flash.now[:alert] = message
    render view
  end
end
