$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def intersection [rhs] {
  filter {|i| $i in $rhs}
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input
  | next-level-lan-party
  | filter {any {str starts-with t}}
  | length
  | print $'Silver:>($in)'
}

def "main gold" [input: path, ] {
  mut conn = open $input | parse-input
  for _ in 0..5 {
      $conn | enumerate | inspect
      $conn = $conn | next-level-lan-party
      if ($conn | length) < 2 { break}
    }
  $conn
  | flatten
  | str join ','
  | print $'Gold:>($in)'
}

# solution for day 2024/5
def main [rest] {
  main gold $rest
  return
  main silver $rest
}

def next-level-lan-party [] {
  let conn = $in
  $conn
  | enumerate
  | each {|i|
    $i.item
    | each {|c|
      $conn
      | skip ($i.index + 1)
      | filter {$c in $in}
      | each {filter {$in != $c}}
      | flatten
    }
    | reduce {|i, acc| $acc | intersection $i}
    | each {$in ++ $i.item}
  }
  | flatten
  | each {sort | uniq}
  | uniq
}

def parse-input [] {
  lines | each {split row '-'} | each {sort} | uniq | sort
}
