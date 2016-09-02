ExUnit.start

Mix.Task.run "ecto.create", ~w(-r MfaMockup.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r MfaMockup.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(MfaMockup.Repo)

