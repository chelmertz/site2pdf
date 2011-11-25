require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

def usage
  usage <<USAGE
  #{__FILE__} parses a site for you

  Usage:
    #{__FILE__} <site> [<output pdf file>]
  
  Requirements:
    - wkhtmltopdf (compiled with qt for support for multiple pages into one pdf)
      source for mac found here: http://www.downloadplex.com/Mac/Network-Internet/Search-Lookup-Tools/wkhtmltopdf-for-mac_257814.html
    
USAGE
  puts usage
end

# taken from http://stackoverflow.com/q/5471032/49879
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = "#{path}/#{cmd}#{ext}"
      return exe if File.executable? exe
    }
  end
  return nil
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

# @todo use http://ruby-doc.org/stdlib-1.9.3/libdoc/optparse/rdoc/OptionParser.html
site = ARGV[0]

if not site
  usage
  exit
end

if not which("wkhtmltopdf")
  puts "Must have wkhtmltopdf installed. Google and it will be yours in one minute"
  exit(false)
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

system "wkhtmltopdf #{uris.join(' ')} #{output}"
if not $?
  puts "Error, couldn't generate a pdf "
else
  puts "wkhtmltopdf is done, output file is now at #{output}"
end
