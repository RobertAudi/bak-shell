module BakShell
  class CLI
    desc "Restore a file or directory"
    arg_name "TARGET"
    command :restore do |c|
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
        latest_backup = Dir.glob(File.join(backup_dir, "*.bak-latest-*"))

        raise "No backup marked as latest was found" if latest_backup.empty?
        raise "More than one backup marked as latest was found" if latest_backup.count > 1

        latest_backup = latest_backup.first

        temp_bak = "#{target}.bak-#{Time.now.to_f}"
        FileUtils.mv(target, temp_bak)
        FileUtils.cp_r(latest_backup, File.join(File.dirname(target), File.basename(latest_backup).sub(/\.bak-latest-.*\Z/, "")))
        FileUtils.rm_r(temp_bak, force: true)

        puts "Backup restored!".color(:green)
      end
    end
  end
end
