# IceSH — A bit of a frozen shell

IceSH (Ice Shell) is a stupid idea of a simple customizable and protected shell.
It's just a dummy shell wrapped with protection layer handled by Ruby.

## Getting started

After you clone the repository, install dependencies with bundler:

    $ bundle install

Yeah, and that's it... Now you can enter into the shell by executing:

    $ ./icesh

## Hacking

### Custom commands (binaries)

Basically, this shell will execute everything that's executable and can be found
in defined binary paths. It can be any kind of bash script, binary, ruby scrip etc.
Script should always respond to two flags:

* `-help` - This should display usage information.
* `-purpose` - This one should display simple summary of what's the purpose of a command.

### Testing

There's nothing special to know about tests suite, run it with rspec rake task:

    $ rake spec

## Copyright

...
