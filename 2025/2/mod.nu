$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def check-even-chars [x] {$x | into string | str length | $in mod 2 | $in == 0}
def invalid-id [x] {$x | into string | split chars | chunks ($in | length | $in // 2) | $in.0 == $in.1}

def "main silver-1" [] {
  each {|i|
    seq $i.0 $i.1
    | where (check-even-chars $it) and (invalid-id $it)
  }
  | flatten
  | math sum
}
def 'main silver' [] {
  each {
    seq $in.0 $in.1
    | into string
    | each {{it: $in len: ($in | str length | $in // 2)}}
    | where $it.it =~ $'^("(")\d{($it.len)})\1$'
  }
  | flatten
  | $in.it
  | into int
  | math sum
}

def invalid-id-gold [x] {
  let x = $x | into string | split chars
  seq 1 ($x | length | $in // 2) | any {|i|
    chunks $i | uniq | length | $in == 1
  }
}

def "main gold" [] {
  each { seq $in.0 $in.1
    | where $it > 9
    | where (invalid-id-gold $it)
  }
  | flatten | math sum
}

def run [input] {
  let input = parse-input $input
  # $input | main gold | print $"Gold:>\n($in)"
  $input | main silver | print $"Silver:>\n($in)"
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
    '11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124'
    | save -f sample.txt
  }
  open $input
  | split row ,
  | each {split row - | into int}
}
