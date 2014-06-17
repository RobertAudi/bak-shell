require "singleton"
require "ostruct"
require "csv"
require "securerandom"

module BakShell
  class Indexer
    include Singleton

    def backup_with_id(id)
      return @backup if !@backup.nil? && id == @backup.id

      backup = self.find_by_id(id)

      if backup.nil?
        @backup = nil
      else
        @backup = OpenStruct.new(backup)
      end

      @backup
    end

    def backup_with_target(target)
      return @backup if !@backup.nil? && target == @backup[:target]

      backup = self.find_by_target(target)

      if backup.nil?
        @backup = nil
      else
        @backup = OpenStruct.new(backup)
      end

      @backup
    end

    def add(target)
      if self.targets.include?(target)
        raise ArgumentError, "Attempt to add an existing backup to the index"
      end

      begin
        id = SecureRandom.hex
      end while self.ids.include?(id)

      CSV.open(self.index_file, "ab") { |f| f << [id, target] }

      self.ids << id
      self.targets << target
      self.backups << { id: id, target: target, persistent: false }

      @backup = OpenStruct.new(self.backups.last)
    end

    def remove(ids)
      new_index = self.backups.select { |b| !ids.include?(b[:id]) }
      new_index.map { |b| b.delete(:persistent) }
      CSV.open(self.index_file, "wb") do |f|
        new_index.each { |b| f << b.values }
      end
    end

    def index_file
      if @index_file.nil?
        @index_file = File.join(BakShell::BACKUP_DIR, "baklist.index")
        FileUtils.touch(@index_file)
      end

      @index_file
    end

    def index_file_exists?
      File.file?(self.index_file)
    end

    def ids
      self.load! if @ids.nil?

      @ids
    end

    def targets
      self.load! if @targets.nil?

      @targets
    end

    def backups
      self.load! if @backups.nil?

      @backups
    end

    def load!
      @ids = Array.new
      @targets = Array.new
      @backups = Array.new
      CSV.foreach(self.index_file) do |row|
        @ids << row.first
        @targets << row.last
        @backups << { id: row.first, target: row.last, persistent: true }
      end
    end
    alias_method :reload!, :load!

    def find_by_id(id)
      self.backups.find { |b| id == b[:id] }
    end

    def find_by_target(target)
      self.backups.find { |b| target == b[:target] }
    end
  end
end
