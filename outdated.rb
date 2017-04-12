#!/usr/bin/ruby -w

args = Hash[ ARGV.flat_map{|s| s.scan(/--?([^=\s]+)(?:=(\S+))?/) } ]

bundle_outdated_result = %x( bundle outdated ).split("\n").each(&:strip!).select { |line| line.start_with?('*') }
outdated_gems = {}

bundle_outdated_result.each do |line|
  gem_line = line.strip.delete('(').delete(')').delete(',')
  next unless gem_line.start_with? '*'

  gem_line_to_array = gem_line.split

  newest_index = gem_line_to_array.index('newest') + 1
  installed_index = gem_line_to_array.index('installed') + 1
  requested_index = gem_line_to_array.index('requested')
  requested_index += 2 if requested_index

  next if gem_line_to_array[installed_index] == gem_line_to_array[newest_index]

  gem_name = gem_line_to_array[1]

  outdated_gems[gem_name] = { installed: gem_line_to_array[installed_index], newest: gem_line_to_array[newest_index] }
end

warning = {}
danger = {}

outdated_gems.each do |name, versions|
  installed_major, installed_medium, _ = versions[:installed].split('.')
  newest_major, newest_medium, _ = versions[:newest].split('.')

  if newest_major > installed_major
    danger[name] = versions
  elsif newest_medium > installed_medium && args['medium'] == 'yes'
    warning[name] = versions
  end
end

unless danger.empty?
  puts "Major different:"
  danger.each{ |gem, versions| puts "#{gem}: is #{versions[:installed]}, should be #{versions[:newest]}" }
end
puts ''
unless warning.empty?
  puts "Medium different:"
  warning.each{ |gem, versions| puts "#{gem}: is #{versions[:installed]}, should be #{versions[:newest]}" }
end

if args['update'] == 'yes'
  if danger.empty?
    puts "Nothing to update !"
  else
    puts 'Update gems...'

    danger.each do |gem, _|
        puts "Update #{gem}..."
        %x( bundle update #{gem} )
    end
  end
end
