def whyrun_supported?
  true
end

action :create do
  converge_by "Create #{@new_resource.name}.xml" do
    template "/etc/shibboleth/attributes.d/#{@new_resource.name}.xml" do
      mode '0644'

      case @new_resource.deecoder
      when :string
      end

    end
  end
end
