actions :create
default_action :create

attribute :name,                   :kind_of => String, :name_attribute => true, :required => true
attribute :id,                     :kind_of => String, :required => true
attribute :decoder,                :kind_of => [Symbol, String], :default => :string
attribute :decoder_case_sensitive, :kind_of => [TrueClass, FalseClass], :default => true
