defmodule MfaMockup.UserTest do
  use MfaMockup.ModelCase

  alias MfaMockup.User

  @valid_attrs %{email: "some content", msisdn: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
