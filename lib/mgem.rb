require 'yaml'
require 'fileutils'
require "stringio"

MGEM_VERSION = '0.1.2'

MGEM_DIR = '.mgem'
GEMS_ACTIVE = 'GEMS_ACTIVE.lst'
GEMS_LIST = 'mgem-list'
GEMS_REPO = 'https://github.com/bovi/mgem-list.git'

def load_gems
  config = {}
  config[:mgem_dir] = [ENV["HOME"], MGEM_DIR].join File::SEPARATOR
  config[:mgem_active] = [config[:mgem_dir], GEMS_ACTIVE].join File::SEPARATOR
  config[:mgem_list] = [config[:mgem_dir], GEMS_LIST].join File::SEPARATOR

  initialize_mgem_list(config)

  MrbgemList.new(config)
end

def initialize_mgem_list(config = {})
  unless File.exists? config[:mgem_list]
    puts "Loading fresh GEM list..."
    `git clone #{GEMS_REPO} #{config[:mgem_list]}`
    puts "done!"
  end

  unless File.exists? config[:mgem_active]
    FileUtils.touch config[:mgem_active]
  end
end

class MrbgemData
  def initialize(gem_data)
    @gem_data = gem_data
  end

  def search(pattern, *fields)
    fields.flatten!
    if fields == []
      fields = [:name, :description]
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
  def repooptions; @gem_data["repooptions"]; end

  def method_missing(method_name)
    err = "Mrbgem Field \"#{method_name}\" doesn't exist!"
    raise ArgumentError.new err
  end
end

class MrbgemList
  def initialize(config)
    @config = config
    @gems = get_gems(@config[:mgem_list])
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
    f = File.open(@config[:mgem_active], 'r+')
    active_gems = f.each_line.map {|g| File.basename(g.chomp)}
    @gems.select {|g| active_gems.include? g.name}
  end

  def size; @gems.size; end

  def activate(gem_name)
    if check_gem(gem_name)
      gems = active + @gems.select {|g| g.name == gem_name}
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

  def update!
    temp_stderr, $stderr = $stderr, StringIO.new
    git_dir = [@config[:mgem_list], '.git'].join File::SEPARATOR
    dir_arg = "--git-dir=#{git_dir} --work-tree=#{@config[:mgem_list]} "
    current_hash = `git #{dir_arg} log -n 1 --pretty=format:%H`
    `git #{dir_arg} pull`
    result = `git #{dir_arg} log #{current_hash}..HEAD --pretty=format:''`
    count = result.lines.count
    if count == 0 
      puts "No new GEMs."
    else
      puts "The GEM list was updated!"
    end
  ensure
    $stderr = temp_stderr
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
    File.open(@config[:mgem_active], 'w+') do |f|
      active_gem_list.uniq.each do |mrbgem|
        f.puts mrbgem.name
      end
    end
  end

  def get_gems(gem_dir)
    gems = []
    Dir.foreach(gem_dir) do |filename|
      next unless filename =~ /\.gem$/

      yaml_gems = YAML.load_file([gem_dir, filename].join(File::SEPARATOR))
      gems << MrbgemData.new(yaml_gems)
    end
    gems
  end
end
