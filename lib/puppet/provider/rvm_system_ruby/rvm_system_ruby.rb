require 'uri'

Puppet::Type.type(:rvm_system_ruby).provide(:rvm) do
  desc "Ruby RVM support."

  commands :rvmcmd => "/usr/local/rvm/bin/rvm"

  def create
    set_autolib_mode if resource.value(:autolib_mode)
    options = Array(resource[:build_opts])
    if proxy = resource[:proxy]
      begin 
        uri = URI.parse(proxy)
      rescue => error
        fail "Invalid proxy '#{proxy}': #{error}"
      end
      rvmcmd "install", resource[:name], '--proxy', "#{uri.host}:#{uri.port}", *options
    else
      rvmcmd "install", resource[:name], *options
    end
    set_default if resource.value(:default_use)
  end

  def destroy
    rvmcmd "uninstall", resource[:name]
  end

  def exists?
    begin
      rvmcmd("list", "strings").split("\n").any? do |line|
        line =~ Regexp.new(Regexp.escape(resource[:name]))
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list RVMs: #{detail}"
    end

  end

  def default_use
    begin
      rvmcmd("list", "default").split("\n").any? do |line|
        line =~ Regexp.new(Regexp.escape(resource[:name]))
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list default RVM: #{detail}"
    end
  end

  def default_use=(value)
    set_default if value
  end

  def set_default
    rvmcmd "alias", "create", "default", resource[:name]
  end

  def set_autolib_mode
    begin
      rvmcmd "autolibs", resource[:autolib_mode]
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not set autolib mode: #{detail}"
    end
  end
end
