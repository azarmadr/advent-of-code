$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def calculate-result [] { 
  each {|i| $i.nums
    | if $i.op == + {math sum} else {math product}
  }| math sum
}
def "main silver" [] {
  str trim
  | split column -r '\s+'
  | transpose -i
  | each {{op: ($in | values | last) nums: ($in | values | drop)}}
  | update nums {into int}
  | calculate-result
}

def "main gold" [] {
  split column '' -c
  | transpose -i
  | each {
    values | str join '' | str replace -r '.$' ' $0'
    | str trim -r
  }
  | str join "\n"
  | split row -r '\n\s*\n'
  | each {lines | str trim | split row -r '\s+'}
  | each {{op: $in.1 nums: ($in | drop nth 1 | into int)}}
  | calculate-result
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    [
      '123 328  51 64 ',
      ' 45 64  387 23 ',
      '  6 98  215 314',
      '*   +   *   +  ',
    ]
    | str join "\n"
    | save -f sample.txt
  }
  open $input
  | lines
}
def run [input] {
  let input = parse-input $input
  {}
  | insert gold {$input | main gold}
  | insert silver {$input | main silver}
}

def main [input = sample.txt, -v] {
  let input = 'input.txt'
  if $v {debug profile -l -m 3 { run $input}
    | move duration_ms --after line
    | reject file
  } else {run $input}
}
