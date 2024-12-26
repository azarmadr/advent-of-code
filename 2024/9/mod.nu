$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input
  | parse-input
  | enumerate
  | do {|i|
    return $i
    mut sum = $i | get item
    | each {$in.0} | math sum | $in // 2 | inspect
    $i
  } $in
  | each {|i| $i.item
    | enumerate
    | update index {if $in == 0 {$i.index} else {'.'}}
    | each {|i| seq 1 $i.item | each {$i.index}}
    | flatten
  }
  | flatten
  | do {
    mut i = $in
    mut index = 0
    while . in $i {
      let last = $i | last
      # $i | str join | inspect | str length | print
      $i | length | print
      let index = $i | enumerate
      | skip until {|i| $i.item == .} | $in.0.index
      $i = $i | drop | update $index $last
      mut last = $i | last
      while $last == . {
        $i = $i | drop
        $last = $i | last
      }
    }
    $i
  }
  | enumerate
  | each {$in.index * $in.item}
  | math sum
  | inspect
}

def "main gold" [input: path, ] {
  open $input | parse-input
}

# solution for day 2024/5
def main [rest] {
  main silver $rest | print 'Silver:>' $in
  return
  main gold $rest | print 'Gold:>' $in
}

def parse-input [] {
  split chars
  | each {try {into int}}
  | chunks 2
}
