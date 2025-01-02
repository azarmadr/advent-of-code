def main [curr: int, ] {
  watch . -r true {|op, path|
    $op | print
    if $op == 'Create' { try {
      clear;timeit {nu $'2024\($curr)\mod.nu' $'2024\($curr)\sample.txt'}
    }}
  }
}
