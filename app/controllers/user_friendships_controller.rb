class UserFriendshipsController < ApplicationController
	before_filter :authenticate_user!


	def index 
		@user_friendships = current_user.user_friendships.all
	end

	def accept
		@user_friendship = current_user.user_friendships.find(params[:id])
		if @user_friendship.accept!
			flash[:notice] = "You are now friends with #{@user_friendship.friend.first_name}"
		else
			flash[:alert] = "The friendship could not be accepted"
		end

		redirect_to user_friendships_path
	end

	def new
		
		if friend_params
			
			#@friend = User.where(profile_name: params[:friend_params])
			@friend = User.find(friend_params)
			@user_friendship =  current_user.user_friendships.new(friend: @friend)
		else
			flash[:alert] = "Friend required"
		end

	rescue ActiveRecord::RecordNotFound
		render file: '/public/404', status: :not_found
	end


	def create
		if friend_params
			@friend = User.find(friend_params)
			if !UserFriendship.where(user_id: current_user.id, friend_id:@friend.id, state: 'pending').empty?
				flash[:notice] = "You already friends with #{@friend.full_name}"
				redirect_to profile_path(@friend)
			else		
				@user_friendship = UserFriendship.request(current_user, @friend)
				if @user_friendship.new_record?
					flash[:alert] = "There was a problem creating a friend request."
				else
					flash[:notice] = "Friend request was sent."
				end
				redirect_to profile_path(@user_friendship.friend)
			end
		else
			flash[:alert] = "Friend required"
			redirect_to root_path
		end
	end

	def edit
		@user_friendship = current_user.user_friendships.find(params[:id])
		@friend = @user_friendship.friend
	end


	def destroy
		@user_friendship = current_user.user_friendships.find(params[:id])
		if @user_friendship.destroy
			flash[:notice] = "Friendship destroyed"
		end
		redirect_to user_friendships_path
	end

	# Never trust parameters from the scary internet, only allow the white list through.
    def friend_params
      if params[:friend_id]
      	return params.require(:friend_id)
      elsif params[:user_friendship]
      	return params.require(:user_friendship,).permit([:friend_id])[:friend_id]
      else
      	return nil
      end
    end


end
