export def main [] {
    let path = pwd | path relative-to ("..." | path expand) | path split | str join /day/
    let url = $'https://adventofcode.com/($path)/input'
    http get $url -H [{Cookie: (open .../.cookie | lines).0}]
    | save input.txt
}
