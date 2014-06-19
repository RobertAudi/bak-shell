module BakShell
  class CLI
    desc "Restore a file or directory"
    arg_name "TARGET"
    command :restore do |c|
      c.desc "Index of backup to restore"
      c.flag :i, :index, default: 1, must_match: /\A[1-9][0-9]*\Z/

      c.action do |global_options, options, args|
        raise TargetMissingError.new("Target missing") if args.empty?
        raise TooManyTargetsError.new("Only one target can be specified") if args.count > 1

        target = File.expand_path(args.first)

        raise InvalidTargetError.new("No such file or directory: #{target}") unless File.exists?(target)

        puts "Restoring backup...".color(:green)

        indexer = Indexer.instance
        backup = indexer.backup_with_target(target)

        raise InvalidBackupError.new("No backup found for file or directory: #{target}") if backup.nil?

        backup_dir = File.join(BakShell::BACKUP_DIR, backup.id)
        index = options[:i].to_i

        if index == 1
          backup_to_restore = Dir.glob(File.join(backup_dir, "*.bak-latest-*")).first
        else
          backups = Dir.glob(File.join(backup_dir, "*")).reverse

          raise BakShell::InvalidBackupError.new("Invalid backup index: #{index}") if index > backups.count

          backup_to_restore = backups[index - 1]
        end

        temp_bak = "#{target}.bak-#{Time.now.to_f}"

        FileUtils.mv(target, temp_bak)
        FileUtils.cp_r(backup_to_restore, target)
        FileUtils.rm_r(temp_bak, force: true)

        puts "Backup restored!".color(:green)
      end
    end
  end
end
