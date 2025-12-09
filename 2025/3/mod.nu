$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *
use .../nu/utils.nu *

def remove-consecutive-patterns [] {
  mut i = $in
  # print $i
  loop {
    let j = $i | str replace -ra '(..+)\1+' '$1'
    if $i == $j {break}
    $i = $j
  }
  $i | str replace -ra '(.)\1+' '$1$1' # do {print $in; $in}
}

def "main silver-slow" [] {
  each {
    remove-consecutive-patterns
    | split chars
    | combinations $in
    | each {str join '' | into int}
    | math max
    # do {print $in; $in}
  }
  | math sum
}

def inspect-list [msg = ''] {
  let list = $in
  $list | try {str join ''} catch {$list} | print $'($msg): ($in)'
  $list
}

def cut-at-max-for [rem] {
  upsert ans {|i| append ($i.list | drop $rem | math max)}
  | update list {|i| $i.list | skip until {$in == ($i.ans | last)} | skip}
}

def get-largest-n-digit [n] {
  let list = split chars | into int | {ans: [] list: $in}
  0..($n - 1) | reduce -f [$list] {|i| append ($in | last | cut-at-max-for ($n - 1 - $i))}
  | update cells {|i| try {str join ''} catch {$i}}
}

def "main gold" [] {
  each { get-largest-n-digit 12 }
  | do {$in | each {print}; $in}
  | each {last | $in.ans | into int}
  | math sum
}

def "main silver" [] {
  each { get-largest-n-digit 2 }
  | do {$in | each {print}; $in}
  | each {last | $in.ans | into int}
  | math sum
}

def run [input] {
  let input = parse-input $input
  $input | main silver | print $"Silver:>\n($in)"
  $input | main gold | print $"Gold:>\n($in)"
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
    '987654321111111
811111111111119
234234234234278
818181911112111'
    | save -f sample.txt
  }
  open $input
  | lines
}
