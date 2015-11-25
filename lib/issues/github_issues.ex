defmodule Issues.GithubIssues do
  @user_agent "Elixir pravindahal@gmail.com"
  @github_url Application.get_env(:issues, :github_url)

  require Logger

  def fetch(user, project) do
    Logger.info "Fetching user #{user}'s project #{project}"
    issues_url(user, project)
      |> HTTPotion.get([headers: ["User-Agent": @user_agent]])
      |> handle_response
  end

  @doc """
  Returns a github url based on user and project

  ## Examples
    iex> Issues.GithubIssues.issues_url("elixir-lang", "elixir")
    "#{@github_url}/repos/elixir-lang/elixir/issues"

  """
  def issues_url(user, project) do
    "#{@github_url}/repos/#{user}/#{project}/issues"
  end

  def handle_response(%HTTPotion.Response{status_code: 200, body: body}) do
    Logger.info "Successful response"
    Logger.debug fn -> inspect(body) end
    { :ok, :jsx.decode(body) }
  end
  def handle_response(%HTTPotion.Response{status_code: status, body: body}) do
    Logger.error "Error #{status} returned"
    { :error, :jsx.decode(body) }
  end
end
