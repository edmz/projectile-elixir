# Projectile Elixir [![Build Status](https://travis-ci.org/edmz/projectile-elixir.png?branch=master)](https://travis-ci.org/edmz/projectile-elixir)

## Synopsis

**Projectile Elixir** is a minor mode for working with the Elixir projects in GNU Emacs.
Internally it is basically a 'port' of [Projectile Rails](https://github.com/asok/projectile-rails) to Elixir,
which in turn relies on [Projectile](https://github.com/bbatsov/projectile).

It means that you can use Projectile's commands for greping (or acking) files, run tests, switch between projects, etc.

With Projectile Elixir you are able to:

* navigate through elixir project files (modules, tests)
* see some frequently used non-elixir keywords highlighted

## Setup

### Installation

#### Melpa

Once you have setup [Melpa](http://melpa.milkbox.net/#/getting-started) you can use `package-install` command to install Projectile Elixir. The package name is `projectile-elixir`.

## Usage

### Hooking up with Projectile

To make it start alongside `projectile-mode`:

```el
(add-hook 'projectile-mode-hook 'projectile-elixir-on)
```
That will start it only if the current project is an Elixir project.

Probably you should read Projectile's [README](https://github.com/bbatsov/projectile) on setting up the completion system, caching and indexing files. Although the default settings are quite sensible and you should be ready to go without much tweaking.

<!--
### Customizing

The mode's buffers will have the Rails keywords highlighted. To turn it off:
```el
(setq projectile-rails-add-keywords nil)
```

If you are using [yasnippet](https://github.com/capitaomorte/yasnippet) and you open a new file it will be filled with a skeleton class. To turn it off:
```el
(setq projectile-rails-expand-snippet nil)
```

By default the buffer of the `projectile-rails-server-mode` is applying the ansi colors. If you find it slow you can disable it with:
```el
(setq projectile-rails-server-mode-ansi-colors nil)
```
-->

### Interactive commands

Command                                  | Keybinding                                 | Description
-----------------------------------------|--------------------------------------------|-------------------------------------------------------
projectile-elixir-find-module            | <kbd>C-c x m</kbd>                         | Find a model using `projectile-completion-system`.
projectile-elixir-find-test              | <kbd>C-c x t</kbd>                         | Find a spec using `projectile-completion-system`.
projectile-elixir-find-current-module    | <kbd>C-c x M</kbd>                         | Go to a module connected with the current test.
projectile-elixir-find-current-spec      | <kbd>C-c x T</kbd>                         | Go to a spec connected with the current module.
projectile-elixir-goto-mix-exs           | <kbd>C-c r g g</kbd>                       | Go to `mix.exs` file.
projectile-elixir-goto-config-exs        | <kbd>C-c r g r</kbd>                       | Go to `config/config.exs` file.
projectile-elixir-goto-test-helper       | <kbd>C-c r g d</kbd>                       | Go to `test/test_helper.exs` file.


<!--
### Discover

There's also integration with [discover.el](https://github.com/mickeynp/discover.el). The key that trigger the menu is `s-r` (the "s" stands for Win/Command key).

![Screenshot](https://github.com/asok/projectile-rails/raw/master/screenshots/discover.png)

-->



### Miscellaneous

* [magit](https://github.com/magit/magit) to interact with git.


