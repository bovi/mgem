require 'yaml'

class MrbgemData
  def initialize(gem_data)
    @gem_data = gem_data
  end

  def search(pattern, *fields)
    fields.flatten!
    if fields == []
      fields = [:name, :description, :author, :website]
    elsif not fields.respond_to? :each
      fields = [fields]
    end
    fields.to_a.each do |field|
      if self.send(field) =~ /#{pattern}/i
        return true   
      end
    end

    return false
  end

  # list of GEM properties

  def name; @gem_data["name"]; end
  def description; @gem_data["description"]; end
  def author; @gem_data["author"]; end
  def website; @gem_data["website"]; end
  def protocol; @gem_data["protocol"]; end
  def repository; @gem_data["repository"]; end

  def method_missing(method_name)
    err = "Mrbgem Field \"#{method_name}\" doesn't exist!"
    raise ArgumentError.new err
  end
end

class MrbgemList
  def initialize(gem_dir)
    @gems = load_gems(gem_dir)
  end

  def each(&block)
    @gems.each {|gem| block.call(gem)}
  end

  def search(pattern, *fields)
     @gems.select do |mrbgem|
      mrbgem.search pattern, fields
    end
  end

  def size; @gems.size; end

  private

  def load_gems(gem_dir)
    gems = []
    Dir.foreach(gem_dir) do |filename|
      next unless filename =~ /\.gem$/

      gems << MrbgemData.new(YAML.load_file("#{gem_dir}/#{filename}"))
    end
    gems
  end
end
