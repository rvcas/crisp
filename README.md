# Crisp

A very minimal lispy calculator implemented in [zig](https://ziglang.org)

![Running Crisp](https://github.com/rvcas/crisp/raw/main/img/screenshot.png)

## Operations

- `+` add a sequence of numbers
  - `(+ 1 2 3)`
- `-` subtract a sequence of numbers
  - `(- 3 2)`
- `*` multiply a sequence of numbers
  - `(* 3 5 2)`
- `/` divide a sequence of numbers
  - `(/ 12 4)`
  - decimals are not supported. meaning: `(/ 2 4) => 0`
    - everything is floored
  - divide by zero results in an error
