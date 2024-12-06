$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
def "main silver" [input: path, ] {
  open $input | lines | $in.6 | split chars | enumerate |inspect | find '^' | print
  let start = open $input | parse-input
  $start | print 'start' $in
  mut pos = {}
  | insert row ($start | enumerate | find '^' | get 0.index)
  | insert col {|i| $start | get $i.row | transpose index value| find '^' | get 0.index}
  | insert dir '^'
  $pos | print
  let start = $start| update cells -c [$pos.col] {if $in == '^' {'X'} else {$in}}
  match $pos.dir {
    '^' => {$pos.row -= 1}
    'v' => {$pos.row += 1}
    '>' => {$pos.col += 1}
    '<' => {$pos.col -= 1}
  }
  $start | update cells -c [$pos.col] {if $in == '^' {'X'} else {$in}} | print
  $pos
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
  | rename -b {str replace 'column' ''}
}
