# Validates charge data and sends money via Stripe
class ChargesController < ApplicationController
  def check_stripe_token
    # checks that the Stripe Token exists
    return if charge_params[:stripeToken]
    flash[:error] = 'No payment information submitted.'
    redirect_back(fallback_location: root_path) && return
    # end
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
    redirect_to campaign_path(campaign) && return
  end

  def check_donor_name
    # check for a name in the Payment Details field
    return if charge_params[:name]
    flash[:danger] = 'Please include your name before making a payment.'
    redirect_to campaign_path(campaign) && return
  end

  def create
    check_stripe_token
    check_campaign_exists
    check_amount
    check_donor_name

    # Retrieve the campaign
    campaign = Campaign.find(params[:campaign])
    begin
    # Convert the amount to cents
    amount = (100 * charge_params[:amount].tr('$', '').to_r).to_i
    # get the logged in user
    @user = User.find_by(id: session[:user_id])
    campaign_owner = User.find(campaign.user_id)

    # Find the account ID associated with this campaign
    account_id = User.find(campaign.user_id).StripeAcctNumber
    if account_id.nil? || account_id.empty?
      flash[:error] = 'Stripe Account Id for the campaign holder is not set.'
      redirect_to campaign_path(campaign) && return
    end

    chrg_desc = "Charge for campaign #{campaign.name}"
    chrg_desc += " for #{amount / 100} dollars."
    # charge the customer
    Stripe::Charge.create(
      source: charge_params[:stripeToken],
      amount: amount.to_i,
      currency: 'usd',
      application_fee: amount.to_i / 10, # Take a 10% application fee
      destination: account_id,
      description: chrg_desc,
      metadata: { 'Donor Name' => charge_params[:name],
                  'Donor Email' => charge_params[:email],
                  'Campaign' => campaign.id,
                  'Campaign name' => campaign.name,
                  'Campaign Owner Email' =>  campaign_owner.email }
    )
    # The money raised will show the whole amount,
    # however the amount deposited will have the
    # application fee subtracted from it
    campaign.MoneyRaised += amount.to_i
    campaign.save
    Charge.create(
      DonorName: charge_params[:name],
      campaign_id: charge_params[:campaign],
      amount: charge_params[:amount]
    )
    # Display the message to the screen
    flash[:success] = "You have been charged $#{(amount / 100)}"
    redirect_to campaign_path(campaign)

    # Handle exceptions from Stripe
  rescue Stripe::StripeError => e
    if e.message == "The 'destination' param cannot be set to your own account."
      flash[:danger] = 'Cannot send donation to your own Stripe account.  \
      You can only donate to other users campaigns.'
    else
      flash[:danger] = e.message
    end
    redirect_to campaign_path(campaign) && return
    # Handle other failures
  rescue StandardError => e
    puts "Error in charges-controller#create -- #{e.message}"
    flash[:danger] = e.message
    redirect_to campaign_path(campaign)
  end
  end

  private

  def charge_params
    params.permit(:amount, :stripeToken, :name,
                  :campaign, :authenticity_token, :email)
  end
end
