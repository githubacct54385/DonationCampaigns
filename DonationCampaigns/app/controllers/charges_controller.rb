# Validates charge data and sends money via Stripe
class ChargesController < ApplicationController
  def check_stripe_token
    # checks that the Stripe Token exists
    return if charge_params[:stripeToken]
    flash[:error] = 'No payment information submitted.'
    redirect_back(fallback_location: root_path) && return
  end

  def check_campaign_exists
    return if charge_params[:campaign] &&
              Campaign.exists?(charge_params[:campaign])
    flash[:error] = "The campaign you specified doesn't exist."
    redirect_back(fallback_location: root_path) && return
  end

  def check_amount
    # check if amount is correct
    return if charge_params[:amount] != '' &&
              !charge_params[:amount].nil?
    flash[:danger] = 'Please the donation amount before making a payment.'
    redirect_to campaign_path(@campaign) && return
  end

  def check_donor_name
    # check for a name in the Payment Details field
    return if charge_params[:name]
    flash[:danger] = 'Please include your name before making a payment.'
    redirect_to campaign_path(@campaign) && return
  end

  def charge_metadata
    { 'Donor Name' => charge_params[:name],
      'Donor Email' => charge_params[:email],
      'Campaign' => @campaign.id,
      'Campaign name' => @campaign.name,
      'Campaign Owner Email' =>  @campaign_owner.email }
  end

  def do_charge
    # charge the customer
    Stripe::Charge.create(
      source: charge_params[:stripeToken],
      amount: @amount.to_i,
      currency: 'usd',
      application_fee: @amount.to_i / 10, # Take a 10% application fee
      destination: @account_id,
      description: @chrg_desc,
      metadata: charge_metadata
    )
  end

  def create_charge
    @chrg_desc = "Charge for campaign #{@campaign.name}"
    @chrg_desc += " for #{@amount / 100} dollars."
    do_charge
  end

  def set_campaign_vars
    # Retrieve the campaign
    @campaign = Campaign.find(params[:campaign])
    @campaign_owner = User.find(@campaign.user_id)
  end

  def set_amount_var
    # Convert the amount to cents
    @amount = (100 * charge_params[:amount].tr('$', '').to_r).to_i
  end

  def set_user_var
    # get the logged in user
    @user = User.find_by(id: session[:user_id])
  end

  def set_account_id
    # Find the account ID associated with this campaign
    @account_id = User.find(@campaign.user_id).StripeAcctNumber
  end

  def set_instance_vars
    set_campaign_vars
    set_amount_var
    set_user_var
    set_account_id
  end

  def check_account_id
    return if !@account_id.nil? && !@account_id.empty?
    flash[:error] = 'Stripe Account Id for the campaign holder is not set.'
    redirect_to campaign_path(@campaign) && return
  end

  def create_local_charge
    Charge.create(
      DonorName: charge_params[:name],
      campaign_id: charge_params[:campaign],
      amount: charge_params[:amount]
    )
  end

  def increment_raised_money
    # The money raised will show the whole amount,
    # however the amount deposited will have the
    # application fee subtracted from it
    @campaign.MoneyRaised += @amount.to_i
    @campaign.save
  end

  def handle_charge_success
    # Display the message to the screen
    flash[:success] = "You have been charged $#{(@amount / 100)}"
    redirect_to campaign_path(@campaign)
  end

  def handle_stripe_error(e)
    msg = "The 'destination' param cannot be set to your own account."
    same_acct_msg = 'Cannot send donation to your own Stripe account.  \
        You can only donate to other users campaigns.'
    flash[:danger] = if e.message == msg
                       same_acct_msg
                     else
                       e.message
                     end
    redirect_to campaign_path(@campaign) && return
  end

  def run_create_tasks
    set_instance_vars
    check_account_id
    create_charge
    increment_raised_money
    create_local_charge
    handle_charge_success
  end

  def run_checks
    check_stripe_token
    check_campaign_exists
    check_amount
    check_donor_name
  end

  def create
    run_checks
    begin
      run_create_tasks
      # Handle exceptions from Stripe
    rescue Stripe::StripeError => e
      handle_stripe_error(e)
      # Handle other failures
    rescue StandardError => e
      flash[:danger] = e.message
      redirect_to campaign_path(@campaign)
    end
  end

  private

  def charge_params
    params.permit(:amount, :stripeToken, :name,
                  :campaign, :authenticity_token, :email)
  end
end
