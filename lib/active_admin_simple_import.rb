require 'active_admin'
require 'rails'

module ActiveAdminSimpleImport
  class Engine < Rails::Engine
    config.mount_at = '/'
  end

  module DSL
    def active_admin_import(options)
      options = { exclusion_list: [], after_update: nil }
                .merge options

      collection_action :import, method: :get do
        render template: 'admin/import'
      end

      collection_action :do_import, method: :post do
        rows = CSV.read params[:csv][:file].tempfile
        attrs = rows.shift.map{ |a| a.parameterize('_').to_sym }
        object_class = controller_name.singularize.camelize.constantize
        objects = rows.map{ |row| Hash[*attrs.zip(row).flatten] }
        objects.each do |object|
          edited_object = object_class.find object.delete :id
          edited_object.update_attributes object.except(*options[:exclusion_list])
          next if options[:after_update].nil? || !options[:after_update].is_a?(Proc)
          options[:after_update].call(edited_object, object)
        end
        redirect_to collection_path, notice: 'Zaimportowana plik CSV!'
      end
    end
  end
end

::ActiveAdmin::DSL.send(:include, ActiveAdminSimpleImport::DSL)
