#!/usr/bin/env ruby

fpath = ARGV[0]
fname_rel = ARGV[1]

# make relative link for root of "site" and shared CSS
root_rel_link = '../' * fname_rel.count('/')

puts <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#{fname_rel} - Zig standard library</title>
    <link rel="stylesheet" href="#{root_rel_link}styles.css">
</head>
<body>
</header>

<table><tbody>
<tr><td class="doc">
<h1>
  <a href="#{root_rel_link}std.zig.html">std</a> /
  #{fname_rel}
</h1>
HTML

doc_comment = nil
in_code_block = false

def new_chunk(extra_class='')
  puts '</td></tr>'
  puts "<tr><td class=\"doc #{extra_class}\">"
end

File.read(fpath).each_line do |line|
  # doc comment (/// or //!)
  if line.match?(/^\/{2}[!\/]/)
    comment = line[3..-1]

    if comment.match?(/^\s*$/)
      comment = "<br><br>"
    end

    if doc_comment
      doc_comment += comment
    else
      doc_comment = comment
    end

    next
  end

  # pub const
  if name = line.match(/^pub const (\w+)/)
    if in_code_block
      new_chunk "value"
    end

    puts "<h2>#{name[1]}</h2>"

    if fname = line.match(/@import\("(.*zig)"\)/)
      puts "<a href=\"#{fname[1]}.html\">#{fname[1]}</a>"
    end

    # TODO: DRY
    if doc_comment
      puts "<p>#{doc_comment}</p>"
      doc_comment = nil
    end

    in_code_block = false
  end

  # pub fn
  if name = line.match(/^pub( inline)? fn (\w+)/)
    if in_code_block
      new_chunk
    end

    puts "<h2>#{name[2]}()</h2>"

    # TODO: DRY
    if doc_comment
      puts "<p>#{doc_comment}</p>"
      doc_comment = nil
    end

    in_code_block = false
  end

  # struct/enum method pub fn
  if name = line.match(/^\s+pub( inline)? fn (\w+)/)
    if in_code_block
      new_chunk 'method'
    end

    puts "<h2>#{name[2]}</h2>"

    # TODO: DRY
    if doc_comment
      puts "<p>#{doc_comment}</p>"
      doc_comment = nil
    end

    in_code_block = false
  end

  # everything else is code!
  if !in_code_block
    in_code_block = true

    if doc_comment
      puts "<p>#{doc_comment}</p>"
      doc_comment = nil
    end

    puts '</td>' #end the doc cell
    puts '<td class="code">'
  end

  puts line

end

puts <<HTML
</td></tr>
</tbody></table>
</body>
</html>
HTML
