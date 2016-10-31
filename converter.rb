require 'nokogiri'
require 'haml'
require 'pry'

doc = File.open('./test/Week_1.xml') { |f| Nokogiri::XML(f) }

class Slide < Struct.new(:header, :type, :contents, :teacher_notes)
  def initialize(*args)
    super
    self.contents ||= []
    self.teacher_notes ||= []
  end

  def generate
    render_haml
  end

  private
  def render_haml
    engine = Haml::Engine.new('./views/ssc_slide.html.haml')
  end
end


# Search for all headers
# Get parent, that's the slide node
# Go through each slide node and extract the


# KEYS: Header, SSC, MSCV, MSCH, TN
headers_xml = doc.search('node[TEXT=Header]')
slides_xml = headers_xml.map(&:parent)

slide_objects = []
i = 0

slides_xml[1..-1].each do |slide_xml|
  slide = Slide.new

  header_xml = slide_xml.search('.//node[@TEXT="Header"]').first.search('.//node').first
  slide.header = header_xml.attribute('TEXT').text

  content_xml = slide_xml.search(".//node[@TEXT='MSCH' or @TEXT='SSC' or @TEXT='MSCV']")
  unless content_xml.empty?
    slide.type = content_xml.attribute('TEXT').text

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

  slide_objects << slide
end




binding.pry
puts 'hello'




