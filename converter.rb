require 'nokogiri'
require 'haml'
require 'pry'


# Relative View Paths
class Views
  ROOT_DIR = '../../'
  CONVERTER_DIR = '../'  # relative
  ASSETS_DIR = File.join(CONVERTER_DIR, 'assets')
  CSS_DIR = File.join(ASSETS_DIR, 'css')
  REVEAL_JS_DIR = File.join(ASSETS_DIR, 'reveal.js')
end

# Relative Code Paths
CONTENT_SOURCE_DIR = File.join('./', 'test')

# http://stackoverflow.com/questions/6125265/using-layouts-in-haml-files-independently-of-rails
module HamlSupport
  LAYOUT_FILE = 'views/base/layout.html.haml'

  def self.render_to_file(output_file, given_html)
    rendered_html = Haml::Engine.new(File.read(LAYOUT_FILE)).render(Object.new) do
      given_html
    end

    save_to_file(output_file, rendered_html)
  end

  def self.render(file_path, locals={})
    Haml::Engine.new(File.read(file_path)).render(Object.new, locals)
  end

  def self.save_to_file(output_file, rendered_html)
    File.open("./output/#{output_file || page}.html", 'w+') do |f|
      f.write(rendered_html)
    end
  end

  def self.render_object
    Object.new
  end
end

class SlideDeck < Struct.new(:path)
  TEMPLATE = 'views/slide_deck_templates/slide_deck_base.html.haml'

  def initialize(*args)
    super
    @doc = File.open(path){ |f| Nokogiri::XML(f) }
    @slide_objects = []
  end

  def parse_slides!
    # Search for all headers
    # Get parent, that's the slide node
    # Go through each slide node and extract the contents

    # KEYS: Header, SSC, MSCV, MSCH, TN
    headers_xml = @doc.search('node[@TEXT=Header]')
    slides_xml = headers_xml.map(&:parent)

    slides_xml.each do |slide_xml|
      @slide_objects << Slide.create_from_xml(slide_xml)
    end
  end

  def render
    # @slide_objects << Slide.new('header', 'msch', ['C1', 'C2'], ['TN1', 'TN2'])

    # render a file that loops through the slide decks and renders each file
    HamlSupport.render(TEMPLATE, { slides: @slide_objects })
  end

  def render_to_file
    file_name = File.basename(path, '.mm')
    HamlSupport.render_to_file(file_name, self.render)
  end
end

class Slide < Struct.new(:header, :type, :contents, :teacher_notes)
  SUPPORTED_TYPES = ['ssc', 'mscv', 'msch']

  def self.create_from_xml(slide_xml)
    begin
      slide = Slide.new

      header_xml = slide_xml.search('.//node[@TEXT="Header"]').first.search('.//node').first
      slide.header = header_xml.attribute('TEXT').text

      content_xml = slide_xml.search(".//node[@TEXT='MSCH' or @TEXT='SSC' or @TEXT='MSCV']")
      unless content_xml.empty?
        slide.type = content_xml.attribute('TEXT').text.downcase

        content_xml.search(".//node").each do |content|
          slide.contents << content.attribute('TEXT').text
        end
      end

      teacher_notes_xml = slide_xml.search(".//node[@TEXT='TN']")
      unless teacher_notes_xml.empty?
        teacher_notes_xml.search('.//node').each do |note|
          slide.teacher_notes << note.attribute('TEXT').text
        end
      end

    rescue StandardError => ex
      binding.pry

    end

    slide
  end

  def initialize(*args)
    super
    self.contents ||= []
    self.teacher_notes ||= []
  end

  def render
    if SUPPORTED_TYPES.include?(type)
      HamlSupport.render(slide_template, slide: self)
    else
      puts "Slide failed: #{self.to_h}"
    end
  end

  def slide_template
    raise StandardError.new("Type: #{type} is not supported") unless SUPPORTED_TYPES.include?(type)

    "views/slide_templates/_#{type.downcase}_slide.html.haml"
  end
end



sd = SlideDeck.new(File.join(CONTENT_SOURCE_DIR, 'Week_2.mm'))
sd.parse_slides!
sd.render_to_file




# binding.pry
# puts 'hello'




