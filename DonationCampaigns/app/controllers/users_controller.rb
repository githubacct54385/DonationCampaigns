# Handles User actions for creation, stripe account connection
# and showing Users
class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def create
    @user = User.new(user_params)
    @user.StripeRegistered = false
    if @user.save
      # Handle a successful save.
      log_in @user
      flash[:success] = 'Welcome to the Donations App!'
      redirect_to @user
    else
      render 'new'
    end
  end

  def stripe_connected
    Rails.logger.info 'Stripe Connected Received...'
    unless logged_in?
      flash[:danger] = 'Please login again to proceed.'
      redirect_to root_url && return
    end

    params.each do |key, value|
      Rails.logger.info "Key: #{key}, Value: #{value}"
    end

    Rails.logger.info "Authorization Code: #{params[:code]}"

    require 'net/http'
    require 'uri'

    uri = URI.parse('https://connect.stripe.com/oauth/token')
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      'client_secret' => Rails.configuration.stripe[:secret_key].to_s,
      'code' => params[:code].to_s,
      'grant_type' => 'authorization_code'
    )

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    Rails.logger.info "Response Body: #{response.body}"

    @user = User.find_by(id: session[:user_id])

    stripe_acct_num = JSON.parse(response.body)['stripe_user_id'].to_s
    Rails.logger.info JSON.parse(response.body)
    Rails.logger.info stripe_acct_num
    if stripe_acct_num.empty?
      flash[:danger] = 'Stripe Account Number could not be parsed from JSON'
      redirect_to @user && return
    end

    Rails.logger.info "Stripe Account Number: #{stripe_acct_num}"
    @user.update_attributes(StripeRegistered: true,
                            StripeAcctNumber: stripe_acct_num)
    if @user.save
      Rails.logger.info 'Successful edit user now'
      flash[:success] = 'Congratulations!  \
      You are all set to create and support campaigns.'
      redirect_to @user && return
    else
      Rails.logger.info 'Failed to edit user now'
      puts @user.errors.full_messages
    end
  end

  def show
    unless User.exists?(id: params[:id])
      flash[:danger] = 'The user you specified does not exist.'
      redirect_back(fallback_location: root_path) && return
    end

    # get the campaigns that this user has created
    @campaigns = Campaign.where(user_id: params[:id])

    @user = User.find(params[:id])
    Rails.logger.info @user.inspect
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password,
                                 :password_confirmation)
  end
end
