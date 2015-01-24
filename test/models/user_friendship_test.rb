require 'test_helper'

class UserFriendshipTest < ActiveSupport::TestCase
  
  should belong_to(:user)
  should belong_to(:friend)

  test "that creating a frendship works without raising an exception" do
  	assert_nothing_raised do
  	UserFriendship.create user: users(:osama), friend: users(:shooq)
  	end
  end

  test "that creating friendship based on user id and friend id works" do
  	UserFriendship.create user_id: users(:osama).id, friend_id: users(:danya).id, state: 'pending'
  	assert users(:osama).pending_friends.include?(users(:danya))
  end

  context "a new instance" do
    setup do
      @user_friendship = UserFriendship.create user: users(:shooq),friend: users(:osama), state: 'pending'

    end

    should "have a pending state" do
      assert_equal 'pending', @user_friendship.state
    end
  end

  context "#send_request_email" do
    setup do
      @user_friendship = UserFriendship.create user: users(:shooq), friend: users(:osama), state: 'pending'
    end

    should "send an email" do
      assert_difference'ActionMailer::Base.deliveries.size', 1 do
        @user_friendship.send_request_email
      end
    end
  end

  context "#accept!" do
    setup do
      @user_friendship = UserFriendship.request users(:shooq), users(:osama)
    end

    should "set the state to accepted" do
      @user_friendship.accept!
      assert_equal "accepted", @user_friendship.state
    end

    should "send an acceptance email" do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        @user_friendship.accept!
      end
    end

    should "include the friend in the list of friends" do
      @user_friendship.accept!
      users(:shooq).friends.reload
      assert users(:shooq).friends.include?(users(:osama))
    end

    should "accept the mutual friendship" do
      @user_friendship.accept!
      assert_equal 'accepted', @user_friendship.mutual_friendship.state
    end
  end

  context ".request" do
    should "create two friendships" do
      assert_difference "UserFriendship.count", 2 do
        UserFriendship.request(users(:osama), users(:shooq))
      end
    end

    should "send a friend request email" do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        UserFriendship.request(users(:osama), users(:shooq))
      end
    end
  end

  context "#delete_mutual_friendship" do
    setup do
      UserFriendship.request users(:osama), users(:shooq)
      @friendship1 = users(:osama).user_friendships.where(friend_id: users(:shooq)).first
      @friendship2 = users(:shooq).user_friendships.where(friend_id: users(:osama)).first
    end

    should "delete the mutual friendship" do
      assert_equal @friendship2, @friendship1.mutual_friendship
      @friendship1.delete_mutual_friendship!
      assert !UserFriendship.exists?(@friendship2.id)
    end
  end

  context "on destroy" do
    setup do
      UserFriendship.request users(:osama), users(:shooq)
      @friendship1 = users(:osama).user_friendships.where(friend_id: users(:shooq)).first
      @friendship2 = users(:shooq).user_friendships.where(friend_id: users(:osama)).first
    end
    should "delete the mutual friendship" do
      @friendship1.destroy
      assert !UserFriendship.exists?(@friendship2.id)
    end
  end
end
