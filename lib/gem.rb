require 'yaml'

def load_gems
  config = {}
  mgem_root = "#{File.dirname(__FILE__)}/.."

  config[:mgem_root] = "#{File.dirname(__FILE__)}/.."
  config[:gems_dir] = "#{config[:mgem_root]}/gems"
  config[:gems_active] = "#{ENV['HOME']}/mrbgems/GEMS.active"
  config[:gems_build_dir] = "#{ENV['HOME']}/mrbgems/g"

  MrbgemList.new(config)
end

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
  def initialize(config)
    @config = config
    @gems = load_gems(@config[:gems_dir])
  end

  def each(&block)
    @gems.each {|gem| block.call(gem)}
  end

  def search(pattern, *fields)
    @gems.select do |mrbgem|
      mrbgem.search pattern, fields
    end
  end

  def active
    f = File.open(@config[:gems_active], 'r+')
    active_gems = f.each_line.map {|g| File.basename(g.chomp)}
    @gems.select {|g| active_gems.include? g.name}
  end

  def size; @gems.size; end

  def activate(gem_name)
    if check_gem(gem_name)
      gems = active
      gems << @gems.select {|g| g.name == gem_name}
      gems.uniq!
      save_active_gems(gems)
      puts "'#{gem_name}' activated!"
    else
      puts "'#{gem_name}' NOT activated!"
    end
  end

  def deactivate(gem_name)
    if check_gem(gem_name)
      gems = active.reject {|g| g.name == gem_name}
      save_active_gems(gems)
      puts "'#{gem_name}' deactivated!"
    else
      puts "'#{gem_name}' NOT deactivated!"
    end
  end

  private

  def check_gem(gem_name)
    if gem_name == "" or gem_name.nil?
      puts "Error: Empty GEM name!"
      false
    elsif not @gems.find_index {|g| g.name == gem_name}
      puts "Error: GEM doesn't exist!"
      false
    else
      true
    end
  end

  def save_active_gems(active_gem_list)
    File.open(@config[:gems_active], 'w+') do |f|
      active_gem_list.flatten.uniq.each do |mrbgem|
        f.puts "#{@config[:gems_build_dir]}/#{mrbgem.name}"
      end
    end
  end

  def load_gems(gem_dir)
    gems = []
    Dir.foreach(gem_dir) do |filename|
      next unless filename =~ /\.gem$/

      gems << MrbgemData.new(YAML.load_file("#{gem_dir}/#{filename}"))
    end
    gems
  end
end
