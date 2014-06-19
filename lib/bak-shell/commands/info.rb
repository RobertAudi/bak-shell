module BakShell
  class CLI
    desc "Show backup info"
    arg_name "TARGET"
    command :info do |c|
      c.action do |global_options, options, args|
        raise TooManyTargetsError.new("Only one target can be specified") if args.count > 1

        indexer = Indexer.instance

        if args.empty?
          backups = Hash.new
          indexer.backups.each { |b| backups[b[:id]] = Dir.glob(File.join(BakShell::BACKUP_DIR, b[:id], "*")).reverse }

          puts "#{backups.values.inject(0) { |count, b| count + b.count }} backups found".color(:green)

          backups.each do |id, b|
            puts indexer.backup_with_id(id).target
            puts "\t#{b.count} backups"

            latest = Time.at(b.find { |v| v =~ /\.bak-latest-.*\Z/ }.sub(/\A.*\.bak-latest-/, "").to_f)
            puts "\tLatest backup time: #{latest}"
          end
        else
          target = File.expand_path(args.first)
          backup = indexer.backup_with_target(target)

          raise InvalidBackupError.new("No backup found for file or directory: #{target}") if backup.nil?

          backup_dir = File.join(BakShell::BACKUP_DIR, backup.id)
          backups = Dir.glob(File.join(backup_dir, "*")).reverse
          backup_count = backups.count

          backup_times = backups.map do |b|
            Time.at(File.basename(b).sub(/\A.*\.bak-(latest-)?/, "").to_f).to_s
          end

          puts "#{backup_count} found"

          if backup_count > 5
            last_five = backup_times[0..4]
            remaining_backups = backup_times.drop(5).count

            puts "Showing five latest backup times:".color(:green)
            last_five.each { |b| puts b }
            puts "#{remaining_backups} more..."
          else
            puts "Showing all backup times:".color(:green)
            backup_times.each { |b| puts b }
          end
        end
      end
    end
  end
end
