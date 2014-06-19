# Dev shit
if ENV["BAK_SHELL_DEV_SHIT"] == "devshit"
  require "awesome_print" rescue nil
end

# Standard lib shit
require "fileutils"

# Require gems shit
require "gli"
require "rainbow/ext/string"

module BakShell
  BACKUP_DIR = File.expand_path(File.join(ENV["HOME"], "bak"))
end

require_relative "./bak-shell/version"
require_relative "./bak-shell/exceptions"
require_relative "./bak-shell/indexer"
require_relative "./bak-shell/cli"
