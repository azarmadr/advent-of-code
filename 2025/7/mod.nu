$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def possible-paths [row prop] {
  get $row | transpose | rename k v
  | where v == $prop and k != paths
  | each {|i| match $i.v {
    '|' => [[($row + 1) $i.k]]
    'T' => {
      let k = $i.k | into int
      [($k - 1) ($k + 1)]
      | each {[$row ($in | into string)]}
      | append [[$row $i.k]]
    }
  }}
}

def propagate-rays [row prop='|'] {
  let map = $in
  $in | possible-paths $row $prop
  | flatten
  | where $it.0 < ($map | length)
  | each {into cell-path}
  | reduce -f $map {|i|
    update $i {match $in {
      . => '|'
      ^ => 'T'
      T => 'v'
      | => '|'
      _ => (error make {msg: $"Unexpected ($map | print)
	    at ($i)"})
    }}
  }
}

def print-map-rays [cond] {
  where ($it | values | skip | str join ''| do $cond $in)
  | print $in
  $in
}

def "main silver" [] {
  print-map-rays {|i| $i !~ v}
  | each {values | where $it == v | length}
  | math sum
}

def merge-splits [row map] {
  let tails = $row | get tail | uniq
  $map
  | upsert items {default 1}
  | each {|r|
    if $r.head in $tails {
      $row
      | where $it.tail == $r.head
      | each {|i| $r | merge $i}
      | reject tail
    } else {[$r]}}
  | flatten
  | group-by head --to-table
  | update head {into int}
  | update items {get items | math sum}
  | do {table -e| print res $in; $in}
}

def "main gold" [] {
  where ($it | values) has v
  | do {print $in; $in}
  | par-each {values | enumerate
    | where $it.item == v
    | get index
    | each {|i|
      [($i - 1) ($i + 1)]
      | each {{head: $in tail: $i}}
    }
    | flatten
  }
  # do {table -e | print $in; $in}
  | reduce {|i| merge-splits $i $in}
  | get items | math sum
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    '.......S.......
     ...............
     .......^.......
     ...............
     ......^.^......
     ...............
     .....^.^.^.....
     ...............
     ....^.^...^....
     ...............
     ...^.^...^.^...
     ...............
     ..^...^.....^..
     ...............
     .^.^.^.^.^...^.
     ...............'
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  open $input
  | lines
  | split column -cr ''
  | rename -b {str replace -ra '\D+' ''}
  | update cells {if $in == S {'|'} else {}}
  | enumerate | flatten
  | reduce -f $in {|r| 
    propagate-rays $r.index T
    | propagate-rays $r.index
  }
}
def run [input] {
  let input = parse-input $input
  {}
  | insert gold {$input | main gold}
  | insert silver {$input | main silver}
}

def main [i=0, -v] {
  let input = [input.txt sample.txt]
  | get $i
  if $v {debug profile -l -m 3 { run $input}
    | move duration_ms --after line
    | reject file
  } else {run $input}
}
