export def next-stones [] {
  match $in {
    $x if ($x | str length | $in mod 2) == 0 => (
      $x
      | split chars
      | chunks ($x | str length | $in / 2 | into int)
      | each {str join '' | str replace -r '0*(.+)' '$1'}
    )
    '0' => '1'
    _ => ($in | into int | $in * 2024 | into string)
  }
}

export def blink [] {
  update group {$in | next-stones}
  | flatten
  | group-by group --to-table
  | update items {get items | math sum}
  | sort-by items
}

export def "blink for" [limit] {
  let i = $in
  0..$limit
  | reduce -f $i {|_,a| $a | blink }
}

export def u-blink [] {
  each {next-stones}
  | flatten
  | uniq
  | sort-by {into int} -r
}
export def "u-blink for" [limit] {
  let i = $in
  0..$limit
  | reduce -f $i {|_,a| $a | u-blink }
}

export def blink-saturate [] {
  mut c = $in
  let init = $in
  for i in 1.. {
    let n = $c | u-blink
    if $n == $c {
      return {init:$init with: $n at: $i}
    }
    $c = $n
  }
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input 25
}

def "main gold" [input: path, ] {
  open $input | parse-input 75
}

# solution for day 2024/5
def main [rest] {
$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

  main silver $rest | print 'Silver:>' $in
  main gold $rest | print 'Gold:>' $in
}

def parse-input [limit] {
  let i = parse -r '(\d+)'
  | group-by capture0 --to-table
  | update items {length}
  $i
  | blink for $limit
  | get items
  | math sum
}
