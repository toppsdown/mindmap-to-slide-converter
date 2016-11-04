require 'fileutils'
require 'pry'

WEB_DIR = '../toppy42.github.com'
SLIDE_ROOT = File.join(WEB_DIR, 'slide_nav')
SLIDES_DIR = File.join(SLIDE_ROOT, 'slides')

# Copy files to web dir
FileUtils.cp_r('./assets', SLIDE_ROOT)
FileUtils.cp_r('./output/.', SLIDES_DIR)

# push changes
Dir.chdir(WEB_DIR) do
  `git add .`
  `git commit -m "deploy slides"`
  `git push`
end
