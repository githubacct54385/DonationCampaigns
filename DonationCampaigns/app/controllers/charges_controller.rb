class ChargesController < ApplicationController


	def create
    # checks that the Stripe Token exists
    unless charge_params[:stripeToken]
      flash[:error] = "No payment information submitted."
      redirect_back(fallback_location: root_path) and return
    end

		# Check for a valid campaign ID
    unless charge_params[:campaign] && Campaign.exists?(charge_params[:campaign])
      flash[:error] = "The campaign you specified doesn't exist."
      redirect_back(fallback_location: root_path) and return
    end

    # Retrieve the campaign
    campaign = Campaign.find(params[:campaign])

    # check if amount is correct
    if charge_params[:amount] == "" || charge_params[:amount] == nil
      flash[:danger] = "Please the donation amount before making a payment."
      redirect_to campaign_path(campaign) and return
    end

    # check for a name in the Payment Details field
    unless charge_params[:name]
      flash[:danger] = "Please include your name before making a payment."
      redirect_to campaign_path(campaign) and return
    end

    #puts "---PASSED VALIDATION---"

    begin
      # Convert the amount to cents
      amount = (100 * charge_params[:amount].tr('$', '').to_r).to_i    	

      # get the logged in user
      @user = User.find_by(id: session[:user_id])

      puts User.find(campaign.user_id).inspect
      campaignOwner = User.find(campaign.user_id)

      # Find the account ID associated with this campaign
      account_id = User.find(campaign.user_id).StripeAcctNumber
      puts "Acct ID: " + account_id

      if account_id == nil || account_id.empty?
        flash[:error] = "Stripe Account Id for the campaign holder is not set."
        redirect_to campaign_path(campaign) and return
      end

      #puts "---ACCT ID NOT EMPTY OR NIL---"

      # charge the customer
      charge = Stripe::Charge.create({
        source: charge_params[:stripeToken],
        amount: amount.to_i,
        currency: "usd",
        application_fee: amount.to_i/10, # Take a 10% application fee for the platform
        destination: account_id,
        description: "Charge for campaign #{campaign.name} for #{amount/100} dollars.",
        metadata: {"Donor Name" => charge_params[:name], "Donor Email" => charge_params[:email], "campaign" => campaign.id, "campaign name" => campaign.name, "CampaignOwnerEmail" =>  campaignOwner.email}
        }
      )

      #puts "---CHARGE CREATED---"

      # The money raised will show the whole amount, 
      # however the amount deposited will have the 
      # application fee subtracted from it
      campaign.MoneyRaised += amount.to_i 
      campaign.save

      #puts "---CAMPAIGN SAVED---"

      charge = Charge.create({
        DonorName: charge_params[:name],
        campaign_id: charge_params[:campaign],
        amount: charge_params[:amount]
      })

      #puts "--LOCAL CHARGE CREATED---"

      # Display the message to the screen       
      flash[:success] = "You have been charged $#{(amount / 100).to_s}"
      redirect_to campaign_path(campaign)

    # Handle exceptions from Stripe
    rescue Stripe::StripeError => e

      if e.message == "The 'destination' param cannot be set to your own account."
        flash[:danger] = "You are trying to send a donation to your own Stripe account.  You can only donate to other users campaigns."
        redirect_to campaign_path(campaign) and return
      else
        flash[:danger] = e.message
        redirect_to campaign_path(campaign) and return
      end
    # Handle other failures
    rescue => e
      puts "Error in charges-controller#create -- #{e.message}"
      flash[:danger] = e.message
      redirect_to campaign_path(campaign)
    end
	end

	private
		  def charge_params
        params.permit(:amount, :stripeToken, :name, :campaign, :authenticity_token, :email)
    	end
end
