$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *
use .../nu/utils.nu *

def distance [r] {
  [$in $r] | each {values | skip} | reduce {|i| zip $i}
  | each {$in.0 - $in.1 | $in * $in}
  | math sum
}

def group-circuits [connection groups limit=10] {
  if $groups == [] { return [$connection] }
  let f = $groups
  | enumerate
  | where ($connection | any {$in in $it.item})
  # if ($f | length) > 1 {$f | table -e | print $in}
  if $f == [] {
    $groups
    | append [$connection]
    | return $in
  }

  let first = $f | first | $in.index
  let rest = $f | skip | get index

  $groups
  | update $first {
    append $connection | append ($f.item | flatten) | uniq}
    | do {let g = $in; $rest | reduce -f $g {|i| drop nth $i}}
}

def print-groups [] {
  update g {
    each {
      select x
      | append ($in | length) | reverse | str join ' '}
      | sort -rn
  } | table -e | print
$in}

def silver [] {
  let count = $in | length | if $in == 1000 {1000} else {10}
  $in
  | reduce -f {g:[] c:0} {|i| 
    if $in.c >= $count {return $in}
    $in | update c {$in + 1}
    | update g { group-circuits $i $in}
  }
  | print-groups
  | $in.g
  | each {length}
  | uniq
  | sort -r
  | first 3
  | math product
}

def gold [] {
  $in | reduce -f {g:[] n:0 res: null i:null} {|i|
    # if $in.res != null {return $in}
    let n = $in.n
    $in
    | update g { group-circuits $i $in}
    | update n {|i| $i.g.0 | length}
    | update i $i
    | update res {|j| if $n != $j.n {
      $j | print-groups
      $i
    } else {}}
  }
  | $in.res.x | math product
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    '162,817,812
    57,618,57
    906,360,560
    592,479,940
    352,342,300
    466,668,158
    542,29,236
    431,825,988
    739,650,466
    52,470,668
    216,146,977
    819,987,18
    117,168,530
    805,96,715
    346,949,466
    970,615,88
    941,993,340
    862,61,35
    984,92,344
    425,690,689'
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  open $input
  | lines
  | parse '{x},{y},{z}'
  | update cells {into int}
  | enumerate | flatten
  | do {
    let count = $in | length | if $in == 1000 {1000} else {10}
    let file = $'out-($count).nuon'
    $in
    | if ($file | path exists) {
      open $file
    } else {
      combinations $in
      | wrap combo
      | par-each {
	insert dist {|i| $i.combo.0 | distance $i.combo.1}}
      | sort-by dist
      | each {$in.combo | select index x}
      | save -f $file
    }
  }
}
def run [input] {
  let input = parse-input $input
  {}
  | insert gold {$input | gold}
  | insert silver {$input | silver}
}

def main [i=0, -v] {
  let input = [input.txt sample.txt] | get $i
  if $v {debug profile -l -m 3 { run $input}
    | move duration_ms --after line
    | reject file
  } else {run $input}
}
