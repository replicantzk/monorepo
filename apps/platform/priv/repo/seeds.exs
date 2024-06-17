# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Platform.Repo.insert!(%Platform.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Platform.Accounts
alias Platform.API

token1 = "8139b4dd-18bf-48f3-8187-1dc423ee12a6"
token2 = "30faf101-70d2-412c-a5a5-c7cbe672a04f"

user1_attrs = %{
  email: "test@test.com",
  password: "testtesttest",
  rate_limit: 1_000
}

user2_attrs = %{
  user1_attrs
  | email: "test2@test.com"
}

if is_nil(Accounts.get_user_by_email(user1_attrs.email)) do
  {:ok, user1} = Accounts.register_user(user1_attrs)
  Accounts.assign_user_token(user1, token1)
  API.transfer_credits(1_000_000, user1.id)
end

if is_nil(Accounts.get_user_by_email(user2_attrs.email)) do
  {:ok, user2} = Accounts.register_user(user2_attrs)
  Accounts.assign_user_token(user2, token2)
  API.transfer_credits(100_000, user2.id)
end
