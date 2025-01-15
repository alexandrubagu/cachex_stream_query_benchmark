defmodule CachexBenchTest do
  use ExUnit.Case
  doctest CachexBench

  test "greets the world" do
    assert CachexBench.hello() == :world
  end
end
