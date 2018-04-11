module Bar
  puts "inside #{File.basename __FILE__}"
  puts 'Starting some stuff...'
  sleep 4
  puts 'Finished some stuff...'
end

def Bar.cats
  puts "running Bar::cats!"
end