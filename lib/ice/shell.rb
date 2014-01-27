# -*- coding: utf-8 -*-
require 'readline'

module Ice
  # Public: Shell is a custom, protected shell environment powered up by
  # redline library handlers.
  #
  # Examples
  #
  #   sh = Ice::Shell.new('./')
  #   sh.path.unshift('./my/extra/binary/path')
  #   sh.start
  #
  class Shell
    # This code, if returned by a command will cause the shell to exit.
    EXIT_CODE = 251

    # Intenral. Root path of this shell.
    attr_reader :root

    # Internal. Config path of this shell.
    attr_reader :configs

    # Constructor. Creates new shell pointed to given config path.
    def initialize(root)
      @root = root
      @configs = File.join(root, 'etc')

      self.path.push(File.join(root, 'bin'), File.join(root, 'sbin'))
      self.help_path.replace(self.path.clone)

      Readline.completion_append_character = " "
      Readline.completion_proc = method(:complete)
    end

    # Internal: Completion function, it returns list of possible commands
    # matching given prefix.
    #
    # s - The String prefix to match.
    #
    # Returns Array of matching commands.
    def complete(s)
      preloaded_commands.keys.grep(/^#{Regexp.escape(s)}/)
    end

    # Internal: Returns Array of binary paths.
    def path
      @path ||= []
    end

    # Internal: Returns Array of binary paths included by help topics.
    def help_path
      @help_path ||= []
    end

    # Internal: Returns String with message of the day.
    def motd
      @motd ||= File.read(File.join(@configs, 'motd'))
    end

    # Internal: Returns String with shell prompt.
    def prompt
      @prompt ||= begin
        tpl = File.read(File.join(@configs, 'prompt'))
        tpl.chomp % prompt_params
      end
    end

    # Internal: Returns Hash with shell prompt interpolation parameters.
    def prompt_params
      @prompt_params ||= {
        u: %x(whoami).chomp,
        h: %x(hostname -s).chomp
      }
    end

    # Public: Starts shell's event loop.
    def start
      puts(motd % { now: Time.now.year })
      puts

      while buf = Readline.readline(prompt, true)
        break if handle(buf) == EXIT_CODE
      end
    rescue Interrupt => err
      puts "^C"
      retry
    end

    # Internal: This method handles and executes single command.
    #
    # buf - The String command to execute.
    #
    # Returns nothing when command couldn't be executed or help topic has been
    # requested. Returns Integer exit status of the exeucted command if found.
    def handle(buf)
      buf = buf.to_s
      buf.strip!

      return if buf.empty?

      parts = buf.split
      cmd_name = parts.shift

      if cmd_name == 'help'
        help(*parts)
        return
      end

      cmd = preloaded_commands[cmd_name]

      unless cmd
        error("Command `#{cmd_name}' not found!")
        return
      end

      system(cmd, *parts)
      return $?.exitstatus
    end

    # Internal: Prints error message.
    def error(*args)
      puts(*args)
    end

    protected

    # Internal: Pre-loads list of available commands from given binary paths.
    #
    # path - The Array list of paths to search for commands.
    #
    # Returns Array with available commands.
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

    # Internal: Returns Array of available commands from general binary paths.
    def preloaded_commands
      get_preloaded_commands(path)
    end

    # Internal: Returns Array of available commands with help topics.
    def preloaded_commands_with_help
      get_preloaded_commands(help_path)
    end

    # Internal: Displays help topics. If command name specified, then it will
    # display help information about that particular command.
    #
    # cmd_name -  The String name of the command to get help info (optional).
    #
    # Return nothing.
    def help(cmd_name=nil)
      if cmd_name && !cmd_name.empty?
        cmd = preloaded_commands[cmd_name]

        unless cmd
          puts "No help topics, command `#{cmd}' not found!"
          return
        end

        system(cmd, '-help')
      else
        puts "Ice Shell v.#{VERSION}. Copyright (c) 2013-#{Time.now.year} by Chris Kovalik."
        puts "Here's the list of available system commands:"
        puts

        commands = preloaded_commands_with_help
        commands.keys.sort.each do |name|
          begin
            cmd = commands[name]
            purpose = %x(#{cmd} -purpose)
            puts("#{name} — #{purpose}")
          rescue
            next
          end
        end

        puts
        puts "Use `help COMMAND' to display information about specific command."
      end
    end
  end
end
