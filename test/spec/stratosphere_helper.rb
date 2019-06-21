module StratosphereHelpers
  def self.environment
    if @environment then
      return @environment
    end

    impl = ENV["IMPL"]
    if impl == "atmosphere" then
      ams_version_str = ENV["ATMOSPHERE_VERSION"]
      if ams_version_str then
        m = ams_version_str.match(/([0-9]+)\.([0-9]+)\.([0-9])/)
        if !m then
          raise "invalid ATMOSPHERE_VERSION string: #{ams_version_str}"
        end
        ams_version = [m[1], m[2], m[3]].map do |e| e.to_i end
      else
        ams_version = [nil, nil, nil]
        File.open("../common/include/atmosphere/version.h") do |f|
          f.each_line do |l|
            l.match(/\#define\s+ATMOSPHERE_RELEASE_VERSION_([A-Z]+)\s+([0-9])+/) do |m|
              v = m[2].to_i
              case m[1]
              when "MAJOR"
                ams_version[0] = v
              when "MINOR"
                ams_version[1] = v
              when "MICRO"
                ams_version[2] = v
              end
            end
          end
        end
        if ams_version.any? do |v| v == nil end then
          raise "failed to parse out AMS version"
        end
      end
    elsif impl == "nintendo" then
      ams_version = nil
    else
      raise "unrecognized IMPL: #{impl}"
    end
    
    target_fw_str = ENV["TARGET_FW"]
    if !target_fw_str then
      raise "missing required environment variable TARGET_FW"
    end

    m = target_fw_str.match(/([0-9]+)\.([0-9]+)\.([0-9])/)
    if !m then
      raise "invalid TARGET_FW string: #{target_fw_str}"
    end

    target_fw = [m[1], m[2], m[3]].map do |e| e.to_i end

    target_fw_numeric_str = ENV["TARGET_FW_NUMERIC"]
    if !target_fw_numeric_str then
      raise "missing required environment variable TARGET_FW_NUMERIC"
    end
    target_fw_numeric = target_fw_numeric_str.to_i(0)
    
    master_key_revision = (ENV["MASTER_KEY_REVISION"] || "0").to_i

    @environment = Lakebed::Environment.new(
      Lakebed::TargetVersion.new(target_fw, target_fw_numeric),
      ams_version,
      master_key_revision)
  end

  def environment
    StratosphereHelpers.environment
  end
  
  def kernel
    @kernel||= Lakebed::Kernel.new(environment)
    if ENV["STRICT_SVCS"] then
      @kernel.strict_svcs = ENV["STRICT_SVCS"] == "1"
    else
      @kernel.strict_svcs = true
    end
    @kernel
  end

  def load_module(name)
    p = Lakebed::Process.new(kernel)
    path = ENV["KIP_PATH"]
    if !path then
      if environment.is_ams? then
        path = "../stratosphere/#{name}/#{name}.kip"
      else
        path = "nintendo/#{environment.target_firmware.numeric}/#{name}.kip"
      end
    end
    File.open(path) do |f|
      p.add_nso(Lakebed::Files::Kip.from_file(f))
    end
    p
  end
end

RSpec.configure do |config|
  config.include StratosphereHelpers
end
