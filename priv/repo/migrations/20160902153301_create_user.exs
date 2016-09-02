defmodule MfaMockup.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :msisdn, :string

      timestamps
    end

  end
end
