Bundler.require

require 'uri'
require 'time'

class Asa10
  class Duration
    attr_reader :dudataion, :start_at, :end_at
    def initialize(duration)
      @duration = duration
      @start_at, @end_at = duration.split(/～/).map{|text|
        Time.parse text
      }
      @end_at += 3600*24-1      # end of day
    end

    def inspect
      "#{ start_at.strftime('%Y-%m-%d') } ~ #{ end_at.strftime('%Y-%m-%d') }"
    end
  end

  class Movie
    attr_reader :title, :uri, :duration

    def initialize(title, uri, duration)
      @title = title
      @uri = uri
      @duration = duration
    end
  end

  class ICalWriter
    def write series
      cal = Icalendar::Calendar.new

      series.each{|movie|
        day = movie.duration.start_at
        while day < movie.duration.end_at
          show_start = Time.new(day.year, day.month, day.day, 10, 0, 0, 0)
          show_end   = Time.new(day.year, day.month, day.day, 12, 0, 0, 0)
          if show_start.saturday? || show_start.sunday?
            cal.event { |e|
              e.dtstart     = Icalendar::Values::DateTime.new(show_start.to_datetime)
              e.dtend       = Icalendar::Values::DateTime.new(show_end.to_datetime)
              e.summary     = movie.title
              e.description = movie.uri.to_s
            }
          end

          day += 3600*24
        end
      }

      cal.publish
      cal.to_ical
    end
  end

  def load source
    @source = source
    @dom = Nokogiri @source
  end

  def parse
    @serieses = {a: [], b: []}

    table = @dom.at '#scheList-all tbody'
    table.search('tr').to_a.delete_if{|tr|
      collection_title? tr
    }.each{|tr|
      a, b = parse_row tr
      @serieses[:a] << a
      @serieses[:b] << b
    }
  end

  def write name
    w = ICalWriter.new
    w.write series name
  end

  def series name
    @serieses[name]
  end

  def root
    URI.parse 'http://asa10.eiga.com/2016/theater/all/'
  end

  def collection_title? tr
    tr.at '.ssTtl'
  end

  def parse_row tr
    date = tr.at '.date'
    duration = Duration.new date.text
    tr.search('a').to_a.map{|link|
      title = link.text
      uri = root + link['href']
      Movie.new title, uri, duration
    }
  end

end

a = Asa10.new
a.load(ARGF.read)
a.parse
puts a.write :a
