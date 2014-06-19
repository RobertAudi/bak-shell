module BakShell
  class CLI
    desc "Backup a file or directory"
    arg_name "TARGET"
    command :backup do |c|
      c.desc "Replace latest version of backup (if present). Default: false"
      c.switch :R, :replace, default_value: false, negatable: false

      c.action do |global_options, options, args|
        raise TargetMissingError.new("Target missing") if args.empty?
        raise TooManyTargetsError.new("Only one target can be specified") if args.count > 1

        target = File.expand_path(args.first)
        raise InvalidTargetError.new("No such file or directory: #{target}") unless File.exists?(target)

        puts "Backing up...".color(:green)

        indexer = Indexer.instance
        backup = indexer.backup_with_target(target) || indexer.add(target)
        backup_dir = File.join(BakShell::BACKUP_DIR, backup.id)

        unless backup.persistent
          FileUtils.mkdir_p(backup_dir)

          puts "Created new backup directory".color(:green)
        end

        base_target = File.basename(target)
        destination = File.join(BakShell::BACKUP_DIR, backup.id, "#{base_target}.bak-latest-#{Time.now.to_f}")
        previous_latest = Dir.glob(File.join(backup_dir, "*.bak-latest-*"))

        if previous_latest.count == 1
          previous_latest = previous_latest.first

          if options[:replace]
            FileUtils.rm_r(previous_latest, force: true)

            puts "Removed old backup".color(:green)
          else
            FileUtils.mv(previous_latest, previous_latest.sub(/-latest/, ""))

            puts "Versionned old backup".color(:green)
          end
        elsif previous_latest.count > 1
          raise "Found more than one backup marked as latest"
        end

        FileUtils.cp_r(target, destination)

        puts "Backup complete!".color(:green)
      end
    end
  end
end
