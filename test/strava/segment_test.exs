defmodule Strava.SegmentTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start
  end

  test "retrieve segment" do
    use_cassette "segment/retrieve#229781" do
      segment = Strava.Segment.retrieve(229781)

      assert segment != nil
      assert segment.name == "Hawk Hill"
      assert segment.created_at == ~N[2009-09-21 20:29:41]
      assert segment.map.id == "s229781"
      assert segment.map.polyline == "}g|eFnpqjVl@En@Md@HbAd@d@^h@Xx@VbARjBDh@OPQf@w@d@k@XKXDFPH\\EbGT`AV`@v@|@NTNb@?XOb@cAxAWLuE@eAFMBoAv@eBt@q@b@}@tAeAt@i@dAC`AFZj@dB?~@[h@MbAVn@b@b@\\d@Eh@Qb@_@d@eB|@c@h@WfBK|AMpA?VF\\\\t@f@t@h@j@|@b@hCb@b@XTd@Bl@GtA?jAL`ALp@Tr@RXd@Rx@Pn@^Zh@Tx@Zf@`@FTCzDy@f@Yx@m@n@Op@VJr@"
    end
  end

  test "list segment efforts" do
    use_cassette "segment/list_efforts#229781" do
      segment_efforts = Strava.Segment.list_efforts(229781)

      assert segment_efforts != nil
      assert length(segment_efforts) == 30

      first_effort = hd(segment_efforts)
      assert first_effort.id == 1323785488
      assert first_effort.name == "Hawk Hill"

      assert first_effort.start_date == ~N[1970-01-01 00:29:39]
      assert first_effort.start_date_local == ~N[1969-12-31 16:29:39]
    end
  end

  test "list segment efforts, filtered by athlete" do
    use_cassette "segment/list_efforts#229781.athlete", match_requests_on: [:query] do
      segment_efforts = Strava.Segment.list_efforts(229781, %{athlete_id: 5287})

      assert segment_efforts != nil

      Enum.each(segment_efforts, fn(segment_effort) ->
        assert segment_effort.name == "Hawk Hill"
        assert segment_effort.athlete.id == 5287
      end)
    end
  end

  test "list segment efforts, filtered by start and end dates" do
    use_cassette "segment/list_efforts#229781.date", match_requests_on: [:query] do
      segment_efforts = Strava.Segment.list_efforts(229781, %{
        start_date_local: "2014-01-01T00:00:00Z",
        end_date_local: "2014-01-01T23:59:59Z"
      })

      assert segment_efforts != nil

      Enum.each(segment_efforts, fn(segment_effort) ->
        assert segment_effort.name == "Hawk Hill"

        assert segment_effort.start_date.year == 2014
        assert segment_effort.start_date.month == 1
        assert segment_effort.start_date.day == 1

        assert segment_effort.start_date_local.year == 2014
        assert segment_effort.start_date_local.month == 1
        assert segment_effort.start_date_local.day == 1
      end)
    end
  end

  test "stream segment efforts, filtered by start and end dates" do
    use_cassette "segment/stream_efforts#229781.date", match_requests_on: [:query] do
      segment_efforts = Strava.Segment.stream_efforts(229781, %{
        start_date_local: "2014-01-01T00:00:00Z",
        end_date_local: "2014-01-01T23:59:59Z"
      })
      |> Stream.take(5)
      |> Enum.to_list

      assert length(segment_efforts) == 5

      Enum.each(segment_efforts, fn(segment_effort) ->
        assert segment_effort.name == "Hawk Hill"

        assert segment_effort.start_date.year == 2014
        assert segment_effort.start_date.month == 1
        assert segment_effort.start_date.day == 1

        assert segment_effort.start_date_local.year == 2014
        assert segment_effort.start_date_local.month == 1
        assert segment_effort.start_date_local.day == 1
      end)
    end
  end

  test "stream segment efforts, filtered by start and end dates, for multiple pages" do
    use_cassette "segment/stream_efforts#229781.date2", match_requests_on: [:query] do
      segment_efforts = Strava.Segment.stream_efforts(229781, %{
        start_date_local: "2016-01-01T00:00:00Z",
        end_date_local: "2016-01-02T23:59:59Z"
      })
      |> Enum.to_list

      assert length(segment_efforts) > 200

      Enum.each(segment_efforts, fn(segment_effort) ->
        assert segment_effort.name == "Hawk Hill"

        assert segment_effort.start_date_local.year == 2016
        assert segment_effort.start_date_local.month == 1
      end)
    end
  end

  describe "starred segments" do
    test "list starred segments" do
      use_cassette "segment/list_starred" do
        starred_segments = Strava.Segment.list_starred()

        assert starred_segments != nil
        assert length(starred_segments) > 0

        first_segment = hd(starred_segments)
        assert first_segment.name != ""
        assert first_segment.id > 0
      end
    end

    test "paginate starred segments" do
      use_cassette "segment/paginate_starred", match_requests_on: [:query] do
        starred_segments = Strava.Segment.paginate_starred(%Strava.Pagination{per_page: 5, page: 1})

        assert starred_segments != nil
        assert length(starred_segments) <= 5

        first_segment = hd(starred_segments)
        assert first_segment.name != ""
        assert first_segment.id > 0
      end
    end

    test "stream starred segments" do
      use_cassette "segment/stream_starred", match_requests_on: [:query] do
        starred_segments = Strava.Segment.stream_starred() |> Enum.to_list

        assert starred_segments != nil
        assert length(starred_segments) > 0

        first_segment = hd(starred_segments)
        assert first_segment.name != ""
        assert first_segment.id > 0
      end
    end
  end

  describe "Segment leaderboards" do
    test "leaderboard" do
      use_cassette "segment/leaderboards", match_requests_on: [:query] do
        leaderboard = Strava.Segment.leaderboard(229781)

        assert leaderboard != nil
        assert leaderboard.entry_count > 0
        assert length(leaderboard.entries) > 0
      end
    end
  end

  describe "exploring segments" do
    test "explore" do
      use_cassette "segment/explore", match_requests_on: [:query] do
        explored_segments = Strava.Segment.explore([37.821362,-122.505373,37.842038,-122.465977])

        assert explored_segments != nil
        assert length(explored_segments) > 0

        first_segment = hd(explored_segments)
        assert first_segment.name != ""
        assert first_segment.id > 0
        assert first_segment.average_grade != nil
        assert first_segment.average_grade > 0
      end
    end
  end
end
