require "bundler"
Bundler.require :default

Slim::Engine.set_options \
  sort_attrs: false,
  pretty:     false

class Helper
  def render(template)
    Slim::Template.new(File.join(File.expand_path("..", __FILE__), "#{template}.slim")).render(self)
  end
end

def compile_stylesheet
  print "Compiling #{File.basename(ELTFC_STYLESHEET_PATH)}... "
  SassC::Engine.new(File.read(ELTFC_STYLESHEET_PATH), syntax: :sass, style: :compressed, load_paths: [File.expand_path("..", __FILE__)]).render.tap do |css|
    File.open("#{File.basename(ELTFC_STYLESHEET_PATH, ".*")}.css", "w") { |f| f.write(css) }
  end
end

def compile_markup
  print "Compiling #{File.basename(ELTFC_MARKUP_PATH)}... "
  Slim::Template.new(ELTFC_MARKUP_PATH).render(Helper.new).tap do |html|
    File.open("#{File.basename(ELTFC_MARKUP_PATH, ".*")}.html", "w") { |f| f.write(html) }
  end
end

def compile_safe
  yield
  puts "OK"
rescue Exception => e
  puts "Error: #{e}"
  puts "Waiting for files to change..."
end

ELTFC_MARKUP_PATH     = File.expand_path("../eltfc.slim", __FILE__)
ELTFC_STYLESHEET_PATH = File.expand_path("../eltfc.sass", __FILE__)

compile_safe { compile_stylesheet }
compile_safe { compile_markup }

FileWatcher.new("**/*.{slim,sass}", spinner: true).watch do |filepath|
  case File.extname(filepath)
    when ".slim"
      compile_safe { compile_stylesheet }
      compile_safe { compile_markup }
    when ".sass"
      compile_safe { compile_stylesheet }
      compile_safe { compile_markup }
  end
end
