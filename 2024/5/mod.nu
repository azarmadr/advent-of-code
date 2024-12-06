def get-middle [] {skip (((($in | length) - 1) / 2 )|into int) | first}
def sum-middle-entries [] {
  each {get-middle}
  | into int
  | math sum
}

def correct-input [pos] {
  sort-by -c {|a, b| {pre:$a, post:$b} in $pos}
}

# get the middle number of correct reports and sum them
def "main silver" [input: path, ] {
  open $input | parse-input | where valid | get item | sum-middle-entries
}

def "main gold" [input: path, ] {
  open $input | parse-input | where valid == false | get item | sum-middle-entries
}

# solution for day 2024/5
def main [rest] {
  print 'Silver'
  main silver $rest | print
  print 'Gold'
  main gold $rest
}


def parse-input [] {
  let data = $in
  let pos = $data | lines | parse '{pre}|{post}'
  $data
  | lines
  | filter {$in =~ ','}
  | each {split row ','}
  | each {
    let corrected = $in | correct-input $pos
    {item: $corrected, valid: ($in == $corrected)}
  }
}
