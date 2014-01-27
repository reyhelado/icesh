# -*- coding: utf-8 -*-
require 'readline'

class Shell
  VERSION = "0.0.1"

  def initialize(config_path)
    @config_path = config_path
    @motd = File.read(File.join(@config_path, 'motd'))

    Readline.completion_append_character = " "
    Readline.completion_proc = method(:complete)
  end

  def path
    @path ||= []
  end

  def help_path
    @help_path ||= []
  end

  def complete(s)
    preloaded_commands.keys.grep(/^#{Regexp.escape(s)}/)
  end

  def start
    puts(@motd % { now: Time.now.year })
    puts
    main
  end

  def main
    while buf = Readline.readline("> ", true)
      buf.strip!

      next if buf.empty?

      parts = buf.split
      cmd_name = parts.shift

      next if cmd_name.empty?

      if cmd_name == 'help'
        help(*parts)
        next
      end

      cmd = preloaded_commands[cmd_name]

      unless cmd
        error("Command `#{cmd_name}' not found!")
        next
      end

      system(cmd, *parts)
      rc = $?.exitstatus

      if rc == 251
        break
      end
    end
  rescue Interrupt => err
    puts "^C"
    retry
  end

  protected

  def get_preloaded_commands(path)
    commands = {}

    path.each { |path|
      Dir[File.join(path, '*')].each { |fname|
        if File.executable_real?(fname)
          commands[File.basename(fname)] = fname
        end
      }
    }

    commands.merge('exit' => File.join(path.last, 'exit'))
  end

  def preloaded_commands
    get_preloaded_commands(path)
  end

  def preloaded_commands_with_help
    get_preloaded_commands(help_path)
  end

  def help(cmd_name=nil)
    if cmd_name && !cmd_name.empty?
      cmd = preloaded_commands[cmd_name]
      return unless cmd
      system(cmd, '-help')
    else
      puts "Ice Shell v.#{VERSION}. Copyright (c) 2013-#{Time.now.year} by Chris Kovalik."
      puts "Here's the list of available system commands:"
      puts

      commands = preloaded_commands_with_help
      commands.keys.sort.each do |name|
        cmd = commands[name]
        purpose = %x(#{cmd} -purpose)
        puts("#{name} — #{purpose}")
      end

      puts
      puts "Use `help COMMAND' to display information about specific command."
    end
  end

  def error(*args)
    puts(*args)
  end
end
