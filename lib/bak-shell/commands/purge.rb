module BakShell
  class CLI
    desc "Remove (specific) backups"
    arg_name "TARGET"
    command :purge do |c|
      c.desc "Number of backups to keep"
      c.flag :k, :keep, default: 0, must_match: /\A[1-9][0-9]*\Z/

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

        keep_count = options[:k].to_i

        if keep_count > 0
          targets = targets.map { |t| Dir.glob(File.join(t, "*")).reverse.drop(keep_count) }.flatten
          backup_count = targets.count
        else
          backup_count = targets.map { |t| Dir.glob(File.join(t, "*")).count }.inject(:+)
          indexer.remove(ids)
        end

        if backup_count > 0
          targets.each { |t| FileUtils.rm_r(t, force: true) }
        end

        puts "Purging complete! (#{backup_count} backups removed)".color(:green)
      end
    end
  end
end
