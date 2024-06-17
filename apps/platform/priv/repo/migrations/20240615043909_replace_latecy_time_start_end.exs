defmodule Platform.Repo.Migrations.ReplaceLatecyTimeStartEnd do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      remove :latency
      add :time_start, :utc_datetime
      add :time_end, :utc_datetime
    end
  end
end
