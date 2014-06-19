module BakShell
  class CLI
    desc "Show backup info"
    arg_name "TARGET"
    command :info do |c|
      c.desc "Show all backups for a target (Doesn't work if no target is specified!!)"
      c.switch :a, :all, default_value: false, negatable: false

      c.desc "Show the path to the backup of a target (takes the index of the backup as argument)"
      c.arg_name "index"
      c.flag :p, :path, must_match: /\A[1-9][0-9]*\Z/

      c.desc "Show the path to the latest backup of a target (equivalent to `-p 1`)"
      c.switch :P, :"latest-path", default_value: false, negatable: false

      c.action do |global_options, options, args|
        raise TooManyTargetsError.new("Only one target can be specified") if args.count > 1

        indexer = Indexer.instance

        if args.empty?
          illegal_options = {
            a: false,
            p: nil,
            P: false
          }

          command_switches = c.switches.map { |k, s| { s.name => [s.name, s.aliases].flatten } }.inject({}) { |s, cs| s.merge(cs) }
          command_flags = c.flags.map { |k, s| { s.name => [s.name, s.aliases].flatten } }.inject({}) { |s, cs| s.merge(cs) }
          command_options = command_switches.merge(command_flags)

          illegal_error_message = ""
          options.each do |o, v|
            if illegal_options.has_key?(o) && illegal_options[o] != v
              illegal_error_message << "The #{command_options[o].map { |k| "`#{k.length > 1 ? "--" : "-"}#{k}`" }.join("/")} option cannot be used if no target is specified\n".color(:red)
            end
          end

          puts "#{illegal_error_message}\n" unless illegal_error_message.empty?

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
          if options[:P] && !options[:p].nil?
            raise BakShell::InvalidOptionError.new("Conflicting options: `-p`/`--path` and `-P`/`--latest-path`")
          end

          target = File.expand_path(args.first)
          backup = indexer.backup_with_target(target)

          raise InvalidBackupError.new("No backup found for file or directory: #{target}") if backup.nil?

          backup_dir = File.join(BakShell::BACKUP_DIR, backup.id)

          if options[:P]
            puts Dir.glob(File.join(backup_dir, "*.bak-latest-*")).first
          else
            backups = Dir.glob(File.join(backup_dir, "*")).reverse
            backup_count = backups.count

            if !options[:p].nil?
              if options[:p].to_i > backup_count
                raise BakShell::InvalidBackupError.new("Invalid backup index: #{options[:p]}")
              end

              puts backups[options[:p].to_i - 1]
            else
              backup_times = backups.map do |b|
                Time.at(File.basename(b).sub(/\A.*\.bak-(latest-)?/, "").to_f).to_s
              end

              puts "#{backup_count} found"

              if !options[:a] && backup_count > 5
                last_five = backup_times[0..4]
                remaining_backups = backup_times.drop(5).count

                puts "Showing five latest backup times:".color(:green)
                last_five.each_with_index { |b, i| puts "[#{i + 1}] #{b}" }
                puts "#{remaining_backups} more..."
              else
                puts "Showing all backup times:".color(:green)
                backup_times.each_with_index { |b, i| puts "[#{i + 1}] #{b}" }
              end
            end
          end
        end
      end
    end
  end
end
