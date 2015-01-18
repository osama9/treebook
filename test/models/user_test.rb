require 'test_helper'

class UserTest < ActiveSupport::TestCase

  should have_many(:user_friendships)
  should have_many(:friends)          

  test "a user should enter a first name" do
  	user = User.new
  	assert !user.save
  	assert !user.errors[:first_name].empty?
  end

  test "a user should enter a last name" do
  	user = User.new
  	assert !user.save
  	assert !user.errors[:last_name].empty?
  end

  test "a user should enter a profile name" do
  	user = User.new
  	assert !user.save
  	assert !user.errors[:profile_name].empty?
  end

  test "a profile name should be unique" do
  	user =User.new
  	user.profile_name = users(:osama).profile_name

  	assert !user.save
  	assert !user.errors[:profile_name].empty?
  end

  test "a user should have a profile name without spaces" do
  	user = User.new(first_name: 'osama', last_name: 'ansari', email: 'osama2@gmail.com')
    user.password = user.password_confirmation = 'asdfasdf'
    
  	user.profile_name = "My Profile with spaces"

  	assert !user.save
  	assert !user.errors[:profile_name].empty?
  	assert user.errors[:profile_name].include?("Must be formatted correctly.")
  end

  test "a user can have a correctly formatted profile name" do
    user = User.new(first_name: 'osama', last_name: 'ansari', email: 'osama2@gmail.com')
    user.password = user.password_confirmation = 'asdfasdf'

    user.profile_name = 'osama_3'
    assert user.valid?
  end

  test "that no error is raised when trying to access a friend list" do
    assert_nothing_raised do
      users(:osama).friends
    end
  end

  test "that creating friendships on a user workd" do
    users(:osama).friends << users(:shooq)
    users(:osama).friends.reload
    assert users(:osama).friends.include?(users(:shooq))
  end

end
