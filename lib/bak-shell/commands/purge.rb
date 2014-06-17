module BakShell
  class CLI
    desc "Remove (specific) backups"
    arg_name "TARGET"
    command :purge do |c|
      c.action do |global_options, options, args|
        indexer = Indexer.instance
        targets = Array.new
        ids = Array.new

        if args.empty?
          targets = Dir.glob(File.join(BakShell::BACKUP_DIR, "*"))
          targets.delete(indexer.index_file)
          ids = indexer.ids
        else
          args.each do |arg|
            target = File.expand_path(arg)
            raise ArgumentError, "No such file or directory: #{target}" unless File.exists?(target)

            backup = indexer.backup_with_target(target)

            # TODO: Show some kind of warning
            next if backup.nil?

            targets << File.join(BakShell::BACKUP_DIR, backup.id)
            ids << backup.id
          end
        end

        targets.each { |t| FileUtils.rm_r(t, force: true) }
        indexer.remove(ids)
      end
    end
  end
end
