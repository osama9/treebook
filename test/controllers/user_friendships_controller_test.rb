require 'test_helper'

class UserFriendshipsControllerTest < ActionController::TestCase
    
    context "#index" do
      context "when not logged in" do
        should "redirect to login page" do
          get :index
          assert_response :redirect
        end
      end

      context "when logged in" do
        setup do
          @friendship1 = create(:pending_user_friendship, user: users(:osama), friend: create(:user, first_name: 'Pending', last_name: 'Friend'))
          @friendship2 = create(:accepted_user_friendship, user: users(:osama), friend: create(:user, first_name: 'Active', last_name: 'Friend'))

          sign_in users(:osama)
          get :index
        end

        should "should get the response page without error" do
          assert_response :success
        end

        should "assign user_friendships" do
          assert assigns(:user_friendships)
        end

        should "display friend's names" do
          assert_match /Pending/, response.body
          assert_match /Active/, response.body
        end

        should "display pending information on a pending friendship" do
          assert_select "#user_friendship_#{@friendship1.id}" do
            assert_select "em", "Friendship is pending."
          end
        end
      end
    end


    context "#new" do
    	context "when not logged in" do
  		should "redirect to login page" do
  			get :new
  			assert_response :redirect
        assert_redirected_to login_path
  		end
  	end

  	context "when logged in" do
  		setup do
  			sign_in users(:osama)
  		end

  		should "get new and return succedd" do
  			get :new
  			assert_response :success
  		end

  		should "should set a flash error if the friend_id params is missing" do
  			get :new, {}
  			assert_equal "Friend required", flash[:alert]
  		end

  		should "display the friend's name" do
  			get :new, friend_id: users(:shooq).id
  			assert_match /#{users(:shooq).full_name}/, response.body
  		end

  		should "assign a new user friendship" do
  			get :new, friend_id: users(:shooq).id
  			assert assigns(:user_friendship)
  		end

  		should "assign a new user friendship to the correct friend" do
  			get :new, friend_id: users(:shooq).id
  			assert_equal users(:shooq), assigns(:user_friendship).friend 
  		end

  		should "assign a new user friendship to the currently logged in user" do
  			get :new, friend_id: users(:shooq).id
  			assert_equal users(:osama), assigns(:user_friendship).user 
  		end

  		should "returns 404 status if no friend found" do
  			get :new, friend_id: 'invalid'
  			assert_response :not_found
  		end

  		should "Ask if you really want to friend the user" do
  			get :new, friend_id: users(:shooq).id
  			assert_match /Do you really want to friend #{users(:shooq).full_name}?/, response.body
  		end
  	end
  end

  context "#create" do
    context "when not logged in do" do
      should "redirect to the login page" do
        get :new
        assert_response :redirect
        assert_redirected_to login_path
      end
    end

    context "when logged in" do
      setup do
        sign_in users(:osama)
        @friendship = create(:pending_user_friendship, user: users(:osama), friend: users(:danya))
      end

      context "with no friend id" do
        setup do
          post :create
        end

        should "set the flash error message" do
          
          assert !flash[:alert].empty?
        end

        should "redirected to the root path" do
          assert_redirected_to root_path
        end

      end

      context "successfuly" do
        should "create two user friendship objects" do
            assert_difference 'UserFriendship.count', 2 do
              post :create, user_friendship:{friend_id: users(:shooq).id}
            end
        end
      end

      context "with valid friend id" do
        setup do
          post :create, user_friendship: {friend_id: @friendship.friend.id}
        end

        should "assign a friend object" do
          assert assigns(:friend)
          assert_equal users(:danya), assigns(:friend)
        end

        # should "assign a user_friendship object" do
        #   assert assigns(:user_friendship) do
        #     assert_equal users(:osama), assigns(:user_friendship).user
        #     assert_equal users(:danya), assigns(:user_friendship).friend 
        #   end
        # end

        # should "create a friendship" do
        #   put users(:osama).friends.inspect
        #   assert users(:osama).pending_friends.include?(users(:danya))
        # end

        should "redirect to the profile page of the friend" do
          assert_response :redirect
          assert_redirected_to profile_path(users(:danya))
        end

        # should "set the flash success message" do
        #   assert !flash[:notice].empty?
        #   assert_equal "You are now friends with #{users(:danya).full_name}", flash[:notice]
        # end
      end
    end
  end 

  context "#mutual_friendship" do
    setup do
      UserFriendship.request users(:osama), users(:shooq)
      @friendship1 = users(:osama).user_friendships.where(friend_id: users(:shooq)).first
      @friendship2 = users(:shooq).user_friendships.where(friend_id: users(:osama)).first
    end

    should "correctly find the mutual friendship" do
      assert_equal @friendship2, @friendship1.mutual_friendship

    end
  end

  context "#accept mutual friendship" do
    setup do
      UserFriendship.request users(:osama), users(:shooq)
    end

    should "accept the mutual friendship" do
      friendship1 = users(:osama).user_friendships.where(friend_id: users(:shooq).id).first
      friendship2 = users(:shooq).user_friendships.where(friend_id: users(:osama).id).first

      friendship1.accept_mutual_friendship!
      friendship2.reload
      assert_equal 'accepted', friendship2.state
    end
  end

  context "#accept" do
      context "when not logged in" do
        should "redirect to login page" do
          put :accept, id: 1
          assert_response :redirect
          assert_redirected_to login_path
        end
      end

      context "when logged in" do
        setup do
          @friend = create(:user)
          @user_friendship = create(:pending_user_friendship, user: users(:osama), friend: @friend)
          create(:pending_user_friendship, user: @friend, friend: users(:osama))
          sign_in users(:osama)
          put :accept, id: @user_friendship
          @user_friendship.reload
        end

        should "assign a user_friendship" do
          assert assigns(:user_friendship)
          assert_equal @user_friendship, assigns(:user_friendship)
        end

        should "update the state to accepted" do
          assert_equal 'accepted', @user_friendship.state
        end
        should "have a flash success message" do
          assert_equal "You are now friends with #{@user_friendship.friend.first_name}", flash[:notice]
        end
      end
    end

    context "#edit" do
      context "when not logged in" do
        should "redirect to login page" do
          get :edit, id: 1
          assert_response :redirect
          assert_redirected_to login_path
        end
      end

      context "when logged in" do
        setup do
          @user_friendship = create(:pending_user_friendship, user: users(:osama))
          sign_in users(:osama)
          get :edit, id: @user_friendship
        end

      should "get edit and return succedd" do
        assert_response :success
      end
      should "assign to user_friendship" do
        assert assigns(:user_friendship)
      end
      should "assign to friend" do
        assert assigns(:friend)
      end
    end
  end
 
 context "#destroy" do
      context "when not logged in" do
        should "redirect to login page" do
          delete :destroy, id: 1
          assert_response :redirect
          assert_redirected_to login_path
        end
      end

      context "when logged in" do
        setup do
          @friend = create (:user)
          @user_friendship = create(:accepted_user_friendship, friend: @friend, user: users(:osama))
          create(:accepted_user_friendship, friend: users(:osama), user: @friend)

          sign_in users(:osama)
        end

        should "delete the user friendships" do
          assert_difference 'UserFriendship.count', -2 do
            delete :destroy, id: @user_friendship.id
          end
        end

        should "set the flash" do
          delete :destroy, id: @user_friendship.id
          assert_equal "Friendship destroyed", flash[:notice]
        end

      end
    end

end
