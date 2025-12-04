$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def "main silver" [] {
  let items = $in
  | update fresh {each {$in.0..$in.1}}
  $in.available
  | each {|i| $items.fresh | any {$i in $in}}
  | where $it
  | length
}

def format-ranges [rhs] {
  [$'->[($in | length)]'] ++ $in
  | each {str join : | str replace -ra '(\d{5})(\d)' '$1,$2'}
  | grid | str join "\n" | print
  $in
}
def merge-ranges [rhs] {
  $in ++ [$rhs]
  | format-ranges $rhs
  if ($in | is-empty) {return [$rhs]}
  let lhs = $in | last
  $in
  | drop
  | append (
    if false {
    } else if $lhs.1 >= $rhs.1 {
      [$lhs]
    } else if $lhs.1 + 1 >= $rhs.0 or $lhs.1 + 1 >= $rhs.1 {
      [[$lhs.0 $rhs.1]]
    } else {[$lhs $rhs]})
  | do {
    $in | last 2
    $in
  }
}
def "main gold" [] {
  $in.fresh
  | sort-by -c {|a b| $a.0 < $b.0}
  | uniq
  | reduce -f [] {|i| merge-ranges $i}
  | each {$in.1 - $in.0 + 1}
  | math sum
}

def main [input = sample.txt, -v] {
  let input = 'input.txt'
  if $v {debug profile -l -m 3 { run $input}
  | move duration_ms --after line
  | reject file
  } else {run $input}
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    '3-5
     10-14
     16-20
     12-18

     1
     5
     8
     11
     17
     32'
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  open $input
  | split column -r '\n\s*\n'
  | $in.0
  | rename fresh available
  | update cells {lines}
  | update fresh {each {split row -| into int}}
  | update available {into int}
}
def run [input] {
  let input = parse-input $input
  {}
  | insert gold {$input | main gold}
  | insert silver {$input | main silver}
}
