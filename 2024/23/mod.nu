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
  # mut conn = open $input | parse-input
  # for _ in 0..5 {
  #     $conn | enumerate | inspect
  #     $conn = $conn | next-level-lan-party
  #     if ($conn | length) < 2 { break}
  #   }
  # $conn
  # | flatten
  # | str join ','

  mut links = {un: (open $input | parse-input) p: []}
  while $links.un != [] {
    let next = $links | merge-head
    if $links.p != $next.p and false {
      $next.p | last | {l: ($in | length | into string) s:($in | str join ',')} | print $in
    }
    $links = $next
  }
  let groups = $links.p
  | group-by {length} --to-table
  | update group {into int}
  let max = $groups | get group | math max | inspect
  $groups | where group == $max
  | $in.0.items.0
  | str join ','
  | print $'Gold:>($in)'
}

def merge-head [-v] {
  let conn = $in
  if $conn.un == [] {return $conn}
  let head = $conn.un.0
  let rest = $conn.un | skip
  let groups = $head
  | each {|c|
    $rest
    | filter {$c in $in}
    | each {filter {$in != $c}}
    | flatten
  }
  | reduce {|i, acc| $acc | intersection $i}
  | each {$in ++ $head | sort}
  | uniq
  if $v {
    $head | inspect
    $rest | inspect
    $groups | inspect
  }
  if $groups == [] {
    $conn | update un $rest | update p {$in ++ [$head]}
  } else {
    $conn | update un ($rest
      | filter {|p| not ($groups | any {$p == ($in | intersection $p | sort)}) }
      | append $groups
      | uniq
      | sort
    )
  }
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
