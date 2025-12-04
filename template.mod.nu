$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true
use .../nu/get-days-input.nu *

def "main silver" [] {
}

def "main gold" [] {
}

def run [input] {
  let input = parse-input $input
  $input | main gold | print $"Gold:>\n($in)"
  $input | main silver | print $"Silver:>\n($in)"
}
def main [input = sample.txt, -v] {
  # let input = 'input.txt'
  if $v {debug profile -l -m 3 { run $input}
  | move duration_ms --after line
  | reject file
  } else {run $input}
}

def parse-input [input] {
  cd ($env.CURRENT_FILE | path dirname)
  if not ('input.txt' | path exists) { get-days-input }
  if not ('sample.txt' | path exists) {
    # save -f sample.txt
  }
  open $input
}
