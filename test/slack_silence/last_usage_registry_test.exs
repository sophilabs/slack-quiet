defmodule SlackSilence.LastUsageRegistryTest do
  use ExUnit.Case, async: false

  @user_1_id "user#{System.unique_integer()}"
  @user_2_id "user#{System.unique_integer()}"

  setup do
    # Before each test is run flush the registry
    # so we start the test with a clean slate.
    SlackSilence.LastUsageRegistry.flush()
  end

  test "lookup_last_usage/1 when user hasn't used the command yet" do
    refute SlackSilence.LastUsageRegistry.lookup_last_usage(@user_1_id)
  end

  test "lookup_last_usage/1 when user has used the command before" do
    refute SlackSilence.LastUsageRegistry.lookup_last_usage(@user_1_id)

    naive_datetime = NaiveDateTime.add(NaiveDateTime.utc_now(), -45)
    SlackSilence.LastUsageRegistry.put_last_usage(@user_1_id, naive_datetime)

    assert SlackSilence.LastUsageRegistry.lookup_last_usage(@user_1_id)
  end

  test "can_use_command?/1 when user hasn't used the command yet" do
    assert SlackSilence.LastUsageRegistry.can_use_command?(@user_1_id)
  end

  test "can_use_command?/1 when user has used the command in the last 30 seconds" do
    SlackSilence.LastUsageRegistry.put_last_usage(@user_1_id)

    refute SlackSilence.LastUsageRegistry.can_use_command?(@user_1_id)
  end

  test "can_use_command?/1 when user hasn't used the command in the last 30 seconds" do
    naive_datetime = NaiveDateTime.add(NaiveDateTime.utc_now(), -45)
    SlackSilence.LastUsageRegistry.put_last_usage(@user_1_id, naive_datetime)

    assert SlackSilence.LastUsageRegistry.can_use_command?(@user_1_id)
  end
end
