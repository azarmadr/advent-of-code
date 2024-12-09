$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def update-pos [] {
  let map = $in
  let pos = {}
  | insert row ($map | enumerate | find -r '[\^>v<]' | get 0.index)
  | insert col {|i| $map | get $i.row | enumerate | find -r '[\^>v<]' | get 0.index}
  | insert dir {|i| $map | get $i.row | get $i.col}
  let map = $map | update $pos.row {update $pos.col ({
    ^ : 'k', >: 'l', <: 'h', v: 'j'
  } | get $pos.dir)}
  let next_pos = $pos | update (match $pos.dir {
    '^' => 'row'
    'v' => 'row'
    '>' => 'col'
    '<' => 'col'}) {$in + (match $pos.dir {
    '^' => -1
    'v' => 1
    '>' => 1
    '<' => -1})}
  if ($map | get $next_pos.row | get $next_pos.col | $in != '#') {
    $map | update $next_pos.row {update $next_pos.col $next_pos.dir}
  } else {
    $map | update $pos.row {update $pos.col (match $pos.dir {
      '^' => '>'
      '>' => 'v'
      'v' => '<'
      '<' => '^'
      })}
  }
}

def "main silver" [input: path, ] {
  mut map = open $input | parse-input
  loop {
    try {
      $map = $map | update-pos
    } catch {|e|
      print $e
      break 
    }
  }
  $map | each {str join ''} | str join "\n" | inspect | parse -r '([hjkl])' | length
}

def "main gold" [input: path, ] {
  open $input | parse-input
}

# solution for day 2024/5
def main [rest] {
  main silver $rest | print 'Silver' $in
  return
  main gold $rest | print 'Gold' $in
}

def parse-input [] {
  lines
  | each { parse -r '(.)' | rotate --ccw }
  | flatten
  | reject column0
  | each {values}
}
