class Mysql2psql
  class Converter
    attr_reader :reader, :writer, :options
    attr_reader :exclude_tables, :only_tables, :suppress_data, :suppress_ddl, :force_truncate, :preserve_order, :clear_schema

    def initialize(reader, writer, options)
      @reader = reader
      @writer = writer
      @options = options
      @exclude_tables = options.exclude_tables([])
      @only_tables = options.only_tables(nil)
      @suppress_data = options.suppress_data(false)
      @suppress_ddl = options.suppress_ddl(false)
      @force_truncate = options.force_truncate(false)
      @preserve_order = options.preserve_order(false)
      @clear_schema = options.clear_schema(false)
      @update_primary_keys = options.update_primary_keys(false)
    end

    def convert
      tables = reader.tables
               .reject { |table| @exclude_tables.include?(table.name) }
               .select { |table| @only_tables ? @only_tables.include?(table.name) : true }

      puts "Tables to migrate:"
      puts tables.map(&:name)
      puts "\n"

      if @preserve_order
        reordered_tables = []

        @only_tables.each do |only_table|
          idx = tables.index { |table| table.name == only_table }
          reordered_tables << tables[idx]
        end

        tables = reordered_tables
      end

      if @suppress_ddl
        puts "Skipping table writing due to suppress_ddl option."
      else
        tables.each do |table|
          puts "Writing table #{table.name}"
          writer.write_table(table)
        end
        puts "\n"
      end

      # tables.each do |table|
      #   writer.truncate(table) if force_truncate && suppress_ddl
      #   writer.write_contents(table, reader)
      # end unless @suppress_data

      if @suppress_data
        puts "Skipping data writing due to suppress_data option."
      else
        tables.each do |table|
          puts "Truncating table #{table.name}"
          writer.truncate(table) if force_truncate && suppress_ddl
        end
        puts "\n"

        tables.each do |table|
          puts "Writing table #{table.name} data"
          writer.write_contents(table, reader)
        end
        puts "\n"
      end

      tables.each do |table|
        writer.write_indexes(table)
      end unless @suppress_ddl
      tables.each do |table|
        writer.write_constraints(table)
      end unless @suppress_ddl

      writer.close

      if @clear_schema
        puts "Schema clearing"
        writer.clear_schema
      else
        puts "Skipping schema clearing due to clear_schema option."
      end

      if @update_primary_keys
        puts "Primary keys updating"
        writer.update_primary_keys
      else
        puts "Skipping primary keys couters updating due to update_primary_keys option."
      end

      writer.inload

      0
    rescue => e
      $stderr.puts "Mysql2psql: Conversion failed: #{e.to_s}"
      $stderr.puts e
      $stderr.puts e.backtrace[0,3].join("\n")
      return -1
    end
  end
end
