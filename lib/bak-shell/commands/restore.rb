module BakShell
  class CLI
    desc "Restore a file or directory"
    arg_name "TARGET"
    command :restore do |c|
      c.action do |global_options, options, args|
        raise ArgumentError, "Target missing" if args.empty?
        raise ArgumentError, "Only one target can be specified" if args.count > 1

        target = File.expand_path(args.first)

        raise ArgumentError, "No such file or directory: #{target}" unless File.exists?(target)

        indexer = Indexer.instance
        backup = indexer.backup_with_target(target)

        raise ArgumentError, "No backup found for file or directory: #{target}" if backup.nil?

        backup_dir = File.join(BakShell::BACKUP_DIR, backup.id)
        base_target = File.basename(target)
        latest_backup_dir = File.join(backup_dir, base_target)


        temp_bak = "target.bak-#{Time.now.to_f}"
        FileUtils.mv(target, temp_bak)
        FileUtils.cp_r(latest_backup_dir, File.dirname(target))
        FileUtils.rm_r(temp_bak, force: true)
      end
    end
  end
end
