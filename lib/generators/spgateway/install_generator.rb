module Spgateway
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      desc "Creates a spgateway initialize"
      class_option :orm

      def copy_initializer
        template "spgateway.rb", "config/initializers/spgateway.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end

    end
  end
end
