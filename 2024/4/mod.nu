def "main silver" [input: path ] {
  let input = open $input

  let max_chars = $input | lines | each {str length} | math max
  let matrix = $input | parse -r (seq 1 $max_chars | each {'(.)'} | str join '')

  let xmas_counter = {|| each {values|str join ''} | [
    ($in | parse -r '(XMAS)')
    ($in | parse -r '(SAMX)')
  ] | flatten | length}
  let add_num = {|num| parse -r '(\d+)' | $"capture(($in.0.capture0 | into int) + $num)"}

  let move_cols = {|i| rename -c (
    $matrix.0 | columns | reduce -f {} {|it| insert $it ($it | do $add_num $i)}
  )}

  []
  | append ($matrix | do $xmas_counter)
  | append ($matrix | rotate | reject $"column($max_chars)" | do $xmas_counter)
  | append ($matrix
    | enumerate
    | each {|i| $i.item | do $move_cols (-1 * $i.index) }
    | transpose --ignore-titles
    | do $xmas_counter
  )
  | append ($matrix
    | enumerate
    | each {|i| $i.item | do $move_cols $i.index }
    | transpose --ignore-titles
    | do $xmas_counter
  )
  | math sum
  | print
}

# run silver and gold problems
def main [ ] { error make {msg: 'provide <silver|gold>', }}
