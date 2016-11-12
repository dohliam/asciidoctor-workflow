#!/usr/bin/ruby
# encoding: utf-8

# asciidoctor-workflow: Create rich css-enabled html and pdfs from Asciidoctor documents

gem 'asciidoctor', '>1.5'

require 'asciidoctor'
require 'erb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: asciidoctor_workflow.rb [options] [filename]"

  opts.on("-f", "--fixes", "Fixes some common display problems with pdfs") { options[:fixes] = true }
  opts.on("-o", "--output NAME", "Basename of output file (by default same as input file)") { |v| options[:output] = v }
  opts.on("-p", "--pdf", "Create pdf instead of html") { options[:pdf] = true }
  opts.on("-s", "--stylesheet NAME", "Specify name of stylesheet to use instead of CSS switcher") { |v| options[:stylesheet] = v }

end.parse!

f = ""
if ARGV[0]
  f = ARGV[0]
else
  abort("  No asciidoctor file specified")
end

basename = File.basename(f, File.extname(f))
html_name = basename + ".html"
content = File.read(f)
script_dir = File.expand_path(File.dirname(__FILE__)) + "/"

$title = basename.capitalize
if content.match(/^= (.*?)$/)
  $title = Regexp::last_match[1]
end

$switcher = '    <script src="https://darshandsoni.com/asciidoctor-skins/switcher.js" type="text/javascript"></script>'

fixes = ""
if options[:fixes]
  fixes = "      h1,h2,h3,h4 {\n        letter-spacing: 0rem;\n      }\n"
end

$css = ""
if options[:stylesheet]
  name = options[:stylesheet]
  $switcher = ""
  padding = "\n    <style type=\"text/css\">\n      body {\n        padding-left: 24px;\n      }\n"
  close_tag = "    </style>\n"
  $css = '    <link href="https://darshandsoni.com/asciidoctor-skins/css/' + name + '.css" type="text/css" rel="stylesheet">' + padding + fixes + close_tag
end

html = Asciidoctor.convert content, header_footer: true, safe: :safe
# fix indentation:
$content = html.gsub(/^/, "      ")
# trim default css:
$content = $content.gsub(/<\!DOCTYPE html>.*<\/head>\n/m, "")
# remove trailing element tags:
$content = $content.gsub(/<\/body>\n<\/html>/, "")

output = ERB.new(File.read(script_dir + "template.rhtml")).result

File.open(html_name, "w") { |o| o << output }

outfile = basename
if options[:output]
  outfile = options[:output]
end

if options[:pdf]
  `wkhtmltopdf '#{basename}.html' '#{outfile}.pdf'`
end
