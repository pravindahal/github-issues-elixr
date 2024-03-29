defmodule Issues.CLI do
  @default_count 4
  @moduledoc """
  Handle the command line parsing and the dispatch to the various functions that
  end up generating a table of the last _n_ issues in a github project
  """

  def main(argv) do
    argv
      |> parse_args
      |> process
  end

  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [ count | #{@default_count}]
    """
    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
      |> decode_response
      |> convert_to_list_of_hashdicts
      |> sort_into_ascending_order
      |> Enum.take(count)
      |> format_issues
  end

  def decode_response({:ok, body}) do
    body
  end
  def decode_response({:error, error}) do
    {_, message} = List.keyfind(error, "message" , 0)
    IO.puts "Error fetching from Github: #{message}"
    System.halt(2)
  end

  def convert_to_list_of_hashdicts(list) do
    list
      |> Enum.map(&Enum.into(&1, Map.new))
  end

  def sort_into_ascending_order(list_of_issues) do
    Enum.sort list_of_issues, fn i1, i2 -> i1[ "created_at" ] <= i2[ "created_at" ] end
  end

  def _format_issues([], formatted), do: IO.puts formatted
  def _format_issues([head | tail], formatted) do
    _format_issues(tail, formatted <> Integer.to_string(head["number"]) <> "\t|" <> head["created_at"] <> "\t|" <> head["title"] <> "\n")
  end
  def format_issues(data), do: _format_issues(data, "#\t|created_at\t\t|title\n---------------------------------------------------------------------------------\n")

  @doc """
  `argv` can be -h or --help which returns :help.
  Otherwise it is a github user name, project name, and (optionally) the number
  of entries to format.
  Return a tuple of `{user, project, count}`, or `:help` if help was given.
  """

  def parse_args(argv) do
    parse = OptionParser.parse(argv,
      switches: [ help: :boolean],
      aliases: [h: :help]
    )
    case parse do
      { [help: true], _, _} -> :help
      { _, [ user, project, count ], _ } -> { user, project, String.to_integer(count) }
      { _, [ user, project ],        _ } -> { user, project, @default_count }
      _ -> :help
    end
  end
end
