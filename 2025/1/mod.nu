$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

use ../../nu/get-days-input.nu *

def "main silver" [] {
  each {$in mod 100}
  | reduce -f [50] {|i a| append (($a | last) + $i | $in mod 100)}
  | where $it == 0
  | length
}

def "main gold" [] {
  wrap m
  | insert direct_0s {$in.m // 100 | math abs}
  | update direct_0s {|i| if $i.m < 0 {$in - 1} else {}}
  | update m {($in mod 100) - (if $in < 0 {100} else {0})}
  | reduce -f [{pointer: 50 cross: 0}] {|m|
    let $l = $in | last
    $in | append ($l
    | update cross {$in + $m.direct_0s}
    | update pointer {$in + $m.m}
    | merge $m
    | update cross {|i| $in + ($i.pointer // 100 | math abs)}
    | update cross {|i| if $l.pointer == 0 and $m.m < 0 {$in - 1} else {}}
    | update cross {|i| if $i.pointer == 0 and $m.m < 0 {$in + 1} else {}}
    | update pointer {$in mod 100}
    )
  }
  | do {$in | print; $in}
  | last | $in.cross
}

def d [input] {
  let input = parse-input $input
  $input | main gold | print $"Gold:>\n ($in)"
  $input | main silver | print $'Silver:> ($in)'
}
def main [input = sample.txt -v] {
  let input = 'input.txt'
  if $v {debug profile -l -m 3 { d $input}
  | move duration_ms --after line
  | reject file
  } else {d $input}
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) { 'L68
L30
R48
L5
R160
L155
L1
L99
R14
L82' | save -f sample.txt
  }

  open $input
  | lines
  | parse -r '(?<dir>.)(?<size>.*)'
  | update size {into int}
  | each {$in.size * (if $in.dir == R {1} else {-1})}
}
