$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input
  | parse-input
  | enumerate
  | do {|i|
    mut sum = $i | get item
    | each {$in.0} | math sum | $in
    mut index = 0
    while $sum > 0 {
      $sum -= $i | get $index | $in.item | math sum
      $index += 1
    }
    let index = $index
    $i | each {if $in.index < $index {$in} else {update item {$in.0}}}
  } $in
  | inspect
  | each {|i| $i.item
    | enumerate
    | update index {if $in == 0 {$i.index} else {'.'}}
    | each {|i| seq 1 $i.item | each {$i.index}}
    | flatten
  }
  | flatten
  | do {
    mut i = $in
    mut index = 1
    while . in $i { $i | length | print $'($index) - ($in)'
      while ($i | get $index) != . {$index += 1}
      $i = $i | drop | update $index ($i | last)
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
