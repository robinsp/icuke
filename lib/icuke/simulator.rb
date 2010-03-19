require 'httparty'
require 'appscript'
require 'timeout'

module ICuke
  class Simulator
    include HTTParty
    base_uri 'http://localhost:50000'
    
    def launch(project_file, options = {})
      # If we don't kill the simulator first the rest of this function becomes
      # a no-op and we don't land on the applications first page
      simulator = Appscript.app('iPhone Simulator.app')
      simulator.quit if simulator.is_running?

      xcode = Appscript.app('Xcode.app')
      xcode.launch
      xcode.open project_file
      project = xcode.active_project_document.project
      # Currently runs whichever target is active, this should be configurable
      executable = project.active_executable.get
      options[:env].each_pair do |name, value|
        executable.make :new => :environment_variable,
                        :with_properties => { :name => name, :value => value, :active => true }
      end
      project.launch_
      
      Timeout::timeout(30) do
        begin
          view
        rescue Errno::ECONNREFUSED
          sleep(0.1)
          retry
        end
      end
    end
    
    def quit
      Appscript.app('iPhone Simulator.app').quit
    end
    
    def view
      get('/view')
    end
    
    def record
      get '/record'
    end
    
    def stop
      get '/stop'
    end
    
    def save(path)
      get '/save', :query => { :file => path }
    end
    
    def load(path)
      get '/load', :query => { :file => path }
    end
    
    def play
      get '/play'
    end
    
    def fire_event(event)
      get '/event', :query => { :json => event.to_json }
    end
    
    def set_defaults(defaults)
      get '/defaults', :query => { :json => defaults.to_json }
    end
    
    private
    
    def get(path, options = {})
      self.class.get(path, options).body
    end
  end
end
