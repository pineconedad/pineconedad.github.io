#!/usr/bin/env ruby

require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DATA_DIR = File.join(ROOT, "_data")
PUBLICATION_IMAGE_TYPES = %w[.png .jpg .jpeg .webp .gif .svg].freeze
PROFILE_IMAGE_TYPES = %w[.png .jpg .jpeg .webp].freeze

DATA_HEADERS = {
  "publications.yml" => "# image accepts PNG, JPG/JPEG, WebP, GIF, or SVG. Do not use a PDF as an image.\n",
  "projects.yml" => "# image accepts PNG, JPG/JPEG, WebP, GIF, or SVG. Do not use a PDF as an image.\n",
  "profile.yml" => "# photo accepts PNG, JPG/JPEG, or WebP. Do not use a PDF or GIF as a profile photo.\n"
}.freeze

def fail_with(message)
  warn "Error: #{message}"
  exit 1
end

def ask(label, default: nil, required: false)
  loop do
    default_text = default.nil? || default.to_s.empty? ? "" : " [#{default}]"
    print "#{label}#{default_text}: "
    input = $stdin.gets
    fail_with("Input ended before the entry was complete.") unless input

    value = input.strip
    value = default if value.empty? && !default.nil?
    return value unless required && (value.nil? || value.to_s.empty?)

    puts "This field is required."
  end
end

def ask_update(label, current)
  current_text = current.nil? || current.to_s.empty? ? "empty" : current
  print "#{label} [#{current_text}; Enter keeps it, type remove to clear]: "
  input = $stdin.gets
  fail_with("Input ended before the update was complete.") unless input

  value = input.strip
  return current if value.empty?
  return nil if value.casecmp("remove").zero?

  value
end

def slugify(value)
  slug = value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
  slug.empty? ? "entry" : slug
end

