module BakShell
  class CLI
    desc "Remove (specific) backups"
    arg_name "TARGET"
    command :purge do |c|
      c.action do |global_options, options, args|
        puts "Purging...".color(:green)

        indexer = Indexer.instance
        targets = Array.new
        ids = Array.new

        if args.empty?
          raise InvalidBackupError.new("Nothing to purge") if indexer.backups.count == 0

          targets = Dir.glob(File.join(BakShell::BACKUP_DIR, "*"))
          targets.delete(indexer.index_file)
          ids = indexer.ids
        else
          args.each do |arg|
            target = File.expand_path(arg)
            raise InvalidTargetError.new("No such file or directory: #{target}") unless File.exists?(target)

            backup = indexer.backup_with_target(target)

            if backup.nil?
              puts"No backup found for file or directory: #{target}".color(:yellow)
              next
            end

            targets << File.join(BakShell::BACKUP_DIR, backup.id)
            ids << backup.id
          end
        end

        targets.each { |t| FileUtils.rm_r(t, force: true) }
        indexer.remove(ids)

        puts "Purging complete!".color(:green)
      end
    end
  end
end
