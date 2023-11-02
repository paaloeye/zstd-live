STDIN.each do |line|
  foo = line.match(/(.*)\.html/)
  puts "<a href=\"#{foo[1]}.html\">#{foo[1]}</a><br>"
end
