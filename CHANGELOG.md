## 1.1.1 / _Not released yet_


## 1.1.0 / 2019-01-24

- Add `Terraform::RakeTask` helper to run Terraform format checks easily with [Rake](https://ruby.github.io/rake/) ([GH-3](https://github.com/tmatilai/guard-terraform/pull/3))

## 1.0.1 / 2019-01-19

- Optimise `run_all` to check all the `*.tf` files at once and only the `*.tfvars` files separately ([GH-2](https://github.com/tmatilai/guard-terraform/pull/2))
- Be more quiet by hiding the checked paths to debug output. File names with format issues are still of course printed.

## 1.0.0 / 2019-01-18

- First public version of the plugin
