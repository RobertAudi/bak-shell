module BakShell
  class CLI
    extend GLI::App

    program_desc  "Backup utility for the shell"
    version       BakShell::VERSION

    commands_from File.expand_path(File.join(File.dirname(File.realpath(__FILE__)), "commands"))
  end
end
