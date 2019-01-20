# Guard::Terraform

[![Gem Version](https://badge.fury.io/rb/guard-terraform.svg)](https://rubygems.org/gems/guard-terraform)
[![Build Status](https://travis-ci.org/tmatilai/guard-terraform.svg?branch=master)](https://travis-ci.org/tmatilai/guard-terraform)

[Guard]: https://github.com/guard/guard#readme

A [Guard][] plugin for checking and optionally fixing [Terraform](https://www.terraform.io/) configuration formatting and style. Uses the [`terraform fmt`](https://www.terraform.io/docs/commands/fmt.html) command to do the job.

By running Guard, the formatting is automatically checked every time a `.tf` or `.tfvars` file is added or modified. By default all issues are printed as diff, but automatic rewrite is also possible, and maybe even recommended.

This project also includes a [Rake](https://ruby.github.io/rake/) task. This could be useful for example in some CI setups when running different linter tasks.

## Installation

This plugin requires Terraform to be installed on the system. This can be done e.g. [the official way](https://learn.hashicorp.com/terraform/getting-started/install.html), or with [chtf](https://github.com/Yleisradio/homebrew-terraforms#readme) on Mac. Guard::Terraform should be compatible with all (well, at least reasonably recent) Terraform versions.

Then Ruby is needed. While most operating systems include Ruby, it is best to leave the (often really old) system version alone, and install a recent one with for example Homebrew or [ruby-install](https://github.com/postmodern/ruby-install) (which is great with [chruby](https://github.com/postmodern/chruby)).

The recommended way to install Guard plugins is using [Bundler](https://bundler.io/) and `Gemfile`. Ruby v2.6 and later come with Bundler included, but on older ones it can be installed by:

```sh
$ gem install bundler
```

The `Gemfile` in your Terraform project root could look like this:

```ruby
source 'https://rubygems.org'

gem 'guard'
gem 'guard-terraform', '~> 1.0'
```

Finally, to install Guard and Guard::Terraform, execute:

```sh
$ bundle

# Later the versions can be updated by:
$ bundle update
```

If you don't want to use Bundler, you can just run:

```sh
$ gem install guard-terraform
```

## Usage

Please read [Guard usage doc][Guard].

The default configuration for Guard::Terraform can be generated to `Guardfile` executing:

```sh
$ bundle exec guard init terraform
```

Then Guard is started by:

```sh
$ bundle exec guard
```

### Options

Options can be specified in the `Guardfile` like this:

```ruby
# This example checks and fixes recursively all Terraform files at startup.
# Then the formatting is done whenever a file with `.tf` or `.tfvars` suffix is
# added or modified
guard :terraform, all_on_start: true, write: true do
  watch(/\.tf$/)
  watch(/\.tfvars$/)
end
```

Available options and their default values:

```ruby
all_on_start: true  # Check all files on start?

diff:  true         # Show diffs of the changes?
write: false        # Fix the formatting instead of just verifying?
```

Notes:

* `diff` should be enabled at least if `write` is disabled, or it might be difficult to catch the issues.
* When `write` is enabled and if Terraform rewrites a file, Guard will catch the modification and pass the file again to Guard::Terraform. So the file is checked again, but should of course pass this time.

## Rake Integration

To run Terraform format checks easily with [Rake](https://ruby.github.io/rake/), add the `rake` gem to the `Gemfile`, and this to a `Rakefile`:

```ruby
require 'terraform/rake_task'

Terraform::RakeTask.new
```

Then you can run the task with:

```sh
$ bundle exec rake terraform
```

Another example that creates two tasks: one for checking and another for auto-correcting the formatting. Tasks can be listed with `bundle exec rake -T`.

```ruby
require 'terraform/rake_task'

task default: 'terraform:check'

namespace :terraform do
  desc 'Check Terraform file formatting'
  Terraform::RakeTask.new(:check)

  desc 'Auto-correct Terraform file formatting'
  Terraform::RakeTask.new(:fix) do |task|
    task.write = true
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/tmatilai/guard-terraform](https://github.com/tmatilai/guard-terraform). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Guard::Terraform project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tmatilai/guard-terraform/blob/master/CODE_OF_CONDUCT.md).
