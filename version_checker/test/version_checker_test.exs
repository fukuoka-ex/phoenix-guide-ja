defmodule VersionCheckerTest do
  use ExUnit.Case
  doctest VersionChecker

  test "greets the world" do
    assert VersionChecker.hello() == :world
  end
end
