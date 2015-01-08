module FleetCaptain
  module UnitFile
    extend self
    def parse(name = 'Unnamed', text)
      text.each_line.with_object(FleetCaptain::Service.new(name)) do |line, service|
        directive, value = line.split('=')
        if FleetCaptain.available_directives.include? directive
          if service.send("#{directive.underscore}_multiple?")
            service.send("#{directive.underscore}_concat", value)
          else
            service.send("#{directive.underscore}=", value)
          end
        end
      end
    end
  end
end
