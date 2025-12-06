$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def "main silver" [] {
}

def "main gold" [] {
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    return
    | lines | str trim | str join "\n"
    | save -f sample.txt
  }
  open $input
}
def run [input] {
  let input = parse-input $input
  {}
  | insert gold {$input | main gold}
  | insert silver {$input | main silver}
}

def main [input = sample.txt, -v] {
  # let input = 'input.txt'
  if $v {debug profile -l -m 3 { run $input}
    | move duration_ms --after line
    | reject file
  } else {run $input}
}
