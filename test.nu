def main [curr: int, year = 2025] {
  let puzzle_path = [$year $curr] | into string | path join
  mkdir $puzzle_path
  if not ([$puzzle_path mod.nu] | path join | path exists) {
    cp template.mod.nu ([$puzzle_path mod.nu] | path join)
  }
  watch . -r true
  | where operation == Create and path !~ '~$'
  | where path !~ '.(jj|git).'
  | each {|e|
    print $e
    try {
      clear;timeit {nu $'($year)\($curr)\mod.nu'}
    }
  }
}
