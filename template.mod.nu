$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

def "main silver" [input: path, ] {
  open $input | parse-input
}

def "main gold" [input: path, ] {
  open $input | parse-input
}

def main [-v rest] {
  debug profile -l -m 3 {
    main gold $rest | print $'Gold:> ($in)'
    main silver $rest | print $'Silver:> ($in)'
  }
  | move duration_ms --after line
  | reject file
  | if $v {print}
}

def parse-input [] {
}
