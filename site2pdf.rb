require 'rubygems'
require 'mechanize'

def usage
  puts <<USAGE
  #{__FILE__} parses a site for you

  Usage:
    #{__FILE__} <site> [<output pdf file>]
    
USAGE
end

def get_uris(site)
  agent = Mechanize.new
  visited = []
  to_visit = [site]
  while !to_visit.empty?
    visited << site
    to_visit.delete(site)
    agent.get(site).links.each do |link|
      href = link.href
      # URI.parse tips at http://stackoverflow.com/q/2719009/49879
      if !URI.parse(href).host and !visited.include?(href) and !to_visit.include?(href)
        to_visit << href
      end
    end
    site = to_visit.shift
  end
  visited
end

site = ARGV[0]

if not site
  usage
  exit
end

if not site =~ /^https?:\/\//
  puts "Neither http or https protocol detected, using http"
  site = "http://" + site
end

if not URI.parse(site)
  puts "#{site} is not a valid URI"
  exit(false)
end

output = ARGV[1] || site.sub(/^http:\/\//, '').sub(/\/$/, '')+".pdf"

uris = get_uris(site)

uris.map! do |uri|
  if uri.start_with?("/")
    site + uri
  end
end

uris.compact!

puts "#{uris.count} uris found, calling wkhtmltopdf.."


