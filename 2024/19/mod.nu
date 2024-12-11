$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def remove-towels-from-designs [design] {
  each {|i| $design | each {if ($in | str starts-with $i) or ($in == '') {str replace -r $'^("(" + $i))+' ''}}}
  | flatten
  | uniq -c
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  let onsen = open $input | parse-input
  let towels = $onsen.towels

  $onsen.design | par-each {|design|
    mut acc = [$design]
    loop {
      $acc = $towels | remove-towels-from-designs $acc | get value
      if ($acc | is-empty) {return false}
      if ($acc | any {$in == ''}) {return true}
    }

    if false { # very slow for input
    mut acc = ['']
    loop {
      $acc = $acc
        | each {|i| $towels | each {$i + $in}}
        | flatten
        | filter {|i| $design | str starts-with $i}
        # inspect
        if ($acc | is-empty) {return false} else if ($acc | any {$in == $design}) {return true}
    }
    }
  }
  | filter {$in}
  | length
}

def "main gold" [input: path, ] {
  let onsen = open $input | parse-input
  let towels = $onsen.towels

  $onsen.design | par-each {|design|
    mut acc = [$design]
    loop {
      $acc = $towels | remove-towels-from-designs $acc | get value
      if ($acc | is-empty) {return false}
      if ($acc | any {$in == ''}) {return true}
    }
  }
  | filter {$in}
  | length
}

# solution for day 2024/5
def main [rest] {
  main gold $rest | print $'Gold:> ($in)'
  return
  main silver $rest | print 'Silver:>' $in
}

def parse-input [] {
  lines
  | {towels: $in.0 design: ($in | skip 2)}
  | update towels {split row ', '}
}
