$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  let onsen = open $input | parse-input
  let towels = $onsen.towels

  mut count = 0
  mut acc = []
  for design in $onsen.design {
    $acc = [$design] | uniq -c 
    loop {
      $acc = $acc | remove-towels-from-designs $towels
      if ($acc | is-empty) {break}
      if ($acc | get value | any {$in in $towels}) { $count += 1; break}
    }

    # very slow for input
    if false {
      mut acc = ['']
      loop {
        $acc = $acc
          | each {|i| $towels | each {$i + $in}}
          | flatten
          | filter {|i| $design | str starts-with $i}
          if ($acc | is-empty) {return false} else if ($acc | any {$in == $design}) {return true}
      }
    }
  }
  $count
}

def "main gold" [input: path, --count(-c): int] {
  let onsen = open $input | parse-input
  let towels = $onsen.towels

  mut acc = $onsen.design | if $count == null {take $count} else {$in} | uniq -c
  mut count = 0
  loop {
    $acc = $acc | remove-towels-from-designs $towels | inspect
    if ($acc | is-empty) {return $count}
    for it in ($acc | where value == ''| get count) {$count += $it}
    $acc = $acc | where value != ''
  }
}

def remove-towels-from-designs [towels] {
  par-each {|design| $towels
    | filter {|i| $design.value | str starts-with $i}
    | each {|towel| $design | update value {str replace $towel ''}}
  }
  | flatten
  | if $in != [] {
    group-by value --to-table
    | rename value count
    | update count { get count | math sum}
  } else {[]}
}

# solution for day 2024/5
def main [rest] {
  main silver $rest | print $'Silver:>($in)'
  main gold $rest | print $'Gold:> ($in)'
}

def parse-input [] {
  lines
  | {towels: $in.0 design: ($in | skip 2)}
  | update towels {split row ', '}
}