def normalized_path(value)
  path = value.strip
  path = path[1...-1] if path.length > 1 && %w[' "].include?(path[0]) && path[-1] == path[0]
  File.expand_path(path.gsub("\\ ", " "))
end

def copy_image(kind, slug, current: nil)
  profile = kind == "profile"
  formats = profile ? PROFILE_IMAGE_TYPES : PUBLICATION_IMAGE_TYPES
  format_names = formats.map { |extension| extension.delete_prefix(".").upcase }.join(", ")
  current_text = current.nil? || current.empty? ? "none" : current
  action = profile ? "Enter keeps #{current_text}; type remove to clear" : "Enter skips the image"

  print "Image file to copy (#{format_names}; #{action}): "
  input = $stdin.gets
  fail_with("Input ended before the image selection was complete.") unless input

  value = input.strip
  return current if value.empty?
  return nil if profile && value.casecmp("remove").zero?

  source = normalized_path(value)
  fail_with("Image file not found: #{source}") unless File.file?(source)

  extension = File.extname(source).downcase
  if extension == ".pdf"
    fail_with("PDF files cannot be used as images. Export the figure to #{format_names} first.")
  end
  fail_with("Unsupported image format #{extension}. Use #{format_names}.") unless formats.include?(extension)

  folder = File.join(ROOT, "assets", "images", kind)
  FileUtils.mkdir_p(folder)
  destination = File.join(folder, "#{slug}#{extension}")

  unless File.expand_path(source) == File.expand_path(destination)
    if File.exist?(destination)
      overwrite = ask("#{File.basename(destination)} exists. Overwrite it? (y/N)", default: "N")
      fail_with("Image was not copied.") unless overwrite.casecmp("y").zero?
    end
    FileUtils.cp(source, destination)
  end

  "/assets/images/#{kind}/#{File.basename(destination)}"
end

def load_yaml(path, fallback)
  return fallback unless File.exist?(path)

  YAML.load_file(path) || fallback
rescue Psych::SyntaxError => error
  fail_with("Cannot read #{path}: #{error.message}")
end

def yaml_without_marker(value)
  YAML.dump(value).sub(/\A---\s*\n/, "")
end

def append_entry(filename, entry)
  path = File.join(DATA_DIR, filename)
  entries = load_yaml(path, [])
  fail_with("#{path} must contain a YAML list.") unless entries.is_a?(Array)

  existing = File.exist?(path) ? File.read(path) : DATA_HEADERS.fetch(filename)
  block = yaml_without_marker([entry]).rstrip
  content = if entries.empty? && existing.match?(/^\[\]\s*$/)
              existing.sub(/^\[\]\s*$/, block)
            else
              "#{existing.rstrip}\n#{block}\n"
            end
  File.write(path, content.end_with?("\n") ? content : "#{content}\n")
  puts "Updated #{path.delete_prefix("#{ROOT}/")}."
  puts "Review the changes, then commit and push them to publish the update."
end

def update_profile
  path = File.join(DATA_DIR, "profile.yml")
  profile = load_yaml(path, {})
  fail_with("#{path} must contain a YAML map.") unless profile.is_a?(Hash)

  name = ask("Name", default: profile["name"], required: true)
  bio = ask("Description", default: profile["bio"], required: true)
  photo = copy_image("profile", slugify(name), current: profile["photo"])
  photo_alt = photo ? ask("Profile photo alt text", default: profile["photo_alt"] || name, required: true) : nil

  current_links = Array(profile["links"]).each_with_object({}) do |link, result|
    result[link["label"]] = link["url"]
  end
  labels = %w[Email GitHub LinkedIn CV]
  links = labels.each_with_object([]) do |label, result|
    url = ask_update("#{label} URL", current_links[label])
    result << { "label" => label, "url" => url } if url && !url.empty?
  end

  known_labels = labels.each_with_object({}) { |label, result| result[label] = true }
  custom_links = Array(profile["links"]).reject { |link| known_labels[link["label"]] }
  updated = {
    "name" => name,
    "bio" => bio,
    "photo" => photo,
    "photo_alt" => photo_alt,
    "links" => links + custom_links
  }

  File.write(path, DATA_HEADERS.fetch("profile.yml") + yaml_without_marker(updated))
  puts "Updated _data/profile.yml."
end

def add_publication
  title = ask("Paper title", required: true)
  slug = slugify(ask("Image filename slug", default: slugify(title), required: true))
  author_names = ask("Authors, separated by commas", required: true).split(",").map(&:strip).reject(&:empty?)
  fail_with("At least one author is required.") if author_names.empty?

  year_text = ask("Publication year", required: true)
  fail_with("Publication year must contain four digits.") unless year_text.match?(/\A\d{4}\z/)

  image = copy_image("publications", slug)
  entry = {
    "title" => title,
    "authors" => author_names.map do |name|
      author = { "name" => name }
      author["self"] = true if name.casecmp("Wardat Shams Iqbal").zero?
      author
    end,
    "venue" => ask("Venue", required: true),
    "year" => year_text.to_i,
    "paper" => ask("Paper URL"),
    "arxiv" => ask("arXiv URL"),
    "code" => ask("Code URL"),
    "website" => ask("Project website URL"),
    "summary" => ask("Short summary"),
    "image" => image,
    "image_alt" => image ? ask("Image alt text", required: true) : nil
  }.reject { |_, value| value.nil? || value == "" }

  append_entry("publications.yml", entry)
end

def add_project
  title = ask("Project title", required: true)
  slug = slugify(ask("Image filename slug", default: slugify(title), required: true))
  image = copy_image("projects", slug)
  entry = {
    "title" => title,
    "dates" => ask("Dates"),
    "description" => ask("Description", required: true),
    "technologies" => ask("Technologies"),
    "website" => ask("Website URL"),
    "code" => ask("Code URL"),
    "paper" => ask("Paper URL"),
    "image" => image,
    "image_alt" => image ? ask("Image alt text", required: true) : nil
  }.reject { |_, value| value.nil? || value == "" }

  append_entry("projects.yml", entry)
end

def print_help
  puts <<~HELP
    Usage: ruby tools/manage_site.rb [publication|project|profile]

    publication  Add a paper and optionally copy its image.
    project      Add a project and optionally copy its image.
    profile      Update the introduction, links, and profile photo.

    Run without an argument to choose from a menu.
  HELP
end

command = ARGV.shift
if %w[-h --help help].include?(command)
  print_help
  exit
end

unless command
  puts "1. Add a publication"
  puts "2. Add a project"
  puts "3. Update the profile"
  choice = ask("Choose an action", required: true)
  command = { "1" => "publication", "2" => "project", "3" => "profile" }[choice]
end

case command
when "publication"
  add_publication
when "project"
  add_project
when "profile"
  update_profile
else
  print_help
  fail_with("Choose publication, project, or profile.")
end
