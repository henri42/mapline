require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "génère un slug à partir du nom affiché à la création" do
    user = User.create!(
      email_address: "jeanne@example.com",
      display_name: "Jeanne d'Arc",
      password: "motdepasse123",
      password_confirmation: "motdepasse123"
    )

    assert_match(/\Ajeanne-d-arc-[a-z0-9]{6}\z/, user.slug)
  end

  test "exige un nom affiché" do
    user = User.new(email_address: "x@example.com", password: "motdepasse123")

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :display_name
  end

  test "normalise et exige un e-mail unique" do
    User.create!(
      email_address: "dup@example.com",
      display_name: "Premier",
      password: "motdepasse123"
    )
    duplicate = User.new(
      email_address: "  DUP@example.com  ",
      display_name: "Second",
      password: "motdepasse123"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :email_address
  end

  test "rejette une URL de site invalide" do
    user = User.new(
      email_address: "url@example.com",
      display_name: "Test",
      password: "motdepasse123",
      website_url: "pas-une-url"
    )

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :website_url
  end
end
