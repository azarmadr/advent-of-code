$env.config.table.mode = 'compact'
$env.config.table.header_on_separator = true

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input
  | get items
  | reduce {|i| each {|j| $i | each {zip $j}}| flatten}
  | filter {all {math sum | $in < 8}}
  | length
  | inspect
}

def "main gold" [input: path, ] {
  open $input | parse-input
}

# solution for day 2024/5
def main [rest] {
  main silver $rest | print $'Silver:>($in)'
  return
  main gold $rest | print $'Gold:>($in)'
}

def parse-input [] {
  split row -r '\n\n'
  | each {
    lines
    | split chars
  }
  | group-by --to-table {
    if ($in.0 | all {$in == '#'}) { 'lock' } else { 'key' }
  }
  | update items { each {
    each {enumerate| transpose -ir}
    | flatten
    | transpose -i
    | each {values | uniq -c | transpose -dr | get '#'}
  }} # do {$in | table -e | print; $in}
}
