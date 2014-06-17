module BakShell
  class CLI
    desc "Backup a file or directory"
    arg_name "TARGET"
    command :backup do |c|
      c.desc "Replace latest version of backup (if present). Default: true"
      c.switch :R, :replace, default: true

      c.action do |global_options, options, args|
        raise ArgumentError, "Target missing" if args.empty?
        raise ArgumentError, "Only one target can be specified" if args.count > 1

        target = File.expand_path(args.first)
        raise ArgumentError, "No such file or directory: #{target}" unless File.exists?(target)

        indexer = Indexer.instance
        backup = indexer.backup_with_target(target) || indexer.add(target)
        backup_dir = File.join(BakShell::BACKUP_DIR, backup.id)

        unless backup.persistent
          FileUtils.mkdir_p(backup_dir)
        end

        base_target = File.basename(target)
        destination = File.join(BakShell::BACKUP_DIR, backup.id, base_target)

        if File.exists?(destination)
          if options[:replace]
            FileUtils.rm_r(destination, force: true)
          else
            FileUtils.mv(destination, "#{destination}.bak-#{Time.now.to_f}")
          end
        end

        FileUtils.cp_r(target, backup_dir)
      end
    end
  end
end
