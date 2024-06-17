defmodule Platform.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :from, :integer
      add :to, :integer
      add :amount, :integer
      add :request_id, references(:requests, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:from])
    create index(:transactions, [:to])
  end
end
