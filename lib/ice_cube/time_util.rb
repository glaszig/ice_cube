require 'date'

module IceCube

  module TimeUtil

    LEAP_YEAR_MONTH_DAYS = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    COMMON_YEAR_MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    DAYS = {
      :sunday => 0, :monday => 1, :tuesday => 2, :wednesday => 3,
      :thursday => 4, :friday => 5, :saturday => 6
    }

    MONTHS = {
      :january => 1, :february => 2, :march => 3, :april => 4, :may => 5,
      :june => 6, :july => 7, :august => 8, :september => 9, :october => 10,
      :november => 11, :december => 12
    }

    # Get the beginning of a date
    def self.beginning_of_date(date)
      Time.local(date.year, date.month, date.day, 0, 0, 0)
    end

    # Get the end of a date
    def self.end_of_date(date)
      Time.local(date.year, date.month, date.day, 23, 59, 59)
    end

    # Convert a symbol to a numeric month
    def self.symbol_to_month(sym)
      month = MONTHS[sym]
      raise "No such month: #{sym}" unless month
      month
    end

    # Convert a symbol to a numeric day
    def self.symbol_to_day(sym)
      day = DAYS[sym]
      raise "No such day: #{sym}" unless day
      day
    end

    # Return the count of the number of times wday appears in the month,
    # and which of those time falls on
    def self.which_occurrence_in_month(time, wday)
      first_occurrence = ((7 - Time.utc(time.year, time.month, 1).wday) + time.wday) % 7 + 1
      this_weekday_in_month_count = ((days_in_month(time) - first_occurrence + 1) / 7.0).ceil
      nth_occurrence_of_weekday = (time.mday - first_occurrence) / 7 + 1
      [nth_occurrence_of_weekday, this_weekday_in_month_count]
    end

    # Get the days in the month for +time
    def self.days_in_month(time)
      is_leap?(time.year) ? LEAP_YEAR_MONTH_DAYS[time.month - 1] : COMMON_YEAR_MONTH_DAYS[time.month - 1]
    end
    
    # Number of days in a year
    def self.days_in_year(time)
      is_leap?(time.year) ? 366 : 365
    end

    # Number of days to n years
    def self.days_in_n_years(time, year_distance)
      sum = 0
      next_mark = time
      year_distance.times do
        diy = days_in_year(next_mark)
        sum += diy
        next_mark += diy * ONE_DAY
      end
      sum
    end

    # The number of days in n months
    def self.days_in_n_months(time, month_distance)
      # move to a safe spot in the month to make this computation
      desired_day = time.day
      time -= IceCube::ONE_DAY * (time.day - 27) if time.day >= 28
      # move n months ahead
      sum = 0
      next_mark = time
      month_distance.times do
        dim = days_in_month(next_mark)
        sum += dim
        next_mark += dim * ONE_DAY
      end
      # now we can move to the desired day
      if desired_day > days_in_month(next_mark)
        sum -= desired_day - days_in_month(next_mark)
      end
      sum
    end

    # Given a year, return a boolean indicating whether it is
    # a leap year or not
    def self.is_leap?(year)
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    end

    # A utility class for safely moving time around
    class TimeWrapper

      def initialize(time)
        @time = time
      end

      # Get the wrapper time back
      def to_time
        @time
      end

      # DST-safely add an interval of time to the wrapped time
      def add(type, val)
        type = :day if type == :wday
        @time += case type
        when :year then TimeUtil.days_in_n_years(@time, val) * ONE_DAY
        when :month then TimeUtil.days_in_n_months(@time, val) * ONE_DAY
        when :day  then val * ONE_DAY
        when :hour then val * ONE_HOUR
        when :min  then val * ONE_MINUTE
        when :sec  then val
        end
      end

      # Clear everything below a certain type
      CLEAR_ORDER = [:sec, :min, :hour, :day, :month, :year]
      def clear_below(type)
        type = :day if type == :wday
        CLEAR_ORDER.each do |ptype|
          break if ptype == type
          send(:"clear_#{ptype}")
        end
      end

      private

      def clear_sec
        @time -= @time.sec
      end

      def clear_min
        @time -= (@time.min * ONE_MINUTE)
      end

      def clear_hour
        @time -= (@time.hour * ONE_HOUR)
      end

      # Clear the minute segment (and below) of the wrapper time
      def clear_below_hour
        @time -= (@time.to_i % IceCube::ONE_HOUR)
      end

      # Move to the first of the month, 0 hours
      def clear_day
        @time -= (@time.day - 1) * IceCube::ONE_DAY
      end

      # Clear to january 1st
      def clear_month
        @time -= ONE_DAY
        until @time.month == 12
          @time -= TimeUtil.days_in_month(@time) * ONE_DAY
        end
        @time += ONE_DAY
      end

      def clear_year
      end

    end

  end

end