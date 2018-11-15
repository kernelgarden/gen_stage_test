defmodule GenStageTestTest do
  use ExUnit.Case
  doctest GenStageTest

  test "greets the world" do
    assert GenStageTest.hello() == :world
  end
end
