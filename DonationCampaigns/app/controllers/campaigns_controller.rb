# Handles campaign actions
class CampaignsController < ApplicationController
  def home
    # Retrieve all active campaigns to be displayed on the homepage
    @campaigns = Campaign.where(IsActive: true)
  end

  def about; end

  def new
    # Initialize a new campaign for creation
    unless logged_in?
      flash[:danger] = 'Please login first'
      redirect_to login_url && return
    end

    unless logged_in_StripeCreds?
      flash[:danger] =
        'Please register your account with Stripe before creating an account'
      redirect_to user_path(current_user) && return
    end
    @campaign = Campaign.new
  end

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    # set active and money raised variables
    @campaign.IsActive = true
    @campaign.MoneyRaised = 0
    # save campaign, if successful, show the campaign, if not, show errors
    if @campaign.save
      flash[:success] = 'Your campaign has been created!'
      redirect_to @campaign
    else
      render 'new'
    end
  end

  def show
    unless Campaign.exists?(id: params[:id])
      flash[:danger] = 'The campaign you specified does not exist.'
      redirect_back(fallback_location: root_path) && return
    end

    # show the campaign
    @campaign = Campaign.find(params[:id])
    @charge = Charge.new
    # @campaignOwner = User.find(@campaign.user_id)
    # List all charges for a given campaign
    @charges = Charge.where(campaign_id: @campaign.id).order(created_at: :desc)
  end

  def destroy
    @campaign = Campaign.find(params[:id])
    name = @campaign.name
    @campaign.destroy

    flash[:success] = "Your #{name} campaign has been successfully deleted."
    redirect_to root_url
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name, :description, :goal, :picture)
  end
end
