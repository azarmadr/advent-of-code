export def main [] {
    let path = pwd | path relative-to ("..." | path expand) | path split | str join /day/
    http get $'https://adventofcode.com/($path)/input' -H [{Cookie: (open .../.cookie)}]
    | save input.txt
}
